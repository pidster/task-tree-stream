---
paths:
  - "docs/research/**"
---

# Research notes and experiments

- Files are named `YYYY-MM-DD-topic.md` and added to the table in `docs/research/README.md`.
- Every note states: the question, the method (docs read or experiment run), the finding, sources with URLs and the date checked, and implications for design.
- Distinguish "read in docs" from "verified by running". Only the latter counts as verified for design approval.
- Experiments are disposable. Any code or SurrealQL here starts with a line saying so, lives only in this directory, and is never imported by, copied into, or linked from product code. Experiment scaffolding (a temporary Cargo project, a container) is created under this directory or in the scratchpad, never at the repo root.
- Record the exact software versions used (SurrealDB, Rust, SDK crate) in every experiment note.
- Negative results are recorded too.
