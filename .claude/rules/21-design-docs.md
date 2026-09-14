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
- **Single owner per concept.** A design doc may define only the concepts assigned to it in the Concept ownership map in `docs/design/README.md`. Every other concept is referenced by owning doc and section, never redefined, restated with different fields, or "summarised" with invariants of its own. If you need a concept nobody owns, add it to the map first, in the same change.
- **Partition before parallel drafting.** Two docs that share a concept are not drafted concurrently until the owner has published at least an interface stub for that concept (entity names, fields, invariants, and the principal kinds), and the non-owner's contract points at it. A stub is a Draft section in the owning doc, not a note in a task prompt.
- **Deliberate divergence is allowed, but declared.** To validate a design, two or more authors may independently design the same concept. This is an explicit mode, not the default, and is used sparingly for high-risk concepts. It requires, before drafting starts: a row in the ownership map marked `competing (Dnn-a, Dnn-b; converge by DATE; synthesiser: role)`; candidates written as separate files `NN-topic.candidate-a.md` and so on, never in the canonical doc; and a named synthesiser who produces the single canonical doc, recording in its Alternatives section what each candidate contributed and why the rest was dropped. Candidates are then marked Superseded. The exercise is not finished until the map shows one owner.
- **Overlap is a blocker, not an open question.** If while drafting you find another doc already defines a concept you were asked to define, stop on that section, log an escalation naming both docs, and continue with the rest. Do not write a second definition "for the reviewer to reconcile".

