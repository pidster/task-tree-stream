# Rust SDK: embedded vs remote server mode

**Status:** Disposable research note, not a design document. The throwaway Cargo project it references lives under `docs/research/experiments/sdk-spike/`, starts with its own disposability header, and is never referenced from product code (none exists yet — Phase 0/1 gate).

**Question:** What is the feature parity between the Rust SDK's embedded mode and remote server mode? What storage backends are available (memory, rocksdb, surrealkv, others), and what are the implications for tests vs deployment? What is the exact MSRV and SDK crate version? Recommendation: embedded vs remote for dev, test, and production.

**Method:** Created a disposable Cargo project at `docs/research/experiments/sdk-spike/` (`Cargo.toml` + `src/main.rs`, never at the repo root, never referenced elsewhere). Declared `surrealdb = { version = "3", features = ["kv-mem", "kv-rocksdb"] }` with no version pin beyond the major version, let `cargo build` resolve the latest compatible release, and wrote a small program that: (1) connects in embedded in-memory mode (`mem://`) and does a create+select; (2) connects in embedded file-backed mode (`rocksdb://<path>`) and does a create; (3) connects in remote mode (`ws://127.0.0.1:8901`) against a `surreal start memory` server running locally, signs in as root, and does a create+select. Ran `cargo build` and `cargo run` for real. Inspected the resolved `Cargo.lock` and the downloaded crate's `Cargo.toml` for edition/feature facts. Checked MSRV via web search since it isn't declared in the crate's own `Cargo.toml`.

**Software versions:** Rust/cargo `1.98.0` (host toolchain). SurrealDB server `3.2.3+20260721.40522d1`. `surrealdb` Rust crate resolved to **`3.2.4`** (requested `"3"`, no tighter pin). Full experiment project: `docs/research/experiments/sdk-spike/` (`Cargo.toml`, `src/main.rs`).

## Findings

1. **Verified by running — embedded in-memory mode works end to end.** `connect("mem://")`, `use_ns/use_db`, `.create(("task","e1")).content(...)`, `.select(("task","e1"))` all succeeded:
   ```
   === embedded mem:// ===
   embedded create result: Some(Task { status: "embedded-created" })
   embedded select result: Some(Task { status: "embedded-created" })
   ```

2. **Verified by running — embedded RocksDB (file-backed) mode works.** `connect("rocksdb:///tmp/sdk-spike-rocksdb-data")` with the `kv-rocksdb` feature enabled created a record successfully:
   ```
   === embedded rocksdb:// ===
   rocksdb create result: Some(Task { status: "rocksdb-created" })
   ```
   This confirms a durable, file-backed embedded engine is available for local dev/test persistence without running a separate server process, distinct from the pure in-memory engine.

3. **Verified by running — remote mode against a real `surreal start` server works, using the same `connect()`/query API surface as embedded mode.** `connect("ws://127.0.0.1:8901")`, `.signin(Root { username, password })`, `use_ns/use_db`, `.create()`, `.select()` all succeeded once the server was confirmed reachable:
   ```
   === remote ws:// ===
   remote create result: Some(Task { status: "remote-created" })
   remote select result: Some(Task { status: "remote-created" })
   ```
   The client code is identical across embedded and remote except for the connection string and the extra `.signin()` call remote mode needs (embedded mode in this test had no auth configured). This is a strong practical signal for feature parity at the query/CRUD API level via `surrealdb::engine::any::connect`, which erases the embedded-vs-remote distinction behind one `Surreal<Any>` handle.

4. **Verified by running — the current SDK's data-binding API differs from older tutorials/examples that use `serde::Serialize`/`Deserialize` directly.** The first build attempt, using `#[derive(Serialize, Deserialize)]` structs from `serde` passed to `.content()`, failed to compile with `the trait bound 'Task: SurrealValue' is not satisfied` (10 errors). The fix was to derive `surrealdb::types::SurrealValue` instead (`#[derive(Debug, SurrealValue)]`, importing `surrealdb::types::SurrealValue`), and to use owned `String`s rather than `&str` for `opt::auth::Root { username, password }` (the struct now expects `String`, not `&str` — another compile error caught and fixed). This is a real, current-version fact worth flagging for D08: **any Rust SDK code examples pulled from older blog posts/tutorials that predate the `SurrealValue` trait will not compile against `surrealdb 3.2.4`** without this change. Confirmed by reading the installed crate source (`~/.cargo/registry/.../surrealdb-3.2.4/src/opt/mod.rs`, `src/opt/auth.rs`, `src/opt/resource.rs`), which shows `SurrealValue` used throughout `Create`, `Select`, and `Credentials` bounds, and is derivable via `#[derive(SurrealValue)]`.

