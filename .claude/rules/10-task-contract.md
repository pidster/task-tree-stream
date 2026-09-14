# Task contract and scope

Before starting any non-trivial task, confirm it has a goal, acceptance criteria, scope boundary, inputs, tier, and an ownership line: the concepts this task **owns** (may define) and the concepts it may only **reference**, each with the owning document (see `docs/agent-rules.md` sections 3 and 12). If any is missing, write it first and get it confirmed.

- Do the task as specified. Do not narrow it quietly or widen it.
- Adjacent problems become escalations or task proposals, not drive-by fixes, unless the fix is trivial, reversible, and blocking.
- Escalate rather than guess when a choice would change the data model, an API or protocol surface, security or audit behaviour, an objective or non-goal, or an accepted ADR. Log escalations in `docs/design/README.md` under Open Escalations during Phase 0/1.
- Report outcomes faithfully. Failed checks are reported with output. Skipped steps are named. Nothing is called done that is not done.
- Use the cheapest agent tier that can do the job well. A T1 agent doing mechanical work stops, writes a spec, and delegates to T2/T3. Record the tier used.
- Prefer project skills (Skill tool) over ad hoc approaches when one applies.
- **Orchestrators partition before they parallelise.** The agent that spawns parallel tasks is accountable for giving them disjoint ownership. Shared concepts are either sequenced (owner first) or stubbed by the owner before the others start. "Flag any overlap for the reviewer" is not a partition and is not an acceptable contract. Deliberate competing designs are allowed only when declared as such in the ownership map and in every contract involved, with a convergence date and a synthesiser (see `.claude/rules/21-design-docs.md`). See `docs/design/reviews/2026-09-14-retro-duplicate-identity.md`.

