# Glossary

**Status:** Living document. Add a term when a design doc introduces one; do not invent synonyms.

| Term | Meaning |
| --- | --- |
| **Project** | The root of a tree of tasks. Owns metadata, a stream, and a dependency graph. |
| **Plan** | A project, or a subtree of one, packaged so an agent can be pointed at it and execute it. Exact relationship to Project is decided in D01. |
| **Task** | A unit of work with a status, timestamps, an optional parent, optional children, dependencies, and metadata. |
| **Tree** | The containment relationship: a task has sub-tasks. Strict hierarchy, one parent. |
| **Stream** | The execution order of tasks within a plan: what runs next, what runs in parallel. Whether stored or derived is decided in D01. |
| **Graph** | Dependency and user-defined relationships between tasks, crossing tree boundaries. |
| **Dependency** | A directed edge meaning "this task cannot start (or finish) until that one is done". Semantics fixed in D01. |
| **Metadata** | Arbitrary key/value pairs on any entity, user-defined, queryable, with no schema change. |
| **User-defined edge** | A named relationship between entities created by users, stored as a graph edge, filterable like metadata. |
| **Status** | The current state of a task in its state machine (defined in D01). |
| **Transition** | An audited change of status, with actor, time, reason, and prior state. |
| **Escalation** | A first-class request for a decision raised by an agent or human on a task, with an owner and a resolution. |
| **Decision** | The recorded resolution of an escalation, made by an agent or a human. |
| **Organisation** | The top-level tenant boundary. Owns projects, teams, and users. |
| **Team** | A named group of users within an organisation, used for assignment and authorisation. |
| **User** | An identified principal within an organisation. Both humans and agents are users. |
| **Principal** | The authenticated user (human or agent) performing an action; recorded on every transition. |
| **Client tool** | The self-contained single-binary CLI that agents (and humans) use to talk to the service; handles auth and emits machine-readable output. Defined in D12. |
| **Agent Skill** | The packaged instructions that teach an agent how to use the client tool to operate a plan. Defined in D12. |
| **Operator** | A human supervising projects through the UI. |
| **Agent** | An AI worker that executes tasks via the agent protocol. The system does not run agents; it hands them work. |
| **Agent protocol** | The API contract by which an agent reads a plan, claims work, reports progress, escalates, and waits. Defined in D03. |
| **Complexity** | An estimate of how hard a task is, used to guide decomposition. Scoring method decided in D05. |
| **Decomposition** | Splitting a task into sub-tasks, guided by complexity, targeting predictable completion. |
| **Throughput** | Tasks completed per unit time, per project or per agent. Defined and measured per D06. |
| **Tier (T1/T2/T3)** | Agent capability class used for development of this project; see `docs/approach.md`. |
| **Gate** | A checklist that must be fully met before the next phase begins. |
