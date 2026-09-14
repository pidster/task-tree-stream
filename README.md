# task-tree-stream

A project task management service that models work as a **tree** (tasks contain sub-tasks), a **stream** (tasks are completed in sequence and in parallel), and a **graph** (tasks depend on other tasks). Built on SurrealDB, with a Rust backend, and designed first for AI agents as operators and second for humans as supervisors.

## Status

**Phase 0: Initiation.** No application code exists yet, by design. See [docs/approach.md](docs/approach.md) for the phase gates. Code is not written until the design in `docs/design/` is complete, reviewed, and approved.

## Start here

| Document | Purpose |
| --- | --- |
| [docs/vision.md](docs/vision.md) | Why this exists and what it must feel like |
| [docs/objectives.md](docs/objectives.md) | Measurable goals and non-goals |
| [docs/approach.md](docs/approach.md) | Phases, gates, repo layout, how agents are used |
| [docs/agent-rules.md](docs/agent-rules.md) | Rules every agent working on this repo must follow |
| [docs/design/README.md](docs/design/README.md) | Design index and review process |
| [docs/decisions/](docs/decisions/) | Architecture decision records |
| [docs/glossary.md](docs/glossary.md) | Shared vocabulary |
| [CLAUDE.md](CLAUDE.md) | Operating instructions loaded by Claude Code |

## Repository layout

```
.
├── CLAUDE.md            # agent operating instructions (short; points at docs/)
├── .claude/agents/      # role definitions for specialised sub-agents
├── .claude/rules/       # modular, path-scoped operating rules
├── docs/
│   ├── vision.md
│   ├── objectives.md
│   ├── approach.md
│   ├── agent-rules.md
│   ├── glossary.md
│   ├── design/          # design documents (gate for Phase 2)
│   ├── decisions/       # ADRs
│   └── research/        # notes on SurrealDB, prior art, experiments
├── crates/              # (Phase 2+) Rust workspace members, incl. the client tool
├── skills/              # (Phase 2+) Agent Skill(s) packaged for distribution
├── ui/                  # (Phase 2+) web UI
└── schema/              # (Phase 2+) SurrealQL schema and migrations
```

Directories marked Phase 2+ do not exist yet and must not be created before the design gate is passed.
