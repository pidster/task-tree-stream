# Recursive / multi-hop traversal for subtrees and dependency closure, and depth limits

**Disposable research note.** Not product code. Supports D01/D02. See `docs/research/experiments/2026-09-14-edges-vs-links.surql` for the runnable (disposable) SurrealQL this note is based on; this note focuses specifically on the recursion mechanics and limits (the edge-vs-link modelling question is covered in `2026-09-14-edges-vs-record-links.md`).

## Question

Does SurrealDB 3.x support a single query for "the whole subtree under this task" and "the whole dependency closure blocking/blocked-by this task", at arbitrary depth? What is the query syntax, what depth limits exist, and what happens when a query exceeds them?

## Method

Verified by running, against a local `surreal start --user root --pass root memory` instance (SurrealDB 3.2.3), using both `surreal sql` and the HTTP `/sql` endpoint. Built a 5-level containment chain (`task:c1` → `c2` → `c3` → `c4` → `c5` → `c6`) via a `contains` `RELATE` edge and probed the recursion operator's syntax, its `+collect`/`+path`/`+inclusive` modifiers, and its documented and observed depth bounds. Cross-checked syntax against the official docs page for recursive idioms.

## Findings

- SurrealDB 3.x's recursive traversal is expressed as an idiom: `<start>.{<depth-spec>+<algorithm>}(<repeated-path>)`. The repeated path is whatever sits inside the parentheses (e.g. `->contains->task`, or a plain field like `.parent`) and is re-applied `<depth-spec>` times. Depth-spec forms verified: `..` (unbounded, subject to the limit below), `1..5` (a range), and a bare `256` maximum bound. Read in docs and confirmed by running:
  - `RETURN task:c1.{..+collect}(->contains->task);` → `[task:c2, task:c3, task:c4, task:c5, task:c6]` (all 5 descendants, unbounded, one query).
  - `RETURN task:c1.{1..256+collect}(->contains->task);` → same result; 256 is accepted as an explicit upper bound.
  - `RETURN task:c1.{1..300+collect}(->contains->task);` → error: `"Found 300 for bound but expected 256 at most."` **256 is a hard, enforced ceiling on the depth bound you may request**, not just a soft default.
- Three collection algorithms exist, selected as a suffix on the depth spec:
  - `+collect` — returns a deduplicated flat array of every node reached, order not guaranteed to reflect depth. This is what a subtree listing or a dependency closure set should use.
  - `+path` — returns every distinct path from the start node as its own array (an array of arrays). Verified: `RETURN task:root.{1..5+path}(->contains->task);` → `[[task:b], [task:a, task:a2], [task:a, task:a1, task:a1x]]`. Useful for breadcrumbs or "why is this blocked" chains, not for closure sets (it does not deduplicate nodes reached via multiple paths).
  - `+shortest=<target>` — read in docs only (not exercised here): computes the shortest path to a named target record rather than enumerating everything. Likely relevant later for "shortest dependency chain between X and Y" UI features but not needed for D01/D02's core subtree/closure queries.
  - `+inclusive` is a modifier, not an algorithm on its own — it must be combined with one of the three above (e.g. `+collect+inclusive`) to also include the start node in the result set. Attempting `.{..+inclusive}` alone is a parse error: `Unexpected instruction 'inclusive' expected 'path', 'collect', or 'shortest'`.
- **Omitting the parentheses around the repeated path breaks recursion silently rather than erroring usefully in one case we hit**: `SELECT ->contains->task.{..} AS subtree FROM task:root;` (recursion applied as a trailing idiom, not wrapping the graph hop) returned an empty array rather than the subtree or an error. The parenthesised form, `task:root.{..+collect}(->contains->task)`, is required for the graph hop itself to repeat. This is an easy mistake to make and worth calling out explicitly in D02 so implementers use the parenthesised form from the start.
- **`+path` without an explicit upper bound can hit an internal recursion guard even on a tiny graph.** `SELECT ->contains->task.{..+path} AS subtree FROM task:root;` (6 nodes, depth 3) produced `"Exceeded the idiom recursion limit of 256."` `+collect` on the same unbounded query did not hit this. We did not fully diagnose why `+path` is more expensive here (plausibly it explores more of the graph shape before collapsing, or the malformed non-parenthesised form contributed) — this should be re-tested against the corrected parenthesised syntax before being relied on, and is flagged as a follow-up rather than a settled negative result.
- We did not test performance/latency at scale (hundreds or thousands of tasks, deep or wide trees). All traversals above ran against small (5–6 node) in-memory test graphs in well under a millisecond each per the engine's own reported `time` field. That says nothing about query planning or cost at production scale — a follow-up experiment with a synthetic large tree/graph is recommended before committing to unbounded recursive queries as a hot path in the agent protocol (e.g. "give me my next unblocked task" should probably not require an unbounded closure scan on every poll).
- No SurrealDB-documented behavioural difference was found between 2.x and 3.x specifically for the recursion operator's depth bound or algorithms; the 2.x→3.x migration guide flags "idiom fetching changes" for array/object idiom behaviour generally (can break) but does not call out the recursion operator's depth cap as new in 3.x. Read in docs; not independently confirmed against a 2.x instance (out of scope — 2.x is not the version we are pinning).

## Sources

- Recursive idiom syntax reference (`.{depth}(path)`, `+path`/`+collect`/`+shortest`/`+inclusive`, and "the number of steps can be any integer from 1 to 256"): https://surrealdb.com/docs/surrealql/datamodel/idioms#recursive-path-querying — checked 2026-09-14 (read in docs; the depth bound was also independently verified by running, see above).
- 2.x→3.x migration guide, "idiom fetching changes" (Can break): https://surrealdb.com/docs/build/migrating/from-old-surrealdb-versions/2x-to-3x — checked 2026-09-14. Read in docs only.
- All other findings above: verified by running against SurrealDB 3.2.3+20260721.40522d1, local `memory` instance.

## Exact versions used

- SurrealDB: `3.2.3+20260721.40522d1`, installed via Homebrew tap `surrealdb/tap`.
- Run mode: `surreal start --user root --pass root memory`; queries via `surreal sql` and the HTTP `/sql` endpoint on `127.0.0.1:8000`.

## Implications for design

1. D02 should specify the two canonical recursive query templates using the verified, parenthesised syntax:
   - Subtree of `X`: `RETURN $x.{1..<max>+collect}(->contains->task);`
   - Dependency closure of `X` (what blocks it): `RETURN $x.{1..<max>+collect}(->depends_on->task);`
   - Reverse closure (what `X` blocks): `RETURN $x.{1..<max>+collect}(<-depends_on<-task);`
   with `<max>` an application-level constant (e.g. 50), never `..` unbounded, and never above 256 (the server rejects it outright).
2. Always use `+collect` for subtree/closure sets in product code; reserve `+path` for path-enumeration UI features and give it an explicit bound — its cost profile is not yet characterised at scale (open follow-up).
3. Treat "give me the next unblocked task" as needing a bounded, indexed query, not an unbounded recursive scan on every agent poll; D02/the protocol design should consider whether closure results are cached/materialised (e.g. a `blocked` boolean maintained on write) rather than recomputed recursively on every read, once real task counts are known. This is a design decision, not a fact this note can settle — flagging it as an open question for D02 rather than guessing.
4. Before approving D02, run a follow-up experiment (not done here — out of the time budget for this task) with a synthetic tree of realistic size (hundreds of nodes, depth 10–20) to get real latency numbers for `+collect` subtree/closure queries; the sub-millisecond timings observed here are not evidence of production-scale performance.
