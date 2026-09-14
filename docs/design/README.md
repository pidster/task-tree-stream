# Design index

**Status:** Phase 1 not started as of 2026-09-10. This file is the gate. Phase 2 opens only when every row below is Approved and the adversarial review has been completed.

## Review process

1. Author drafts the doc (T1 `designer`, or a human). Status: Draft.
2. A different T1 agent in the `reviewer` role reviews it. Findings are appended to the doc under a Review Log heading, with severity and a concrete failure scenario. Status: In Review.
3. Author addresses findings. Reviewer confirms.
4. A human approves. Status: Approved, with date and approver.
5. Before the gate, one adversarial review across all docs together looks for inconsistencies and uncovered objectives.

## Design documents

| # | Document | Covers objectives | Status | Owner | Reviewer |
| --- | --- | --- | --- | --- | --- |
| D01 | [`01-domain-model.md`](01-domain-model.md) — entities, relationships (tree, stream, graph), metadata, statuses, timestamps, task state machine | O1, O2, O4, O8 | Draft v2 | designer agent | — |
| D02 | `02-surrealdb-schema.md` — tables, edges, record links, indexes, schema-full vs schema-less choices, transactions, live queries | O1, O2, E2 | Not started | — | — |
| D03 | `03-agent-protocol.md` — how an agent reads a plan, claims work, reports progress, escalates, waits for decisions; idempotency, concurrency, failure handling | O3, O4, O8 | Not started | — | — |
| D04 | `04-api.md` — external API surface (transport, auth, versioning, error model) shared by agents and UI | O3, O7 | Not started | — | — |
| D05 | `05-decomposition-and-complexity.md` — complexity estimation, split recommendations, task-size targets | O5 | Not started | — | — |
| D06 | `06-throughput-and-control.md` — metrics, in-flight limits, throttling, per-agent and per-project views | O6 | Not started | — | — |
| D07 | `07-operator-ui.md` — views (tree, timeline, graph, stream), navigation model, context preservation, visual direction, cognitive-load constraints | O7 | Not started | — | — |
| D08 | `08-backend-architecture.md` — Rust workspace structure, crate boundaries, async runtime, SurrealDB client usage (embedded vs remote), configuration, observability | E1, E2, E5 | Not started | — | — |
| D09 | [`09-identity-security-and-audit.md`](09-identity-security-and-audit.md) — organisations, teams, users; agent and human principals; authentication (including client tool auth); authorisation; audit trail; secrets | O8, O9 (O3, O4 in part; O6, O10, E6 at the boundary) | Draft v2 | designer agent | — |
| D10 | `10-testing-and-quality.md` — test strategy, protocol conformance tests, fixtures, CI | E6 | Not started | — | — |
| D12 | `12-agent-client-and-skill.md` — self-contained client tool (single binary, machine-readable output, auth handling, offline-safe retries) and the Agent Skill that teaches agents to use it; conformance with D03 | O3, O10 | Not started | — | — |
| D11 | `11-development-plan.md` — Phase 2+ task breakdown with tiers, dependencies, and the first dogfooded plan | E4 | Not started | — | — |

**Constraint recorded on D02 and D08 (founder decision E-2026-09-14-05, 2026-09-14):** the deployment pins **SurrealDB 3.2.3 or later in the 3.2.x line** and uses **no SurrealDB custom API routes**. D02 must carry the pin and define no custom API routes; D08 must carry the same constraint in its connection model and add a dependency-advisory check for the database and the SDK. D09 §2.5 records the reasoning, and it must not be the only document that states the constraint. Tracked as D09 OQ-1b.

Numbering is a suggested order, not a strict sequence. D01, D02, D03, and D09 are on the critical path and should be started first; D01 must be In Review before D02 and D03 are approved, and D09's identity model must be In Review before D01 is approved because every entity carries ownership. D12 depends on D03 and D04.

## Concept ownership map

Every concept has exactly one owning document. The owner defines it (fields, invariants, semantics). Every other document references it by name and section and never redefines it. To change a concept, change the owning doc. Adding a concept means adding a row here first. Deliberate competing designs are recorded as `competing (candidates; converge by DATE; synthesiser)` and must resolve to one owner. See `.claude/rules/21-design-docs.md` and the retrospective in `reviews/2026-09-14-retro-duplicate-identity.md`.

