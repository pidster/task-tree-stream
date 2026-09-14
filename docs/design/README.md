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
| D01 | `01-domain-model.md` — entities, relationships (tree, stream, graph), metadata, statuses, timestamps, task state machine | O1, O2, O4, O8 | Not started | — | — |
| D02 | `02-surrealdb-schema.md` — tables, edges, record links, indexes, schema-full vs schema-less choices, transactions, live queries | O1, O2, E2 | Not started | — | — |
| D03 | `03-agent-protocol.md` — how an agent reads a plan, claims work, reports progress, escalates, waits for decisions; idempotency, concurrency, failure handling | O3, O4, O8 | Not started | — | — |
| D04 | `04-api.md` — external API surface (transport, auth, versioning, error model) shared by agents and UI | O3, O7 | Not started | — | — |
| D05 | `05-decomposition-and-complexity.md` — complexity estimation, split recommendations, task-size targets | O5 | Not started | — | — |
| D06 | `06-throughput-and-control.md` — metrics, in-flight limits, throttling, per-agent and per-project views | O6 | Not started | — | — |
| D07 | `07-operator-ui.md` — views (tree, timeline, graph, stream), navigation model, context preservation, visual direction, cognitive-load constraints | O7 | Not started | — | — |
| D08 | `08-backend-architecture.md` — Rust workspace structure, crate boundaries, async runtime, SurrealDB client usage (embedded vs remote), configuration, observability | E1, E2, E5 | Not started | — | — |
| D09 | `09-identity-security-and-audit.md` — organisations, teams, users; agent and human principals; authentication (including client tool auth); authorisation; audit trail; secrets | O8, O9 | Not started | — | — |
| D10 | `10-testing-and-quality.md` — test strategy, protocol conformance tests, fixtures, CI | E6 | Not started | — | — |
| D12 | `12-agent-client-and-skill.md` — self-contained client tool (single binary, machine-readable output, auth handling, offline-safe retries) and the Agent Skill that teaches agents to use it; conformance with D03 | O3, O10 | Not started | — | — |
| D11 | `11-development-plan.md` — Phase 2+ task breakdown with tiers, dependencies, and the first dogfooded plan | E4 | Not started | — | — |

Numbering is a suggested order, not a strict sequence. D01, D02, D03, and D09 are on the critical path and should be started first; D01 must be In Review before D02 and D03 are approved, and D09's identity model must be In Review before D01 is approved because every entity carries ownership. D12 depends on D03 and D04.

## Objective trace

Filled in as docs are written. Every objective in `docs/objectives.md` must appear here with at least one design section.

| Objective | Design sections |
| --- | --- |
| O1–O10, E1–E6 | (pending) |

## Open escalations

None yet. Format: date, raised by, question, options, recommendation, status.

## Adversarial review

Not yet performed. Record date, reviewer, and a link to the findings when done.
