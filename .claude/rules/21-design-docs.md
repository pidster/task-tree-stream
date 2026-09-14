---
paths:
  - "docs/design/**"
---

# Design documents

- Every design doc starts from `docs/design/00-template.md` and keeps all its sections, including Objective trace and Review log.
- Filenames follow the index in `docs/design/README.md` (`NN-kebab-title.md`). Adding a doc means adding a row to the index with objectives covered.
- Each section must trace to at least one objective in `docs/objectives.md`. Update the objective trace table in the index when the doc is created or its coverage changes.
- Authors do not set their own status to Approved. Status transitions: Draft → In Review (by reviewer, with findings appended) → Approved (by a human, with name and date).
- Review findings are recorded in the Review log with severity (blocker, major, minor), a concrete failure scenario, and a resolution. Praise is not a finding.
- Open questions list an owner and a plan to close them. Deferred questions get an ADR recording the deferral.
- Diagrams are Mermaid in fenced code blocks, not images.
- Dependencies between docs stated in the index (for example D01 before D02) must be respected when moving a doc to Approved.
