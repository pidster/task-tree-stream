# CLAUDE.md

Operating instructions for any Claude agent working in this repository. Keep this file short; detail lives in `docs/` and the enforceable specifics live in `.claude/rules/` (loaded automatically, some path-scoped).

## What this project is

task-tree-stream: a task management service modelling projects as a tree, a stream, and a dependency graph, on SurrealDB, with a Rust backend, organisations/teams/users, a self-contained client tool plus Agent Skill for agents, and a UI for human supervisors. Read `docs/vision.md` before doing anything else.

## Current phase and hard gate

**Phase 0/1: initiation and design.** Do **not** write application code, create `crates/`, `ui/`, `schema/`, or `skills/`, add a `Cargo.toml`, or install dependencies until every design document in `docs/design/README.md` is marked **Approved**. Writing throwaway experiments in `docs/research/` to validate a design question is allowed and encouraged, but they must be labelled as such and never promoted to product code.

## Rules (full version: `docs/agent-rules.md`)

1. Design before code. Design changes go through a design doc and, where architectural, an ADR in `docs/decisions/`.
2. Use the cheapest agent that can do the job well. High-reasoning models for design, architecture, and review. Mid-tier for well-specified implementation. Small models for mechanical work. See `docs/approach.md`.
3. Every task an agent picks up must have a written goal, acceptance criteria, and scope boundary before work starts. If it does not, write them first and get them confirmed.
4. Escalate, do not guess, when a decision changes data model, API surface, security posture, or a documented objective. Record the escalation and the decision.
5. Verify claims. Facts about SurrealDB, Rust crates, or libraries are checked against current docs, and the source and date are noted in `docs/research/`.
6. Prefer project skills (Skill tool) over ad hoc approaches when one applies.
7. Do not commit or push unless asked. Never rewrite history on `main`.
8. Keep documents consistent: if you change a decision, update every doc that states it, and the glossary if vocabulary changes.

## Rule files

`.claude/rules/` holds the operational rules: `00-design-gate`, `10-task-contract`, `11-git`, `20-docs`, `21-design-docs`, `22-decisions`, `23-research`, `30-agent-roles`, `40-rust` (dormant until Phase 2). Read the ones matching the paths you touch.

## Conventions

- Markdown for all docs. One H1 per file. Status header on design docs and ADRs.
- ADRs are numbered `NNNN-kebab-title.md` and never deleted, only superseded.
- Dates are absolute (YYYY-MM-DD), never "last week".
- British or American spelling is both fine; do not churn existing text to change it.
