# 0004: Tiered agent development strategy

**Status:** Accepted — 2026-09-10

## Context

The project will be built mostly by AI agents. High-reasoning models are expensive and slow; using them for routine work wastes budget and, paradoxically, can produce over-elaborate output. Cheap models given vague tasks produce wrong output. The founder requires optimal use of agents without over-using high-reasoning ones.

## Decision

Agents are used in three tiers (see `docs/approach.md`): T1 high reasoning for design, architecture, adversarial review, and escalations; T2 for fully specified implementation and routine review; T3 for mechanical work. Every task carries a written contract (goal, acceptance criteria, scope, inputs, tier) before assignment. The tier used is recorded per task so the strategy can be measured.

## Consequences

- Specification work moves up front; T1 agents spend effort writing specs for T2/T3 rather than doing the work.
- Authors and reviewers are separate agents.
- The product itself should record agent tier on tasks (feeds objective O6 and dogfooding).

## Alternatives

- **Single high-reasoning agent for everything.** Simplest, highest cost, and no measurement of what actually needs it. Rejected.
- **Cheapest-possible everywhere.** Low cost, high rework. Rejected.
