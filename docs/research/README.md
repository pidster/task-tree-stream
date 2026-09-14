# Research notes

Dated notes verifying facts about external systems, and disposable experiments that answer design questions. Nothing here is product code. File naming: `YYYY-MM-DD-topic.md`. Each note states the question, the source or method, the finding, and the date checked.

| Date | Note | Question |
| --- | --- | --- |
| 2026-09-10 | [2026-09-10-surrealdb-status.md](2026-09-10-surrealdb-status.md) | What is the current SurrealDB release and Rust SDK state? |
| 2026-09-14 | [2026-09-14-auth-identity-verification.md](2026-09-14-auth-identity-verification.md) | What do current sources say about SurrealDB auth/authorisation and the OAuth/credential-storage/workload-identity building blocks D09 depends on? |
| 2026-09-14 | [2026-09-14-edges-vs-record-links.md](2026-09-14-edges-vs-record-links.md) | Graph edges vs record links for containment, dependency, and user-defined relationships: which to use? |
| 2026-09-14 | [2026-09-14-schema-metadata-indexing.md](2026-09-14-schema-metadata-indexing.md) | Schema-full vs schema-less tables for arbitrary user metadata, and how to index user-defined keys? |
| 2026-09-14 | [2026-09-14-recursive-traversal.md](2026-09-14-recursive-traversal.md) | Does SurrealDB support recursive/multi-hop traversal for subtrees and dependency closure, and what are the depth limits? |
| 2026-09-14 | [2026-09-14-transactions-and-claiming.md](2026-09-14-transactions-and-claiming.md) | What atomicity does SurrealDB guarantee, and how can "an agent claims a task" be modelled safely under concurrent agents? |
| 2026-09-14 | [2026-09-14-live-queries.md](2026-09-14-live-queries.md) | Are live queries suitable for an agent waiting on a decision and for UI updates? |
| 2026-09-14 | [2026-09-14-rust-sdk-embedded-vs-remote.md](2026-09-14-rust-sdk-embedded-vs-remote.md) | Rust SDK: feature parity, storage backends, and MSRV for embedded vs remote server mode? |
| 2026-09-14 | [2026-09-14-traversal-at-scale.md](2026-09-14-traversal-at-scale.md) | Is D01's derived stream (subtree + dependency closure + topological order) affordable at 1k/10k/100k tasks on SurrealDB 3.2.3? |

## Research needed before D01/D02 can be approved

- Version pinning and upgrade story; behaviour differences between 2.x and 3.x that affect us (partially covered for edges/metadata/recursion by the 2026-09-14 notes above; the full upgrade story is still open).
