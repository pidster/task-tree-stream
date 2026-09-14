# Edges vs. record links for the containment tree, dependency graph, and user-defined relationships

**Disposable research note.** Not product code. Supports D01/D02. See `docs/research/experiments/2026-09-14-edges-vs-links.surql` for the runnable (disposable) SurrealQL.

## Question

For the containment tree (project → task → sub-task), the dependency graph (task depends on task), and arbitrary user-defined relationships between tasks: should we model these as SurrealDB graph edges (`RELATE` into an edge table), or as record-link fields on the `task` table (e.g. a `parent: record<task>` field)? What are the query ergonomics, performance characteristics, and constraints of each, on SurrealDB 3.x?

## Method

Verified by running. Started `surreal start --user root --pass root memory` (SurrealDB 3.2.3) locally and ran statements against it via the HTTP `/sql` endpoint (`curl -u root:root -H "surreal-ns: research" -H "surreal-db: edges"`) and via `surreal sql`. Built a small containment tree (`task:root` → `task:a`/`task:b` → `task:a1`/`task:a2` → `task:a1x`), a dependency edge (`task:a2 -depends_on-> task:a1`, `task:b -depends_on-> task:a`), and a user-defined edge (`task:a -related_to-> task:b`). Full statements and results are in the experiment file; representative results are inlined below.

**Note on tooling:** piping a whole `.surql` file into `surreal sql` stops executing further statements after a parse error partway through the file (the REPL echoed the same parse error dozens of times and silently dropped the remaining statements). Running statements individually against the HTTP `/sql` endpoint was more reliable for iterative experimentation and is what was used once the first parse error was hit.

## Findings

**Both mechanisms coexist without conflict.** A `task` table can have a `parent: option<record<task>>` field (a record link) and also participate in `RELATE`-created edge tables (`contains`, `depends_on`, `related_to`) simultaneously. Nothing about the two approaches is exclusive.

**Record links (`parent: record<task>` field):**
- Defining the field: `DEFINE FIELD parent ON task TYPE option<record<task>>;` plus `DEFINE INDEX task_parent_idx ON task FIELDS parent;` for fast reverse lookup. Verified: `SELECT * FROM task WHERE parent = task:a` returns direct children using the index.
- **Ancestor walks (going up a single-valued field) work with the built-in recursion operator**: `RETURN task:a1x.{..+collect}(.parent);` returned `[task:a1, task:a, task:root]` — a full ancestor chain in one query, verified by running.
- **Descendant/subtree walks (going down, i.e. reverse + filtered lookup) do *not* work with the recursion operator.** Both `task:a.{..+collect}(<-task WHERE parent = $this)` and a `(SELECT VALUE id FROM task WHERE parent = $this)` form inside the recursion parentheses produced parse errors ("expected delimiter `)`"). The recursion operator `.{..}(...)` only recurses over graph traversals (`->edge->table`) or simple forward field idioms (`.field`); it does not support an arbitrary filtered reverse-lookup subquery as the repeated step. So a full subtree query over a parent-link tree requires either one query per depth level issued by the client, or a server-side stored `FUNCTION` doing manual recursion — there is no single built-in SurrealQL query for "give me the whole subtree" when containment is modelled as a record link.

**Graph edges (`RELATE`, e.g. `contains`, `depends_on`, `related_to`):**
- `DEFINE TABLE contains TYPE RELATION FROM task TO task SCHEMAFULL;` then `RELATE task:root->contains->task:a;` creates edge records with `in`/`out` fields, queryable as their own table (`SELECT * FROM contains`) and indexable (`DEFINE INDEX ... ON depends_on FIELDS kind` was used by the query planner — confirmed via `EXPLAIN`, which showed `IndexScan`).
- One-hop traversal: `SELECT ->contains->task AS children FROM task:a;`.
- **Recursive subtree/closure traversal works cleanly and is the main practical advantage of edges over links for tree/graph shapes.** The syntax is `<record>.{<depth>+<algorithm>}(<path>)` — the recursive path must be wrapped in parentheses for the whole hop to repeat. `.{..+inclusive}` with no algorithm and no parens is a parse error: `Unexpected instruction 'inclusive' expected 'path', 'collect', or 'shortest'`. Correct, verified forms:
  - `RETURN task:root.{..+collect}(->contains->task);` → `[task:b, task:a, task:a1, task:a2, task:a1x]` (deduplicated descendant set, unbounded depth).
  - `RETURN task:root.{..+collect+inclusive}(->contains->task);` → same plus `task:root` itself.
  - `RETURN task:b.{..+collect}(->depends_on->task);` → `[task:a]` — dependency closure (what must finish before `task:b` can start).
  - `RETURN task:a1.{..+collect}(<-depends_on<-task);` → `[task:a2]` — reverse closure (what is transitively blocked by `task:a1`).
  - `RETURN task:root.{1..5+path}(->contains->task);` → `[[task:b], [task:a, task:a2], [task:a, task:a1, task:a1x]]` — `+path` returns every distinct root-to-leaf path rather than a deduplicated set; useful for rendering breadcrumbs but not for closure sets.