5. **Verified by running / read from crate manifest — available storage-backend (kv-*) feature flags.** Inspecting the resolved `surrealdb-3.2.4` crate's `Cargo.toml` shows feature flags `kv-mem`, `kv-rocksdb`, `kv-surrealkv`, `kv-indxdb`, `kv-tikv` (each gating `surrealdb-core/kv-*`), with `kv-mem` and `kv-rocksdb` (plus `protocol-ws`, `protocol-http`) enabled by default. We only exercised `kv-mem` and `kv-rocksdb` by running (Findings 1-2); `kv-surrealkv`, `kv-indxdb`, and `kv-tikv` were read from the manifest, not run. `kv-tikv` implies a distributed backend option exists but was out of scope to test locally.

6. **Read in docs — MSRV for the current SDK/crate line is Rust 1.89 or newer.** Not declared as a `rust-version` field in the crate's own `Cargo.toml` (checked directly — absent), so this is sourced from SurrealDB's own docs/marketing pages via web search, consistent with the earlier 2026-09-10 status note. Our host toolchain (rustc 1.98.0) comfortably exceeds this and the crate itself declares `edition = "2024"` (read directly from the crate manifest), which itself requires a fairly recent stable toolchain (edition 2024 stabilised in Rust 1.85). Source: search summary of surrealdb.com SDK pages, checked 2026-09-14; crate manifest read directly from `~/.cargo/registry/src/.../surrealdb-3.2.4/Cargo.toml`.

7. **Negative result — crates.io was unreachable via plain `curl` (HTTP 403) but fully reachable via `cargo build`'s own fetch path.** `curl -s -o /dev/null -w "%{http_code}" https://crates.io/api/v1/crates/surrealdb` returned `403` in this sandboxed environment, which initially looked like it would block this whole experiment. `cargo build` succeeded anyway (downloaded and compiled ~496 transitive dependency crates without issue), so the network restriction is specific to raw `curl` against that endpoint/user-agent, not to cargo's registry client. Recorded here because it could easily be misread as "crates.io is blocked" — it is not, for the tool that actually matters.

## Sources

- Direct build/run of `docs/research/experiments/sdk-spike/` against `surrealdb 3.2.4`, `surreal start memory` 3.2.3+20260721.40522d1, Rust 1.98.0 — 2026-09-14 (verified by running; Findings 1-5, 7).
- `surrealdb-3.2.4` crate manifest and source, read from local cargo registry cache (`~/.cargo/registry/src/index.crates.io-*/surrealdb-3.2.4/Cargo.toml`, `src/opt/*.rs`) — checked 2026-09-14 (verified by reading the actual installed crate, not marketing docs).
- Web search summarising SurrealDB Rust SDK MSRV claims (surrealdb.com/docs/languages/rust/overview and sibling pages) — checked 2026-09-14 (read in docs, corroborates 2026-09-10-surrealdb-status.md).

## Implications for design (D02/D08)

- **Recommend embedded mode (in-memory `mem://`) for unit/integration tests**, and embedded RocksDB (`rocksdb://`) for any test or local-dev scenario that needs data to survive a process restart without standing up a server — both are verified working with the same client API as production remote mode (Finding 3), so test code and production code can share query logic behind `surrealdb::engine::any::connect`, varying only the connection string. This directly supports E5 (reproducible local environment) and E6 (test coverage) from `docs/objectives.md`.
- **Recommend remote mode (WS) for actual deployment**, since that's the only mode that supports multiple concurrent connections from separate processes/machines (an embedded engine is in-process and single-owner) — which the whole multi-agent claiming model (see the transactions note) depends on. This should be stated explicitly in D08 as the deployment default, with embedded RocksDB offered as an option only for a genuinely single-process/single-tenant deployment if that ever becomes a requirement (not currently a stated objective).
- **D08 must budget for the `SurrealValue` derive, not plain `serde::Serialize`/`Deserialize`**, when specifying how domain types bind to SurrealDB records — Finding 4 is a real, current-version compile-time fact, not a style preference, and will bite anyone copying older example code.
- **D02 should record the storage backend choice per environment explicitly**: `kv-mem` for tests, `kv-rocksdb` or a remote server for local dev persistence, and a real `surreal start`/clustered deployment (still untested here beyond a single local `memory` instance) for production. `kv-surrealkv`, `kv-indxdb`, and `kv-tikv` exist as documented options but were not run in this pass (Finding 5) — if a distributed or alternative on-disk engine becomes relevant, that needs its own follow-up experiment before D02 is approved on that point.
- The crates.io/curl finding (Finding 7) is operational, not a design fact — noted so a future agent doesn't waste time concluding registry access is broken based on a `curl` probe alone.
