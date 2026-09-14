# Task contract and scope

Before starting any non-trivial task, confirm it has a goal, acceptance criteria, scope boundary, inputs, and tier (see `docs/agent-rules.md` section 3). If it does not, write them first and get them confirmed.

- Do the task as specified. Do not narrow it quietly or widen it.
- Adjacent problems become escalations or task proposals, not drive-by fixes, unless the fix is trivial, reversible, and blocking.
- Escalate rather than guess when a choice would change the data model, an API or protocol surface, security or audit behaviour, an objective or non-goal, or an accepted ADR. Log escalations in `docs/design/README.md` under Open Escalations during Phase 0/1.
- Report outcomes faithfully. Failed checks are reported with output. Skipped steps are named. Nothing is called done that is not done.
- Use the cheapest agent tier that can do the job well. A T1 agent doing mechanical work stops, writes a spec, and delegates to T2/T3. Record the tier used.
- Prefer project skills (Skill tool) over ad hoc approaches when one applies.
