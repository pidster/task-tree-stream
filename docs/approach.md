# Approach

**Status:** Draft v0.1, 2026-09-10.

## Phases and gates

Work proceeds through phases. Each phase has an exit gate. A gate is passed only when its criteria are recorded as met in this file, with a date.

| Phase | Name | Exit gate | Passed |
| --- | --- | --- | --- |
| 0 | Initiation | Vision, objectives, approach, agent rules, repo layout, and initial ADRs exist and are reviewed | 2026-09-10 (drafted; review pending) |
| 1 | Design | Every design document in `docs/design/README.md` is Approved; design has had at least one adversarial review; open questions in `objectives.md` are resolved or explicitly deferred with an ADR | — |
| 2 | Foundation | Cargo workspace, SurrealDB schema, core data model, agent protocol API, and test harness exist; a scripted agent can complete a plan end to end (O3) | — |
| 3 | Operator UI | Tree, timeline, graph, and stream views; usability tested | — |
| 4 | Throughput and decomposition | Complexity scoring, decomposition assistance, throughput metrics and controls | — |
| 5 | Hardening and release | Auth, audit, performance targets met, docs complete | — |

The Phase 1 gate is the one this repo is currently organised around. **No product code before it.**

## Design phase method

1. **Research first.** Verify SurrealDB capabilities (graph edges, record links, document fields, live queries, schema-full versus schema-less tables, indexing, transactions) against current documentation. Record findings with dates and source URLs in `docs/research/`. Throwaway SurrealQL experiments are fine there.
2. **Write design docs** listed in `docs/design/README.md`. Each is authored by one agent or human, then reviewed by a different agent, then approved by a human.
3. **Adversarial review.** Before the gate, a high-reasoning agent is tasked solely with finding holes: inconsistencies between docs, unstated assumptions, missing failure modes, and objectives with no design coverage.
4. **Trace objectives.** Every objective in `objectives.md` must be traceable to at least one design section. The design index carries the trace table.
5. **Decide, record, move on.** Architectural choices get an ADR. Once accepted, an ADR is not relitigated without new information; a new ADR supersedes it.

## Agent usage strategy

The project is built by agents, deliberately. The aim is high output quality at low cost, which means matching model capability to task difficulty and never using an expensive agent for work a cheaper one does well.

### Tiers

| Tier | Typical model | Use for | Do not use for |
| --- | --- | --- | --- |
| T1 High reasoning | Fable / Opus class | Vision, architecture, data model design, ADRs, adversarial review, resolving escalations, complex debugging | Routine implementation, formatting, boilerplate, search |
| T2 Capable | Sonnet class | Implementing a fully specified task, writing tests to a spec, drafting docs from an outline, code review of routine changes | Open-ended design, unclear specs |
| T3 Fast | Haiku class | Search, summarisation, mechanical edits, renames, running and reporting checks, formatting, changelog entries | Anything requiring judgement about the design |

### Rules of engagement

- **Specify before assigning.** A T2 or T3 agent only receives tasks with a written goal, acceptance criteria, scope boundary, and pointers to relevant docs. If a T1 agent finds itself doing routine work, it should stop and write a spec for a cheaper agent instead.
- **Review is a separate agent.** The author does not approve their own work. Design docs get T1 review. Routine code gets T2 review.
- **Escalate upward, never sideways in silence.** A T2/T3 agent that hits an ambiguity records an escalation and stops on that item. It does not guess and does not widen scope.
- **Record the tier.** Task records in this project (and, once built, in the product itself) note which tier did the work, so we can measure whether the strategy is working.
- **Parallelise independent work.** Design docs, research spikes, and later implementation tasks that do not depend on each other run concurrently.
- **Dogfood.** Once the product can hold a plan, this project's own plan lives in it.

### Sub-agent roles

Role definitions live in `.claude/agents/`. Initial roles: `designer` (T1), `reviewer` (T1, adversarial), `researcher` (T2), `scribe` (T3). Implementation roles are added at the Phase 2 gate, not before.

## Repository layout

Present now:

```
CLAUDE.md, README.md, .editorconfig, .gitignore
.claude/agents/         sub-agent role definitions
.claude/rules/          modular operating rules, some path-scoped
docs/                   all documentation (see README.md for the map)
docs/design/            design documents, gated
docs/decisions/         ADRs
docs/research/          dated research notes and throwaway experiments
```

Planned at Phase 2 (do not create earlier):

```
Cargo.toml              workspace root
crates/                 Rust workspace members incl. the client tool (names decided in design)
skills/                 Agent Skill packages that teach agents to use the client tool
schema/                 SurrealQL schema definitions and migrations
ui/                     operator UI (stack decided in design)
scripts/                dev environment, checks
.github/workflows/      CI
```

## Working agreements

- `main` is always in a coherent state. Documentation is reviewed like code.
- Branch per piece of work; commit and push only when asked.
- Every doc carries a status line: Draft, In Review, Approved, or Superseded, with a date.
- Facts about external systems are dated and sourced. Undated claims are treated as unverified.
