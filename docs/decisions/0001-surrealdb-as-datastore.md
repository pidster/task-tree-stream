# 0001: Use SurrealDB as the single datastore for document and graph workloads

**Status:** Accepted — 2026-09-10

## Context

The domain needs document storage (task bodies, arbitrary key/value metadata, logs, decisions) and graph storage (containment tree, ordering stream, dependency edges, user-defined relationships). Running two databases doubles operational cost and makes cross-model queries awkward. SurrealDB offers both models in one engine with a single query language, record links, graph edges, schema-full and schema-less tables, and live queries. It is also the founder's stated choice.

## Decision

SurrealDB is the only datastore. Documents and graph relationships live in the same database and are queried with SurrealQL. The design phase will decide which relationships are graph edges versus record links versus embedded fields, and which tables are schema-full.

## Consequences

- Design must verify, against current SurrealDB documentation and small experiments, that graph traversal, live queries, and transactional guarantees meet our needs. Findings go in `docs/research/`.
- We accept dependence on a younger database than Postgres. Mitigation: keep the persistence layer behind a clear boundary in the Rust backend (see D08) so the storage choice can be revisited by a superseding ADR without rewriting the domain.
- The Rust SDK is the client. Embedded versus remote server mode is decided in D08.
- SurrealDB version pinning and upgrade policy are decided in D02.

## Alternatives

- **Postgres with a graph extension or recursive CTEs.** Mature, but graph queries are second-class and metadata flexibility relies on JSONB. Rejected for model fit, not viability; it remains the fallback.
- **Neo4j plus a document store.** Strong graph, but two systems to run and no single query surface. Rejected for operational cost.
