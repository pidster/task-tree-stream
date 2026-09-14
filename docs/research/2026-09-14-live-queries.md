# Live queries: suitability for decision-waits and UI updates

**Status:** Disposable research note, not a design document.

**Question:** Are SurrealDB live queries suitable for (a) an agent waiting on a decision/escalation resolution and (b) UI updates? What are the delivery guarantees, reconnect behaviour, and any documented limits (max concurrent live queries, payload size)? Recommendation: live queries for the decision-wait path and the UI stream, or polling/SSE from the backend?

**Method:** Started `surreal start memory --user root --pass root --bind 127.0.0.1:8901`. Opened a `LIVE SELECT` over the WebSocket endpoint (`ws://127.0.0.1:8901`) in one background process (live queries require WS; the HTTP REST endpoint does not support them — read in docs and consistent with observed CLI defaulting to `ws://localhost:8000`), kept the connection open with a `sleep`, and from a second, independent process issued `UPDATE`/`CREATE` statements over plain HTTP against the same record(s). Captured the notifications delivered on the live connection. Repeated with a `WHERE`-filtered live query to simulate "wait until this specific decision resolves." Cross-checked reconnect/limits claims against SDK docs and search results on 2026-09-14 (official docs pages for live query internals/limits were largely marketing-level or unreachable via fetch; noted explicitly below where claims are unverified).

**Software versions:** SurrealDB CLI/server `3.2.3+20260721.40522d1` (macOS aarch64).

## Findings

1. **Verified by running — an unfiltered live query on a table delivers Create and Update notifications from a separate session in real time.**
   ```
   ( echo "LIVE SELECT * FROM task;"; sleep 6 ) | surreal sql --endpoint ws://127.0.0.1:8901 --user root --pass root --ns research --db research --pretty
   ```
   returned a live query UUID, then, after a concurrent `UPDATE task:t1 SET status = 'live_notify_test';` and `CREATE task:live_new SET status = 'brand_new';` were run from a separate `surreal sql --endpoint http://...` process:
   ```
   -- Notification (action: Update, live query ID: 0b1de639-...)
   { id: task:t1, status: 'live_notify_test', version: 0 }
   -- Notification (action: Create, live query ID: 0b1de639-...)
   { id: task:live_new, status: 'brand_new' }
   ```
   Both notifications arrived, tagged with the action and the live query ID, on the same open WS connection, with no polling from the client.

2. **Verified by running — a `WHERE`-filtered live query only fires when the filter is satisfied, which fits the "wait for decision resolution" use case exactly.** Created `decision:d1` with `status = 'pending'`, opened:
   ```
   LIVE SELECT * FROM decision WHERE id = decision:d1 AND status = 'resolved';
   ```
   then updated the record twice from another session: first to `status = 'in_progress'` (no notification delivered — correctly filtered out), then to `status = 'resolved'` (one notification delivered, containing the full updated record including `resolution: 'approved'`). This means an agent can open a single live query scoped to "my decision, resolved" and get exactly one notification when it's time to resume — no polling, no noise from intermediate state changes.

3. **Read in docs — live queries require a WebSocket connection; they are not available over the HTTP REST endpoint.** Multiple SDK docs pages state this plainly for JS/Go/Python/Swift/Mojo SDKs ("Live queries require a WebSocket connection and are not supported over HTTP"). Consistent with our own observation that `surreal sql`'s default endpoint scheme is `ws://` and that the HTTP endpoint accepted ordinary statements but we did not attempt (nor would expect to succeed at) `LIVE SELECT` over it. Source: search results summarising https://surrealdb.com/docs/reference/javascript/concepts/live-queries and sibling SDK pages, checked 2026-09-14.

