# Design gate

Phase 1 (design) is not passed. See `docs/approach.md` for the gate criteria and ADR 0003 for the reasoning.

- Do not create `Cargo.toml`, `Cargo.lock`, `crates/`, `ui/`, `schema/`, `skills/`, `scripts/`, `.github/workflows/`, `package.json`, or any build, dependency, or CI configuration.
- Do not write product code in any language anywhere in the repository.
- If asked to write code, cite ADR 0003, offer to write a research experiment under `docs/research/` or a design section instead, and stop.
- Experiments that answer a design question live only under `docs/research/`, start with a line saying they are disposable, and are never referenced from product code.
- The only way to lift this rule is a change to `docs/approach.md` recording the Phase 1 gate as passed, with a date, made by a human.
