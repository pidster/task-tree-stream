# Agent rules

**Status:** Draft v0.1, 2026-09-10. These rules bind every AI agent working on this repository, regardless of tier. `CLAUDE.md` carries the short form; this is the full form.

## 1. Read before acting

Read `docs/vision.md`, the relevant design doc, and any ADR touching your task before starting. If a task references a doc that does not exist, stop and report it.

## 2. No code before the design gate

Until Phase 1 in `docs/approach.md` is marked passed:

- Do not create `Cargo.toml`, `crates/`, `ui/`, `schema/`, `skills/`, or any build configuration.
- Do not add dependencies or lockfiles.
- Experiments to validate a design question go under `docs/research/` with a dated note explaining the question, the method, and the result. They are disposable and must say so.

## 3. Task contract

Before work starts, a task must state:

- **Goal:** one sentence.
- **Acceptance criteria:** checkable statements.
- **Scope boundary:** what is explicitly not part of this task.
- **Inputs:** the docs, files, or decisions the task depends on.
- **Tier:** which agent tier is expected to do it.

If any is missing, the agent writes them and gets confirmation before proceeding. A T1 agent may confirm for T2/T3 tasks; a human confirms T1 tasks and anything touching an objective.

## 4. Scope discipline

Do the task as specified. Do not narrow it quietly, and do not widen it. If you find adjacent problems, record them as new task proposals or escalations; do not fix them in passing unless they block the task and the fix is trivial and reversible.

## 5. Escalation protocol

Escalate rather than guess when a choice would change:

- the data model or schema,
- any API or protocol surface,
- security, auth, or audit behaviour,
- a stated objective or non-goal,
- a decision recorded in an ADR.

An escalation records: the question, the options considered, a recommendation, and what is blocked. It is logged in the task and, during Phase 0/1, in `docs/design/README.md` under Open Escalations. Work not blocked by the escalation continues.

## 6. Decisions

Architectural decisions are recorded as ADRs in `docs/decisions/` using the template there. Accepted ADRs are not reopened without new information; write a superseding ADR instead. Small decisions are recorded inline in the design doc they affect.

## 7. Verification and honesty

- Claims about SurrealDB, Rust crates, or any external system are checked against current documentation, and the source and date are recorded in `docs/research/`.
- Report outcomes faithfully. If a check failed, say so with the output. If something was skipped, say so. Do not describe work as done that is not done.
- Do not invent names for concepts; use `docs/glossary.md` and extend it when a new term is needed.

## 8. Review

- Authors do not approve their own work.
- Design docs: reviewed by a T1 agent in the `reviewer` role, then approved by a human.
- Reviews are written as findings with severity and a concrete failure scenario, not general praise.
- A design doc moves Draft → In Review → Approved only via a recorded review.

## 9. Document hygiene

- One H1 per file. Status line under it.
- Absolute dates.
- When a decision changes, update every doc that states it in the same change.
- Keep `CLAUDE.md` short; put detail here or in `docs/approach.md`.

## 10. Git

- Never commit or push unless asked. Never force-push `main`.
- Commit messages describe why, not just what, and carry the attribution lines required by the session.

## 11. Cost awareness

Use the cheapest tier that can do the job well. A T1 agent doing mechanical work should stop, write a spec, and hand it down. Record the tier used so the strategy can be measured.