4. **Read in docs — reconnect behaviour depends on whether the live query is "managed" or "unmanaged," and this is an SDK-level distinction, not a server one.** Per SDK documentation: managed live queries (created through the SDK's higher-level `.live()` helper) are automatically restarted by the SDK when the underlying connection reconnects after a drop, so the application keeps receiving notifications transparently. Unmanaged live queries (raw `LIVE SELECT` statements, or `.liveOf()`) are **not** automatically restarted — the application must detect the reconnect (e.g. listen for a `connected` event) and manually re-issue the `LIVE SELECT`, which will also hand back a new live query ID. Source: search summary citing https://surrealdb.com/docs/reference/javascript/concepts/live-queries and https://surrealdb.com/docs/reference/golang/concepts/live-queries, checked 2026-09-14. Not verified by running (would require deliberately killing a connection mid-flight against the Rust SDK; out of scope for this pass) — flagged for a follow-up experiment before D08 is finalised if the Rust SDK's managed/unmanaged split matters to the protocol design.

5. **Read in docs, low confidence — no documented hard limit on the number of concurrent live queries per connection was found.** Search of SurrealDB docs and the Rust SDK concurrency page (https://surrealdb.com/docs/sdk/rust/concepts/concurrency, checked 2026-09-14) turned up only a client-side channel-capacity knob (`.with_capacity()`, to bound the SDK's internal request queue for memory reasons) — not a server-imposed cap on live query count. No payload-size limit specific to live query notifications was found either (ordinary statement/response size limits would presumably apply, but that wasn't pinned down). This is an open gap: **do not assume unlimited concurrent live queries in production** without confirming against the SurrealDB Cloud/self-hosted operational docs or asking upstream directly — worth a follow-up research item if the UI design ends up wanting e.g. thousands of simultaneous per-record subscriptions.

6. **Read in docs — a known upstream bug exists around concurrent `LIVE SELECT`s on the same table from separate connections causing a "transaction read conflict."** GitHub issue https://github.com/surrealdb/surrealdb/issues/5273 ("Bug: Transaction read conflict during concurrent `LIVE SELECT`s to the same table across separate connections"), found via search, checked 2026-09-14, title only reviewed (issue body not fetched). Flagging as a risk to watch, not confirmed against our installed version (3.2.3) — worth a targeted repro before committing the UI design to "one live query per viewer per table."

## Sources

- Direct experiments against `surreal start memory` 3.2.3+20260721.40522d1, run 2026-09-14 (verified by running; see Findings 1-2).
- SurrealDB SDK live-query docs (JS/Go/Python/Swift/Mojo), summarised via web search, checked 2026-09-14 — WS requirement, managed/unmanaged reconnect behaviour.
- SurrealDB Rust SDK concurrency docs — https://surrealdb.com/docs/sdk/rust/concepts/concurrency — checked 2026-09-14 — no live-query-specific limit found, only client-side channel capacity.
- GitHub issue #5273, surrealdb/surrealdb — https://github.com/surrealdb/surrealdb/issues/5273 — checked 2026-09-14 (title only) — known conflict risk with concurrent same-table live queries.

## Implications for design (D02/D03/D08)

- **Live queries are a good fit for the decision-wait path.** Finding 2 demonstrates exactly the shape D03 needs: an agent blocked on an escalation can open one `LIVE SELECT ... WHERE id = $decision AND status = 'resolved'` and get woken with the resolved payload, with no polling loop in the agent client. Recommend this as the primary mechanism, but the agent client must also apply a **timeout and a fallback poll** (e.g. re-`SELECT` after N seconds of silence) to cover connection drops on unmanaged live queries (Finding 4) and the unresolved reconnect story — do not rely on the live query alone for a long-lived wait with no other liveness check.
- **For the UI stream, live queries are a good default but should not be the only data path.** They give low-latency push updates (Finding 1) without a bespoke SSE layer, but given the undocumented concurrency limits (Finding 5) and the known same-table conflict bug (Finding 6), D08/D03 should specify: the UI subscribes to narrowly-scoped live queries (per-project or per-view, not one global table-wide subscription per viewer) and the backend still exposes a plain polling/query endpoint as a fallback and for initial page load (a live query notification carries only the change, not a snapshot — the UI needs an initial `SELECT` regardless).
- **Do not build the decision-wait or UI-stream path solely on raw `LIVE SELECT` from the CLI's semantics; use the Rust SDK's live-query API**, and explicitly decide (open question for D08) whether to use its managed or unmanaged form — the managed form's auto-restart-on-reconnect (Finding 4) is attractive for the decision-wait use case specifically, since a silently-dead live query there means a permanently stuck agent.
- Before D03/D08 are marked Approved, run a follow-up experiment against the Rust SDK itself (not just the CLI) covering: (a) an actual reconnect scenario (kill and restart the server mid-wait) to see what the Rust SDK does, and (b) whether issue #5273 reproduces on 3.2.3 with our expected concurrency pattern (many viewers, live queries scoped to different records within the same table). This note does not resolve those; they are flagged as open follow-ups, not decided here.