- User-defined edges work the same way and carry their own metadata: `DEFINE TABLE related_to TYPE RELATION FROM task TO task SCHEMALESS; RELATE task:a->related_to->task:b SET note = 'shares a reviewer', weight = 3;` then `SELECT ->related_to->task, ->related_to.* AS edge_meta FROM task:a;` returns both the related record and the edge's own fields. This is the natural place to hang edge-level metadata (e.g. `kind`, `created_at`, `weight`) that a record-link field cannot carry (a link is just an ID, not a relationship record).

**Depth limit.** The recursion operator's bound is capped at 256: `RETURN task:c1.{1..300+collect}(->contains->task);` → error `"Found 300 for bound but expected 256 at most."` `{1..256+collect}` succeeds. An unbounded `{..}` combined with `+path` on even a 6-node test graph hit an internal guard: `"Exceeded the idiom recursion limit of 256"` — `+path` (which enumerates all paths, not a deduplicated node set) is more expensive and should always be given an explicit upper bound in real queries; `+collect` did not hit this limit on the same graph.

## Sources

- SurrealDB recursive idiom syntax, `.{depth}(path)`, `+path`/`+collect`/`+shortest`/`+inclusive`, and the 1–256 depth bound: https://surrealdb.com/docs/surrealql/datamodel/idioms#recursive-path-querying — checked 2026-09-14.
- `RELATE` statement reference: https://surrealdb.com/docs/surrealql/statements/relate — checked 2026-09-14.
- 2.x → 3.x migration notes, "Record reference syntax... will break" and idiom-fetching changes: https://surrealdb.com/docs/build/migrating/from-old-surrealdb-versions/2x-to-3x — checked 2026-09-14 (fetched via summarisation tool; treat the exact wording as approximate, the behavioural claims above were independently verified by running against 3.2.3).
- All bulleted findings above not citing a doc URL were verified by running against a local `surreal start memory` instance, SurrealDB 3.2.3+20260721.40522d1 (macOS aarch64, installed via `brew install surrealdb/tap/surreal`).
- SurrealDB 3.3 release status ("beta" as of 2026-09-14, `3.3.0-beta.4`, graph engine overhaul): https://surrealdb.com/releases/3.3 — checked 2026-09-14, read in docs.

## Exact versions used

- SurrealDB: `3.2.3+20260721.40522d1` (`surreal version`), installed via Homebrew tap `surrealdb/tap`.
- Run mode: `surreal start --user root --pass root memory` (in-memory, no persistence), HTTP endpoint `127.0.0.1:8000`.
- No Rust SDK crate was used for this note (raw SurrealQL via `surreal sql` and the HTTP `/sql` endpoint only); SDK-specific behaviour is out of scope here per the task's escalation boundary.

## Implications for design

1. **Model containment, dependency, and user-defined relationships as graph edges (`RELATE`), not record-link fields**, specifically because subtree and dependency-closure queries — core to O1 and to the agent protocol's "give me the next unblocked task" behaviour — are a single built-in recursive query over edges, and are *not* expressible as a single query over a parent-link field. This directly serves objective O1 ("no relationship encoded in free text" / natively stored) and keeps subtree/closure logic in the database rather than in application-side loop code.
2. Use one edge table per relationship kind (`contains` for the tree, `depends_on` for the dependency graph) rather than one generic edge table with a `type` discriminator, so each can carry its own schema (`SCHEMAFULL`) and be indexed independently; this also keeps `EXPLAIN` plans and index definitions simple. User-defined edges (arbitrary relationships end users create) should use a distinctly named, `SCHEMALESS` edge table (or a small family of them) so metadata keys are not constrained up front — see the companion metadata note for the indexing trade-off this implies.
3. Still give `task` an optional single-valued `parent` **record-link field in addition to the `contains` edge**, kept in sync at write time, purely as a cheap O(1) "who is my direct parent" read that does not require a graph hop — useful for breadcrumb rendering and permission checks — while treating the `contains` edge as the source of truth for subtree queries. This is a convenience denormalisation, not a substitute for the edge; D02 should record which write path keeps them consistent (e.g. only `RELATE ... contains ...` is exposed at the API layer, and a trigger/event or application logic derives `parent`).
4. Cap client-issued recursive depth requests well under 256 (e.g. default to an application-level constant such as 50) and always pick `+collect` for closure/subtree sets; reserve `+path` for UI features that need actual path enumeration (breadcrumbs, "why is this blocked" chains) and always bound it explicitly.
5. D02 should record the exact recursive-query templates for "subtree of node X" and "dependency closure of node X" as the two canonical read patterns other design docs (protocol, API) can cite, using the verified syntax above.
6. **Version to pin: SurrealDB `3.2.x`, currently `3.2.3` (the version used throughout this research pass).** `3.3` exists only as a beta (`3.3.0-beta.4`, released 2026-09-09) at the time of writing and advertises "a reworked graph engine with new relation types and much faster traversals" (source below) — directly relevant to this project's edge-heavy data model, but not something to build against pre-release. Re-check `3.3`'s graph-engine changes once it reaches stable, since it may change edge/traversal performance or syntax materially; this is a follow-up for whoever revisits D02 after a `3.3` stable release, not a blocker now.
