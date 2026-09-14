---
paths:
  - "Cargo.toml"
  - "crates/**"
  - "schema/**"
  - "skills/**"
---

# Rust, schema, and skills (Phase 2+)

These paths must not exist until the Phase 1 gate is recorded as passed in `docs/approach.md`. If you are editing one and the gate is not passed, stop and cite ADR 0003.

Once the gate is passed, the conventions below apply and are finalised by design docs D08 (backend), D02 (schema), and D12 (client and skill):

- Single Cargo workspace at the repo root; crate names and boundaries as decided in D08. No new crate without a D08 update.
- Persistence stays behind the boundary D08 defines; domain code does not import the SurrealDB SDK directly.
- Protocol and domain types are defined once and shared between server and client tool.
- `cargo fmt`, `cargo clippy -D warnings`, and `cargo test` pass before any change is reported as done. Report the actual output on failure.
- Schema changes are migrations under `schema/` with a matching update to D02.
- Skill packages under `skills/` are versioned alongside the client tool and document the exact client version they target.