| Concept | Owner | Referenced by |
| --- | --- | --- |
| Organisation, Team, User, Principal, Agent user, Membership, TeamMembership, Grant, roles and permission verbs | D09 | D01, D03, D04, D12 |
| System principal (the per-org actor for system-initiated transitions) | D09 | D01 |
| Authentication, tokens, credentials | D09 | D04, D12 |
| Audit event, retention, redaction | D09 | D01 (Transition links to it), D02 |
| Project, Plan, Task, Dependency, User-defined edge, Metadata, Escalation, Decision, Transition, task state machine, claim and lease semantics, timestamps | D01 | D02, D03, D05, D06, D07 |
| Stream (derivation rules) | D01 | D02, D03, D07 |
| Storage layout, indexes, transactions, live queries | D02 | D03, D08 |
| Agent protocol operations, idempotency, wait and retry behaviour | D03 | D04, D12 |
| API transport, versioning, error model | D04 | D03, D07, D12 |
| Complexity scoring, decomposition | D05 | D01 (fields), D07 |
| Throughput metrics, WIP limits, throttling | D06 | D01 (fields), D07 |
| Operator UI views and navigation | D07 | — |
| Crate layout, persistence boundary, configuration, observability | D08 | D02, D10 |
| Test strategy, conformance suites, isolation test suite | D10 | D09 |
| Phase 2+ task breakdown | D11 | — |
| Client tool, Agent Skill | D12 | — |

## Objective trace

Filled in as docs are written. Every objective in `docs/objectives.md` must appear here with at least one design section.

| Objective | Design sections |
| --- | --- |
| O1 | D01 §1, §2.4, §2.5, §2.6, §3.1, §3.2, §3.3, §3.4, §3.6 |
| O2 | D01 §2.6, §2.7, §4.1, §4.2, §4.3 |
| O3 | D01 §2.3, §3.5, §3.6, §6.2, §6.9, §6.10 (boundary; protocol in D03); D09 §2.2, §2.6, §3.4, §3.5 |
| O4 | D01 §2.8, §2.9, §6.9; D09 §3.3, §3.4, §3.5, §4.1 |
| O5 | D01 §3.1, §6.1, §6.8, PL-4 (boundary only; D01 v2 reserves no complexity fields — D05 owns the model and adds what it needs) |
| O6 | D01 §2.4 (four justified counters), §5.3 (derived durations), §5.5 (`ready_at`), §6.1, §6.5 (hooks only; metrics and WIP limits in D06); D09 §4.1, §4.5, T3, OQ-10 (boundary; D09 measures and throttles nothing) |
| O8 | D01 §2.10, §5, §6.4, §7 (Transition authoritative for domain state); D09 §1.5, §4.1, §4.2, §4.3, §4.4, §4.5 (audit event authoritative for security context) |
| O9 | D01 §2.1, §7.3 (boundary only; D01 v2 defines no identity entity); D09 §1.1–§1.10, §2, §3 |
| E2 | D01 §1, §3.2, §3.4, §8 (boundary; storage in D02) |
| O10 | D09 §2.2, §2.3, §5.2, §5.3, T9 (boundary; client tool in D12) |
| E6 | D09 §1.8, §2.5, §4.2, §5.3 (tests D10 must include) |
| O1–O10, E1–E6 | (pending) |

## Open escalations

Format: date, raised by, question, options, recommendation, status.

### E-2026-09-14-01 — May a Dependency cross project boundaries within an organisation?

- **Date:** 2026-09-14. **Raised by:** designer agent (T1), while drafting D01.
- **Question:** D01 invariant D-2 requires both ends of a Dependency to be in the same organisation. It does not decide whether they must be in the same *project*. This changes the data model (the scope of the cycle-prevention reachability query), the authorisation surface (a principal with rights on project A could observe and gate work in project B), and the stream (a plan's order could depend on tasks outside the plan's project, which the agent may not be permitted to read).
- **Options:**
  1. Same project only. Simplest; bounds cycle checking to one project; cross-project coordination is expressed as a non-gating user-defined edge.
  2. Same organisation, any project, with an authorisation check on both ends at edge creation and on read.
  3. Same organisation, any project, unrestricted.
