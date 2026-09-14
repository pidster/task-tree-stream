# SurrealDB status as of 2026-09-10

**Question:** What is the current SurrealDB release line, and is the Rust SDK a viable primary client?

**Method:** Web search of surrealdb.com release and SDK pages on 2026-09-10. Not yet verified by running the software. Treat as a starting point; D02 and D08 must confirm by experiment.

**Findings**

- SurrealDB 3.x is the current major line. 3.0 was announced with a focus on AI agent memory and improved indexing; 3.1 (2026-05-27) focused on stability and DiskANN vector indexing. Source: https://surrealdb.com/blog/category/releases and https://surrealdb.com/blog/introducing-surrealdb-3-0--the-future-of-ai-agent-memory
- Official Rust SDK exists as a crate, supports remote and embedded databases, is async, and requires Rust 1.89 or newer. Source: https://surrealdb.com/docs/languages/rust/overview and https://surrealdb.com/docs/sdk/rust/setup
- SurrealDB Studio (a first-party GUI) was introduced 2026-08-10, useful for inspecting data during design experiments. Source: https://surrealdb.com/releases

**Implications for design**

- Target the 3.x line. Record the exact pinned version in D02 once experiments run.
- The Rust SDK's embedded mode makes fast, isolated tests plausible; confirm feature parity with server mode in D08.
- Everything above is from marketing and docs pages, not hands-on. The research items listed in `README.md` must be run against a real instance before D02 is approved.
