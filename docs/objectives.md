# Objectives

**Status:** Draft v0.1, 2026-09-10. Each objective should become measurable during design. Numbers marked TBD are set in the design phase, not guessed here.

## Product objectives

| # | Objective | How we will know |
| --- | --- | --- |
| O1 | Model work as tree, stream, and graph in one store | Design doc shows every relationship type stored natively in SurrealDB; no relationship is encoded in free text |
| O2 | Arbitrary user metadata without schema change | Users can add K/V pairs and user-defined edges, then filter and query on them, with no migration |
| O3 | Agent-operable plans | An agent given only a plan identifier, the client tool, and the Agent Skill can complete a multi-task plan end to end, including one escalation and one wait-for-decision, in a scripted test |
| O4 | Decisions as first-class objects | Every escalation has an owner (agent or human), a state, a resolution, and timestamps |
| O5 | Complexity-aware decomposition | The system can estimate task complexity and recommend splits; task completion time variance decreases as decomposition is applied (target TBD) |
| O6 | Measurable, controllable throughput | Operators can see work in flight, blocked, and completed per unit time, per project and per agent, and can throttle intake |
| O7 | Human UI with wow factor and low cognitive load | Tree, timeline, graph, and stream views of the same project; switching views preserves selection and context; usability tested with real operators before release |
| O8 | Full auditability | Every state change carries who, when, why, and prior state |
| O9 | Identity: organisations, teams, users | Every principal (human or agent) is a user in an organisation, optionally in teams; authorisation is scoped by org and team; the client tool authenticates as a user |
| O10 | Self-contained agent client and skill | A single-binary client with machine-readable output, plus an Agent Skill documenting its use, is sufficient for an agent to operate a plan with no other integration |

## Engineering objectives

| # | Objective | How we will know |
| --- | --- | --- |
| E1 | Rust backend | Single Cargo workspace; no runtime language other than Rust on the server |
| E2 | SurrealDB used for both document and graph workloads | Design demonstrates both, with the boundaries between them documented and justified |
| E3 | Thorough design before code | Every doc in `docs/design/README.md` is Approved before `crates/` exists |
| E4 | Cost-efficient agent development | Agent tier is recorded per task; high-reasoning agents are used for design, architecture, and review, not routine implementation |
| E5 | Reproducible environment | A fresh clone can run the full stack locally with one documented command (Phase 2+) |
| E6 | Test coverage where it matters | Protocol behaviours and data-model invariants have automated tests before the first release |

## Non-goals (for the first release)

- Hosted multi-tenant SaaS operations and billing. (Organisations, teams, and users are in scope; running a public service is not.)
- Native mobile apps.
- Replacing Git, chat, or document tools.
- Running or scheduling the agents themselves. We hand out work; we do not host the workers.
- Real-time collaborative editing of task text.

## Open questions to settle in design

- Which timestamps and statuses are required, and what the state machine for a task looks like.
- How complexity is scored and by whom (heuristic, model, human, or a mix).
- Whether "stream" is a materialised ordering or a derived view over dependencies and priorities.
- Authentication mechanism for the client tool (API keys, OAuth device flow, or similar) and how agent users are provisioned and scoped.
- Authorisation model across organisations and teams for agents versus humans.
- Whether the UI is served by the Rust backend or built and deployed separately.