- **Recommendation:** Option 2, with an organisation-level setting defaulting to option 1. Real programmes of work do span projects, and forcing that into non-gating edges would push it back into free text, which O1 exists to prevent. Option 3 is rejected because it leaks work across an authorisation boundary.
- **Blocked:** nothing in D01's draft. D-2 currently permits cross-project dependency and names this escalation. D09 (identity and authorisation) and D02 (cycle-check scope) cannot be approved until it is decided.
- **Decision owner:** D09 author, confirmed by the founder.
- **D09 author's position (2026-09-14):** Agrees with option 2, defaulting to option 1 per organisation. D09 §3 supplies the authorisation rule this needs: creating a Dependency whose ends are in different projects requires the principal to hold `task.update` on the depending task **and** `task.read` on the depended-on task, both evaluated at creation time; a principal who later loses read access on the far end sees the dependency as an opaque blocker (its existence and resolved/unresolved state, not its title or contents). This keeps the gate honest without leaking work across a grant boundary. Still needs founder confirmation.
- **Founder decision (2026-09-14):** Option 2 with an organisation-level setting defaulting to option 1, and the D09 author's opaque-blocker read rule. Confirmed.
- **Status:** Decided.

### E-2026-09-14-02 — Audit and redaction posture for metadata values

- **Date:** 2026-09-14. **Raised by:** designer agent (T1), while drafting D01.
- **Question:** D01 §4 lets users put arbitrary typed key/value pairs on any entity (O2), and D01 TR-5 audits field changes with before/after values in the immutable Transition log (O8). Together these mean a user or agent can write a secret or personal data into metadata and have it copied, verbatim and permanently, into an append-only audit record that cannot be edited or deleted. That is a security-posture question, not a modelling one.
- **Options:**
  1. Accept it. Document that metadata must not carry secrets or personal data, and rely on convention.
  2. Audit metadata changes by key only (record that `sprint.number` changed, not from what to what), losing some of O8's "prior state" for metadata.
  3. Allow keys to be marked sensitive (by prefix or by an org-level declaration); sensitive values are stored but never copied into the Transition log, which records only that the key changed.
  4. Full crypto-shredding or tombstoning of audit records, which contradicts the immutability in TR-1.
- **Recommendation:** Option 3. It preserves full audit for ordinary metadata, gives a defined path for the cases that need it, and does not weaken TR-1. Option 4 should be rejected explicitly so it does not resurface.
- **Blocked:** nothing in D01's draft; §4.2 and TR-5 are written so that option 3 is additive. D09 (security and audit) needs the decision, and D02 needs it before it fixes the audited-field allow-list (D01 Q3).
- **Decision owner:** D09 author, confirmed by the founder.
- **D09 author's position (2026-09-14):** Agrees with option 3, and D09 is drafted to be compatible with it: §4.1 records changed fields rather than whole documents, §4.3 makes redaction (a tombstone, itself audited) the only removal path, and §5.3 requires that free text never reaches application logs. Option 4 is rejected explicitly in D09 §4.3. D09 adds one requirement: a key marked sensitive must be sensitive for the whole organisation, not per record, or the audit log's coverage becomes unpredictable. Still needs founder confirmation.
- **Founder decision (2026-09-14):** Option 1 plus D09's redaction-with-tombstone. Metadata must not carry secrets or personal data; accidental leaks are removed by audited redaction. Both audit events and D01 Transitions must be redactable. No sensitive-key feature in v1; option 3 stays as a designed-but-unbuilt extension.
- **Status:** Decided.

### E-2026-09-14-03 — Multi-organisation humans: introduce an `Account` entity?

- **Date:** 2026-09-14. **Raised by:** designer agent (T1), while drafting D09.
- **Question:** The glossary defines `User` as org-scoped, and D09 keeps it that way. A human belonging to two organisations therefore has two `User` records. Do we add a global `Account` entity (email plus credentials or an external IdP subject, linked to at most one User per organisation) so such a human logs in once, or accept two separate logins in v1? This adds an entity D01 does not currently model.
- **Options:**
  1. Add `Account` now, as D09 §1.1 assumes.
  2. No `Account`; one login per organisation; revisit if it hurts.
  3. Make `User` global and scope everything through `Membership`. Rejected in D09 because a user id would no longer identify a tenant, weakening invariant I4 (no cross-organisation references).
- **Recommendation:** Option 1. It is a small entity, it keeps `User` org-scoped exactly as the glossary says, and retrofitting it later means migrating every human's credentials.
- **Blocked:** nothing in D09's draft. D01 must know whether `Account` exists before either document is approved.
- **Decision owner:** founder.
- **Founder decision (2026-09-14, revised after review):** Option 2. No `Account` in v1; one User per organisation, one login per User. Add later if it hurts. Reviewer's dissent accepted.
- **Status:** Decided.

