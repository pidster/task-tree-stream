# Transactions and claiming a task

**Status:** Disposable research note, not a design document. Experiments referenced here (SurrealQL scripts run via the CLI) were ad hoc and are not preserved as files; the exact commands and their output are transcribed below so the run can be repeated.

**Question:** What atomicity does SurrealDB guarantee across multiple statements (BEGIN/COMMIT/CANCEL, isolation level)? How can "an agent claims a task" be modelled safely under concurrent agents — via optimistic versioning, conditional `UPDATE ... WHERE`, or explicit `BEGIN`/`COMMIT`? What concrete SurrealQL pattern should D03 recommend?

**Method:** Started a local SurrealDB server with `surreal start memory --user root --pass root --bind 127.0.0.1:8901` and drove it with `surreal sql` over both the HTTP (`http://127.0.0.1:8901`) and WebSocket (`ws://127.0.0.1:8901`) endpoints. Ran concurrent claim attempts as parallel OS processes (`&` + `wait` in bash) against a single shared record to force a real race, and inspected which requests succeeded. Cross-checked behaviour against the official docs pages fetched on 2026-09-14.

**Software versions:** SurrealDB CLI/server `3.2.3+20260721.40522d1` (macOS aarch64), run via `/opt/homebrew/bin/surreal`. Client: `surreal sql` from the same binary. No SDK involved in this note (see the Rust SDK note for that).

## Findings

1. **Verified by running — a conditional `UPDATE ... WHERE` claim is safe under real concurrency.** Created `task:t1` with `status = 'unclaimed'`. Fired 8 concurrent processes, each running:
   ```
   UPDATE task:t1 SET status = 'claimed', claimed_by = 'agent$i' WHERE status = 'unclaimed' RETURN AFTER;
   ```
   Exactly one (`agent8` in this run) returned the updated row; the other seven returned `[]` (no rows matched the `WHERE` — the record was no longer `unclaimed` by the time they ran). Final state confirmed only one claim stuck: `{ id: task:t1, status: 'claimed', claimed_by: 'agent8' }`. No errors, no partial writes, no double-claims. This is the simplest safe pattern and requires no client-side retry logic — a loser simply gets zero rows back and can move to the next task.

2. **Verified by running — the CLI's piped/heredoc mode does *not* keep a transaction open across statements; a single request does.** Piping a multi-statement heredoc (`BEGIN TRANSACTION; UPDATE ...; CANCEL TRANSACTION;` as three separate lines via a bash heredoc) produced `'Invalid statement: Cannot CANCEL without starting a transaction'`, and the `UPDATE` in between was **not** rolled back — because the CLI in that pipe mode sends each semicolon-terminated statement as its own separate RPC call, so `BEGIN` from one call has no effect on the next. This is a `surreal sql` CLI/pipe-mode gotcha, not a fact about SurrealDB transactions — worth flagging for anyone scripting demos with the CLI, and it explains why our first CANCEL test looked like atomicity was broken when it wasn't.
   When the whole `BEGIN TRANSACTION; UPDATE ...; CANCEL TRANSACTION;` was sent as a **single** request (`echo "..." | surreal sql ...`, one line, one RPC call), the result was correct: `CANCEL` rolled the `UPDATE` back entirely — `SELECT` afterwards showed the pre-transaction value, untouched. Repeating with `COMMIT TRANSACTION;` in place of `CANCEL` persisted the change. So BEGIN/COMMIT/CANCEL do work as documented, but only when the SDK/driver keeps all statements of a transaction on one connection context/one request — which the Rust SDK does naturally (it doesn't have this CLI foot-gun; each `.query()` submitted in a transaction block is on the same session).

3. **Verified by running — SurrealDB detects write-write conflicts at commit and requires client-side retry; it does not silently lose updates.** Created `task:t2` with `version = 0`. Fired 8 concurrent single-request transactions, each:
   ```
   BEGIN TRANSACTION; UPDATE task:t2 SET version = version + 1; COMMIT TRANSACTION;
   ```
   with no `WHERE` guard at all (a blind read-modify-write). Result: 7 of 8 succeeded (final `version = 7`); the 8th returned:
   ```
   "Cannot COMMIT: Transaction conflict: Write conflict, retry the transaction. This transaction can be retried"
   ```
   No lost update occurred — the loser errored instead of silently overwriting. This confirms optimistic concurrency control (OCC) with conflict detection at commit time, matching the docs claim below. It means: (a) a bare `BEGIN...UPDATE...COMMIT` block on a record under contention is safe but the caller *must* catch this error and retry — SurrealDB will not do it for you; (b) a simple `UPDATE ... WHERE` (finding 1) sidesteps this entirely by returning zero rows instead of erroring, which is simpler to handle for a "claim" operation than catching and retrying a transaction-conflict error.

4. **Read in docs — snapshot isolation is the only isolation level, and this is documented as the source of the retry-on-conflict behaviour.** The SurrealDB transactions reference page states: "Every transaction runs under snapshot isolation, the one isolation level SurrealDB offers, with write conflicts detected at commit," and that this applies "on every storage engine and every deployment model, from an embedded in-memory database to a distributed cluster." It also states "BEGIN starts a manual transaction spanning as many statements, tables and models as you need," and that single statements run in their own implicit transaction by default. Source: https://surrealdb.com/docs/surrealdb/learn/querying/concepts-and-guides/transactions (checked 2026-09-14, via redirect from https://surrealdb.com/docs/surrealdb/reference-guide/transactions). This matches finding 3 exactly.

## Sources

- SurrealDB transactions concepts page — https://surrealdb.com/docs/surrealdb/learn/querying/concepts-and-guides/transactions — checked 2026-09-14 — snapshot isolation, write-conflict-at-commit, BEGIN semantics (read in docs, corroborated by finding 3).
- Direct experiments run against `surreal start memory` 3.2.3+20260721.40522d1 on 2026-09-14 (verified by running; see Findings 1-3 for exact commands/output).

## Implications for design (D03)

- **Recommend `UPDATE <task> SET status = 'claimed', claimed_by = $agent, claimed_at = time::now() WHERE status = 'unclaimed' RETURN AFTER;`** as the canonical claim pattern. It is a single statement (implicitly its own transaction), needs no explicit `BEGIN`/`COMMIT`, needs no client-side retry loop, and the result set itself tells the caller whether the claim succeeded (non-empty = claimed by me; empty = someone else got there first, try the next task). This should be the pattern documented in D03 and in the agent skill.
- If a claim needs to touch more than one record atomically (e.g. claim a task *and* append a stream event in the same operation), wrap both statements in an explicit `BEGIN TRANSACTION; ...; COMMIT TRANSACTION;` **on a single connection/session** (the Rust SDK's `Query` builder or a `.transaction()` helper — not the `surreal sql` piped-heredoc pattern that lost context in finding 2), guard the claiming `UPDATE` with the same `WHERE status = 'unclaimed'`, and treat a `Transaction conflict` error on `COMMIT` as retryable (retry the whole block, not just the failed statement).
- D03 should specify: a claim response with zero affected rows means "not claimed, try another task," not an error — agents must check the result set length, not just absence of an exception.
- Version-field optimism (`WHERE version = $expected`) works identically to the status-field guard and is the right pattern for updates elsewhere in the protocol where "did this change under me" needs to be detected generically (e.g. editing task metadata) — but for the specific "claim an unclaimed task" case, gating on `status` directly is simpler and needs no separate version counter.
- D02 should record `status` (and any optimistic version counter) as an indexed, schema-full field on the task table to keep the `WHERE` clause on the claim path fast — this is a follow-on question for the schema-full/schema-less research item, not resolved here.
