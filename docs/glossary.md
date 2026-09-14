# Glossary

**Status:** Living document. Add a term when a design doc introduces one; do not invent synonyms.

| Term | Meaning |
| --- | --- |
| **Project** | The root of a tree of tasks. Owns metadata, a stream, and a dependency graph. |
| **Plan** | A named, addressable view over a subtree of one project, plus a filter and an execution policy, so an agent can be pointed at it and execute it. A plan does not own tasks (D01 §2.3). |
| **Task** | A unit of work with a status, timestamps, an optional parent, optional children, dependencies, and metadata. |
| **Tree** | The containment relationship: a task has sub-tasks. Strict hierarchy, one parent. |
| **Stream** | The execution order of tasks within a plan: what runs next, what runs in parallel. Derived on read by running Kahn's algorithm over the plan's in-scope dependency edges with tree pre-order as the tie-break; never stored, and it contains only tasks in the plan's scope (D01 §3.2). |
| **Graph** | Dependency and user-defined relationships between tasks, crossing tree boundaries. |
| **Dependency** | A directed edge meaning "this task cannot start until that one is finished". Finish-to-start is the only semantic in v1; other kinds are neither enforced nor storable (D01 §2.5, §3.3). Gating is evaluated at the gated transition and is never retroactive (D01 G-1). |
| **Metadata** | Arbitrary key/value pairs on any entity, user-defined, queryable, with no schema change. |
| **User-defined edge** | A named relationship between entities created by users, stored as a graph edge, filterable like metadata. |
| **Status** | The current state of a task in its state machine: draft, open, claimed, in_progress, blocked, awaiting_decision, done, cancelled, failed (D01 §6.1). |
| **Transition** | An audited change of status, with actor, time, reason where the event does not explain itself, and prior state. Append-only and authoritative for domain state; its `reason` and `changed_fields` are the one thing redactable (D01 §2.10, TR-6). |
| **Escalation** | A first-class request for a decision raised by an agent or human on a task, with an owner and a resolution. |
| **Decision** | The recorded resolution of an escalation, made by an agent or a human. |
| **Organisation** | The top-level tenant boundary. Owns projects, teams, and users. |
| **Team** | A named group of users within an organisation, used for assignment and authorisation. |
| **User** | An identified principal within an organisation. Both humans and agents are users. |
| **Principal** | The authenticated user (human or agent) performing an action; recorded on every transition. |
| **Membership** | The record that a User belongs to an Organisation with a set of organisation-level roles, carrying who granted it, when, and whether it is active, suspended, or revoked. Defined in D09 §1.6. |
| **Grant** | An explicit, optionally time-boxed permission on a Project or task subtree, given to a User or a Team. Defined in D09 §1.7. |
| **Agent user** | A User with `kind = agent`: a non-human principal, owned by a named human, scoped to a set of projects, authenticating with an Agent credential. Defined in D09 §1.4, §1.9. |
| **Agent credential** | The long-lived secret bound to one Agent user, used only to mint short-lived Access tokens. Stored hashed; expires; revocable. Defined in D09 §2.2. |
| **Access token** | The short-lived signed token presented on every API request, minted from an Agent credential or a human session. Defined in D09 §2.1. |
| **Revocation set** | The in-memory set of revoked credential, session, user, membership, grant, and token identifiers checked on every request, so revocation does not wait for token expiry. Defined in D09 §2.1. |
| **Audit event** | An append-only security record of one action: principal, time, action, target, prior and new state, reason, outcome, policy, and correlation id. Related to but distinct from Transition, which stays authoritative for domain state. Defined in D09 §4.1, §4.2. |
| **Redaction** | Replacing a value in an audit event or a Transition with a tombstone recording who removed it, when, and why. The only removal path for text that should never have been written; itself audited, and the one exception to the immutability of the audit trail. Defined in D09 §4.3. |
| **Correlation id** | An identifier grouping every request that belongs to one logical agent operation, so a whole run can be read as a unit. Defined in D09 §4.5. |
| **Client tool** | The self-contained single-binary CLI that agents (and humans) use to talk to the service; handles auth and emits machine-readable output. Defined in D12. |
| **Agent Skill** | The packaged instructions that teach an agent how to use the client tool to operate a plan. Defined in D12. |
| **Operator** | A human supervising projects through the UI. |
| **Agent** | An AI worker that executes tasks via the agent protocol. The system does not run agents; it hands them work. |
| **Agent protocol** | The API contract by which an agent reads a plan, claims work, reports progress, escalates, and waits. Defined in D03. |
| **Complexity** | An estimate of how hard a task is, used to guide decomposition. The entity fields and the scoring method are both **proposed (D05)**; D01 v2 reserves no field for it. |
| **Decomposition** | Splitting a task into sub-tasks, guided by complexity, targeting predictable completion. |
| **Throughput** | Tasks completed per unit time, per project or per agent. Defined and measured per D06. |
| **Tier (T1/T2/T3)** | Agent capability class used for development of this project; see `docs/approach.md`. |
| **Gate** | A checklist that must be fully met before the next phase begins. |
| **Actionable** | Derived property of a task: `open`, unclaimed, in an active project whose organisation is neither suspended nor archived, not the project root task, with every hard dependency satisfied — and, for a plan query, in that plan's scope with the plan active. Never stored as a status (D01 §3.5). |
| **Attempt** | One entry of a task into `in_progress`. Counted per task so repeated tries are visible. |
| **Blocking escalation** | An escalation that moves its subject task to `awaiting_decision` until a decision is recorded or the escalation is withdrawn. Non-blocking escalations change no status. |
| **Claim** | An exclusive, time-limited hold on a task by one user. Carries a claim id and an expiry; it is a lease, not a lock. |
| **Claim id** | The fencing token issued by a successful claim. Every claim-scoped action must present it; a stale claim id is rejected. |
| **Heartbeat** | A claim-scoped signal that extends a lease and records liveness of the claimant. |
| **Lease** | The expiry attached to a claim. When it lapses without release the system returns the task to `open` and audits the expiry. |
| **Release** | A claimant voluntarily giving a task back to the pool, with a reason. Distinct from lease expiry. |
| **MetaValue** | A typed metadata value: string, int, decimal, bool, timestamp, duration, ref, string set, or null (D01 §4.1). |
| **Metadata filter** | The predicate grammar used to select entities by metadata and typed fields; used by plan scope, the UI, and the agent protocol (D01 §4.3). |
| **Resolution** | Why a task ended: completed, superseded, duplicate, wont_do, obsolete, or abandoned. Required on cancellation. |
| **Root task** | The single parentless task created with a project. Never claimable; exists so tree operations have no special case. |
| **Sequence hint** | A per-task decimal that orders siblings within the tree. A hint never overrides a dependency. |
| **Size class** | A coarse band for task size. **Proposed (D05)**; D01 v2 reserves no field for it. |
| **Soft dependency** | A dependency (`hard = false`) that contributes to stream ordering and to cycle prevention but does not block claiming or starting (D01 §2.5, §3.3). |
| **Opaque blocker** | How a Dependency is rendered to a principal who may read the depending task but not the depended-on one: its existence, direction, whether it is hard, and whether it is satisfied — never the far task's identity or contents (D01 §3.6, authorisation rule D09 §3.6). |
| **Graph version** | The per-project counter that serialises every write which can change the shape of the containment tree or the dependency graph, so cycle prevention is not defeated by write skew (D01 §3.4, P-5). |
| **Exhausted plan** | A derived flag: every in-scope task is terminal. Closing the plan remains an explicit, audited act (D01 PL-4). |
| **System principal** | The one User per organisation with `kind = system`, named as actor on system-initiated transitions and as principal on the bootstrap record, so nothing is anonymous. It never authenticates and holds no role, credential, or grant. Also written *system user* in D01. Defined in D09 §1.5. |
| **Terminal state** | `done`, `cancelled`, or `failed`. Leaving one is an explicit, audited reopen, retry, or reinstate. |
| **WIP limit** | The cap on concurrently claimed or in-progress tasks in a project or plan. **Proposed (D06)**; D01 v2 reserves no field for it. D01 §6.5 supplies only the `paused` intake hook. |