### E-2026-09-14-04 — Personal-data erasure versus an immutable audit chain

- **Date:** 2026-09-14. **Raised by:** designer agent (T1), while drafting D09.
- **Question:** D09 §4.3 makes the audit log append-only with a per-organisation hash chain and offers redaction (a tombstone over free text, itself audited) as the only removal path. If a person requests erasure of their personal data, does redaction discharge the obligation, or must audit events referencing them be deleted — which breaks the chain and undermines O8?
- **Options:**
  1. Redaction only; document the position and the deployer's role as data controller.
  2. Redaction plus pseudonymisation of the principal reference after a retention period.
  3. Hard deletion, with a recorded and audited gap in the chain.
- **Recommendation:** Option 1 for v1, with option 2 designed but not built. This is a legal position, not a technical one, which is why it is escalated rather than decided.
- **Blocked:** nothing immediately; D09 should not be approved with the posture unstated.
- **Decision owner:** founder.
- **Founder decision (2026-09-14):** Deferred. Consequence now: none, provided D09 keeps redaction-with-tombstone (option 1) as the designed removal path and option 2 remains possible without a schema change. D09 states the posture as "redaction only, pending a legal position"; no further design work on this in Phase 1.
- **Status:** Deferred.

### E-2026-09-14-05 — Is the Rust layer the only enforcement point for tenant isolation?

- **Date:** 2026-09-14. **Raised by:** designer agent (T1), while drafting D09.
- **Question:** D09 §2.5 decides that the backend connects to SurrealDB as a single privileged database user and does not rely on SurrealDB's own `PERMISSIONS` for tenant isolation. A bug in the Rust authorisation layer therefore has nothing behind it. Do we accept that, or require record-level permissions as defence in depth?
- **Options:**
  1. Rust only, with a mandatory cross-tenant isolation test suite in D10 (D09's position).
  2. Rust plus SurrealDB `PERMISSIONS` as a second layer.
  3. Per-end-user SurrealDB sessions, pushing policy into the database.
- **Recommendation:** Option 1 for v1, reconsidering option 2 once the SurrealDB auth experiment in `docs/research/README.md` gives a cost figure. CVE-2026-63735 (cross-tenant bypass via custom API routes, fixed in SurrealDB 3.2.0; see `docs/research/2026-09-14-auth-identity-verification.md`) argues both that a second layer has value and that it cannot be trusted unverified. D09 consequently requires a minimum SurrealDB version of 3.2.0 and forbids custom API routes.
- **Blocked:** D02's schema (whether `PERMISSIONS` clauses are defined) and D08's connection model. D09's §2.5 stands as a recommendation until decided.
- **Decision owner:** founder, informed by the D02 research experiment.
- **Founder decision (2026-09-14):** Option 1, Rust as the sole enforcement point for now, with the mandatory cross-tenant isolation test suite in D10. Option 2 may be revisited by a later ADR once the SurrealDB auth experiment gives a cost figure.
- **Status:** Decided.

## Scope decisions

| Date | Decision | Source |
| --- | --- | --- |
| 2026-09-14 | Cut from v1: the task review gate (`in_review`, `requires_review`, reviewer fields and transitions); unenforced dependency kinds (finish-to-start only, no `kind`/`enforced` fields); reserved complexity fields in D01 (D05 adds what it needs when it is written); delegation (`on_behalf_of`) in D09; the per-org audit hash chain. | Founder, on reviewer findings in `reviews/2026-09-14-d01-d09-review.md` |
| 2026-09-14 | Further cuts applied while revising D01 to v2, on reviewer minor findings and by the same reasoning as the founder cuts: `Task.labels` (a `string_set` MetaValue covers it), `Task.blocked_on_external` (prose used as state), `wip_limit` on Project and Plan (D06 owns throughput control and adds what it needs), UserEdge endpoints narrowed to Task/Project/Plan. `draft`/`publish`/`unpublish` were reviewed for the same cut and **kept**, with the justification in D01 §6.1. Founder to confirm at review. | D01 v2 author (T1), `01-domain-model.md` Review log |

## Adversarial review

Not yet performed. Record date, reviewer, and a link to the findings when done.
