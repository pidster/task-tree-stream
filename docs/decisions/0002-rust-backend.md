# 0002: Rust for the backend

**Status:** Accepted — 2026-09-10

## Context

The backend serves an agent protocol and a human UI, talks to SurrealDB, and must be predictable under concurrent agent load. The founder has specified Rust. SurrealDB itself is written in Rust and its first-party SDK is Rust, which allows embedded mode and avoids a serialization boundary with a foreign client.

## Decision

The server is a single Rust Cargo workspace. No other runtime language on the server. Crate boundaries, web framework, and async runtime are chosen in design doc D08.

## Consequences

- Strong typing for the domain model and protocol messages; state machines can be enforced at compile time where sensible.
- Slower iteration than a scripting language during early development. Mitigation: the design gate reduces churn, and T2 agents implement against precise specs.
- The UI stack is a separate decision (D07/D08); it may be a browser app served by the Rust backend or built separately.
- Contributors and agents must work in Rust; role definitions and task specs will assume it.

## Alternatives

- **TypeScript/Node.** Faster to prototype, shares a language with the likely UI. Rejected per founder direction and for weaker guarantees under concurrency.
- **Go.** Comparable operational profile. Rejected because the SurrealDB first-party SDK and embedded mode favour Rust.
