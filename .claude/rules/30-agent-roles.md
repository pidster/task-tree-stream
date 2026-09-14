---
paths:
  - ".claude/agents/**"
  - ".claude/rules/**"
---

# Agent role and rule files

- Role files in `.claude/agents/` use frontmatter `name`, `description`, and `model`. The model must match the role's tier in `docs/approach.md`: T1 → `opus`, T2 → `sonnet`, T3 → `haiku`.
- A role's description states what it is for and what it must never do. Every role file restates the design gate until Phase 1 is passed.
- Implementation roles (for example `implementer`, `tester`) are not added until the Phase 2 gate opens.
- Rule files in `.claude/rules/` are numbered by concern: 0x gates, 1x working practice, 2x documentation, 3x agent configuration, 4x code (Phase 2+). Path-scoped rules use frontmatter `paths:` globs; unscoped rules apply everywhere.
- Rules do not duplicate `docs/agent-rules.md`; they operationalise it. When the two disagree, fix the disagreement in the same change rather than leaving both.
