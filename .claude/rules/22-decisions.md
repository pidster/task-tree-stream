---
paths:
  - "docs/decisions/**"
---

# Architecture decision records

- One decision per file, named `NNNN-kebab-title.md`, numbered sequentially from the highest existing number. Start from `0000-template.md`.
- Keep all four sections: Context, Decision, Consequences, Alternatives. The Decision section is one or two sentences.
- Never delete or rewrite an accepted ADR. To change a decision, write a new ADR that supersedes it and update the old one's status line to "Superseded by NNNN".
- Add every new ADR to the table in `docs/decisions/README.md` in the same change.
- Status is Proposed until a human accepts it. Agents may propose; only humans accept.
- If an ADR changes something stated elsewhere, update those documents in the same change.
