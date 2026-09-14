# Vision

**Status:** Draft v0.1, 2026-09-10. Owner: project founder. Review: open.

## One sentence

task-tree-stream is the system of record and the control plane for work that is planned by humans, decomposed and executed largely by AI agents, and supervised by both.

## The problem

Task tools today are built for humans clicking on cards. They assume a person reads the board, decides what to do, and reports back. When the executor is an agent, three things break:

1. **Structure is flattened.** Real work is a tree (a task has sub-tasks), a stream (things happen in order, and in parallel), and a graph (this cannot start until that is done). Tools pick one shape and bolt the others on as labels, which agents cannot reason over reliably.
2. **Progress is narrative, not state.** Agents need to read a plan, take the next unblocked task, report exactly what changed, raise an escalation, and wait for a decision. That is a protocol, not a comment thread.
3. **Throughput is invisible.** Nobody can say how much work is in flight, where it is blocked, or whether decomposition is producing tasks of a size that completes predictably.

## What we are building

A service with four faces:

- **A data model** in SurrealDB that stores the tree, the stream, and the graph natively, plus arbitrary key/value metadata so users can add their own relationships and filters without schema changes. SurrealDB is used as both a document store (task bodies, metadata, logs) and a graph store (containment, ordering, dependency, and user-defined edges).
- **An agent protocol** so an agent can be pointed at a plan and told: read it, follow the stream, update progress, log escalations, wait for decisions. Decisions may come from another agent or from a human. The protocol is the primary API; the human UI is built on the same surface.
- **An agent client and skill.** A self-contained client tool (a single binary CLI with a stable, machine-readable interface) plus an Agent Skill that teaches an agent how to use it. Any agent runtime that can run a command and read a skill can operate a plan without bespoke integration. The client handles authentication, so an agent acts as an identified principal within an organisation.
- **A human interface** that lets operators see a project as a tree, a timeline, a dependency graph, or a flow of events, switching between them without losing their place. It must be genuinely impressive to look at and use, and it must reduce cognitive load rather than add to it. Wow factor is a requirement, not a nicety, but it never wins over clarity.

## What it must feel like

- **To an agent:** unambiguous. There is always a well-defined next action, a defined way to say "done", "blocked", or "need a decision", and no need to infer state from prose.
- **To a human operator:** calm. Glance at a project and know what is moving, what is stuck, and what needs a decision from you. Drill in when you want, not because you have to.
- **To a project owner:** predictable. Decomposition produces tasks of a known size. Throughput is measured, and control of it scales as the number of agents grows.

## Principles

1. **Model the shape of work honestly.** Tree, stream, and graph are first-class. Metadata is for everything else.
2. **Agents first, humans always.** The agent protocol is the primary interface. Every human view is a projection of the same data and every human action is expressible through the protocol.
3. **Every actor is identified.** Agents and humans alike belong to an organisation, act as users, and may be grouped into teams. Nothing happens anonymously.
4. **State over story.** Status, timestamps, and transitions are structured and auditable. Free text is welcome but never the source of truth.
5. **Decomposition is a feature.** The system helps break work down by estimating complexity and guides towards task sizes that complete predictably.
6. **Escalation is cheap and explicit.** Raising a question is a first-class event with an owner and a resolution, not a lost comment.
7. **Design before code.** For this project itself: nothing is built until the design is thorough, reviewed, and approved.

## Out of scope for the vision

- Replacing chat, documents, or source control. We integrate with them; we are not them.
- Being a general workflow engine. The workflow is projects, tasks, and decisions.
- Becoming an agent framework. Agents bring their own runtime; we give them a plan, a protocol, a client tool, and a skill.
