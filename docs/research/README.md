# Research notes

Dated notes verifying facts about external systems, and disposable experiments that answer design questions. Nothing here is product code. File naming: `YYYY-MM-DD-topic.md`. Each note states the question, the source or method, the finding, and the date checked.

| Date | Note | Question |
| --- | --- | --- |
| 2026-09-10 | [2026-09-10-surrealdb-status.md](2026-09-10-surrealdb-status.md) | What is the current SurrealDB release and Rust SDK state? |

## Research needed before D01/D02 can be approved

- Graph edge tables versus record links: query ergonomics, performance, and constraints for tree, stream, and dependency relationships.
- Schema-full versus schema-less tables for arbitrary metadata, and how to index user-defined keys.
- Transactions: what atomicity SurrealDB guarantees across multiple statements, and how to model "claim a task" safely under concurrent agents.
- Live queries: suitability for agents waiting on decisions and for UI updates.
- Embedded versus remote server mode with the Rust SDK; implications for tests and deployment.
- Recursive or multi-hop traversal for subtree queries and dependency closure; depth limits.
- Version pinning and upgrade story; behaviour differences between 2.x and 3.x that affect us.
