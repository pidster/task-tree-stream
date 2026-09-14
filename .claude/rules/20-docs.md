---
paths:
  - "docs/**/*.md"
  - "README.md"
  - "CLAUDE.md"
---

# Documentation

- One H1 per file. Design docs and ADRs carry a status line directly under the H1: Draft, In Review, Approved, or Superseded, with an absolute date (YYYY-MM-DD).
- Absolute dates only. Never "yesterday", "last week", "recently".
- Facts about SurrealDB, Rust crates, or any external system must cite a dated note in `docs/research/`. Undated claims are unverified and must be labelled as such.
- Use terms from `docs/glossary.md`. When a new concept is needed, add a glossary row in the same change; do not coin synonyms.
- When a decision changes, update every document that states it in the same change: vision, objectives, approach, design index, glossary, README, and CLAUDE.md as applicable.
- Keep `CLAUDE.md` short. Detail goes in `docs/` or `.claude/rules/`.
- Do not churn spelling (British and American are both accepted) or reformat text you are not otherwise changing.
- Use the `markdown-files` skill for structural Markdown edits when it applies.
