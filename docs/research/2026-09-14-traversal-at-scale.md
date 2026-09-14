# Traversal performance at scale: is D01's derived stream affordable?

**Disposable research note.** Not product code. Supports D01 §3.2 and D02. Experiment
scripts (disposable, never imported by product code) are at
`docs/research/experiments/2026-09-14-generate-traversal-data.py` and
`docs/research/experiments/2026-09-14-run-traversal-benchmark.sh`.

## Question

D01 §3.2 defines a task's derived stream as: collect its subtree, collect the
dependency closure over graph edges within/touching that subtree, then topologically
order the result. §3.2's open question Q1 asks whether this can be computed on every
request or needs caching/materialisation. This note measures, by running real
queries against real data volumes on SurrealDB 3.2.3, whether the two expensive
primitives underlying that derivation — subtree collection and dependency-edge
lookup within a subtree — are affordable at 1k, 10k, and 100k tasks, so D02 can pick
between derived-per-request, derived-and-cached, and stored ordering.

## Method

Verified by running, on a single MacBook (Apple Silicon, macOS), against a local
`surreal start --user root --pass root memory` instance, SurrealDB
`3.2.3+20260721.40522d1` (Homebrew tap `surrealdb/tap`), HTTP endpoint
`127.0.0.1:8000`. No Rust SDK crate used — raw SurrealQL via the `/sql` HTTP
endpoint and `surreal import`, matching the method used in the two prior traversal
notes this one extends.

**Data generation** (`2026-09-14-generate-traversal-data.py`, disposable): a
containment tree built breadth-first, branching factor uniform in [3, 8] per node,
depth capped at 10, truncated once the target task count N is reached; plus
`depends_on` edges added for ~30% of non-root tasks, each pointing from a
higher-creation-index task to a uniformly-chosen lower-index task — this guarantees
a DAG (no cycle check needed, since edges only point backward in creation order) and
matches the ~0.3-per-task density the task specified. Each task record also carries
denormalised `parent` and `root` record-link fields (indexed) for query (b). Actual
generated shapes:

| N | max depth reached | `contains` edges | `depends_on` edges |
| --- | --- | --- | --- |
| 1,000 | 5 | 999 | 275 |
| 10,000 | 6 | 9,999 | 3,009 |
| 100,000 | 7 | 99,999 | 29,756 |

**Loading.** Sending the whole `.surql` file to the `/sql` HTTP endpoint in one POST
hit the server's request body size limit at 100k rows (`"length limit exceeded"`).
Switched to `surreal import` (which requires `OPTION IMPORT;` as the first statement
in the file — this disables events, live queries, and per-statement result output
for import performance) for all sizes to keep the loading method consistent; load
itself is not a query under test and its cost is noted but not analysed further.

**Four query shapes measured**, run 5 times each per size (except (d) at 100k, see
below), reporting median and max of both (i) end-to-end wall-clock as observed by
the HTTP client (`curl`, loopback, includes JSON parse/marshalling on the server)
and (ii) the SurrealDB engine's own self-reported per-statement execution time
(the `time` field in the `/sql` response), which excludes HTTP/transport overhead:

- **(a) Subtree collect via recursive edge traversal**, from the root, i.e. the
  worst case (whole tree): `RETURN task:t0.{1..50+collect}(->contains->task);`
- **(b) Subtree collect via denormalised field**, same worst case, using the
  indexed `root` field: `SELECT id FROM task WHERE root = task:t0;`
- **(c) Dependency closure for one leaf**: the deepest generated leaf task, via
  `RETURN <leaf>.{1..50+collect}(->depends_on->task);`
- **(d) All enforced dependencies within a subtree, in one query** (again the
  root's subtree, the worst case): collect the subtree inclusively, then find
  `depends_on` edges with both endpoints inside it:
  ```
  LET $subtree = task:t0.{1..50+collect+inclusive}(->contains->task);
  RETURN (SELECT * FROM depends_on WHERE in INSIDE $subtree AND out INSIDE $subtree);
  ```

Server RSS was sampled once per size via `ps -o rss=` on the `surreal` process
after loading and querying. A fresh server process was used per size.

**Deviation from the 5x-per-query protocol:** query (d) at N=100,000 took 243
seconds for a single run (see results). Running it 5 times would have taken over 20
minutes, well past the 10-minute-per-size intent implied by the task's own "under
ten minutes" escalation clause for N=100k as a whole. One run was taken and is
reported as such; queries (a), (b), (c) at 100k were still run 5 times each, since
each individually completed in well under a second.

## Results

Wall-clock is the client-observed `curl` round-trip; engine is SurrealDB's own
reported execution time for the statement. All times in milliseconds unless
marked. RSS is the whole `surreal` server process, sampled after each size's run.

| N | Query | Wall median | Wall max | Engine median | Engine max | Server RSS |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 1,000 | (a) recursive subtree, from root | 11.4 | 12.0 | 1.41 | 1.46 | 198 MB |
| 1,000 | (b) denormalised-field subtree | 11.0 | 11.2 | 0.92 | 0.94 | 198 MB |
| 1,000 | (c) dependency closure, one leaf | 10.0 | 10.0 | 0.067 | 0.068 | 198 MB |
| 1,000 | (d) deps within subtree (root) | 34.3 | 34.9 | 22.5 | 22.6 | 198 MB |
| 10,000 | (a) recursive subtree, from root | 24.6 | 24.8 | 13.6 | 13.7 | 311 MB |
| 10,000 | (b) denormalised-field subtree | 21.0 | 23.0 | 8.0 | 8.7 | 311 MB |
| 10,000 | (c) dependency closure, one leaf | 10.1 | 10.3 | 0.063 | 0.069 | 311 MB |
| 10,000 | (d) deps within subtree (root) | 2,447 | 2,453 | 2,420 | 2,426 | 311 MB |
| 100,000 | (a) recursive subtree, from root | 192 | 199 | 151.7 | 153.5 | 1,023 MB |
| 100,000 | (b) denormalised-field subtree | 159 | 172 | 87.4 | 91.8 | 1,023 MB |
| 100,000 | (c) dependency closure, one leaf | 32.3 | 33.1 | 0.087 | 0.093 | 1,023 MB |
| 100,000 | (d) deps within subtree (root), **n=1 run** | 243,231 | — | 243,231 | — | 1,023 MB |

## Findings — verified by running

1. **Subtree collection (a, b) scales roughly linearly with tree size and is cheap
   at every size tested**, including the worst case of collecting the entire tree
   from the root: ~1.4ms engine time at 1k, ~14ms at 10k, ~152ms at 100k for the
   recursive-edge form. This is affordable as a per-request operation at all three
   sizes for a subtree query alone.
2. **The denormalised-field subtree query (b) is consistently 1.4-1.7x faster than
   the recursive-edge query (a)** at every size (e.g. 87ms vs 152ms engine time at
   100k), but both are cheap in absolute terms up to 100k tasks. The record-link
   approach is a genuine speed-up, not a necessity, at these sizes — consistent with
   the companion note's recommendation to keep it as a convenience field, not a
   substitute for the edge as source of truth.
3. **Dependency closure for a single leaf (c) is essentially free at every size**
   (sub-0.1ms engine time even at 100k) because it only walks the small number of
   `depends_on` edges actually reachable from that one node — it does not scale with
   total tree size, only with the size of that task's own dependency chain.
4. **Query (d) — finding all `depends_on` edges whose endpoints both fall within a
   given subtree — does *not* scale acceptably.** Its cost grew far faster than
   linear with N: 22.5ms (1k) → 2,420ms (10k, ~108x for a 10x increase in N) →
   243,231ms (100k, ~100x again for another 10x increase in N). That is
   consistent with roughly quadratic-or-worse scaling, and it went from
   imperceptible to a 4-minute single query between 10k and 100k tasks. The
   `WHERE in INSIDE $subtree AND out INSIDE $subtree` form is doing what is very
   likely a linear (or near-linear) membership check against the `$subtree` array
   for every row of the `depends_on` table (`~30k` rows at 100k tasks), and/or the
   query planner is not using the `depends_on` table's structure to restrict the
   scan before the membership check — we did not run `EXPLAIN` on this query at
   scale to confirm the exact plan (a gap; see Implications point 4), but the
   observed scaling is unambiguous regardless of mechanism.
5. **Server RSS scales roughly linearly with task count** (~0.2 GB at 1k, ~0.3 GB
   at 10k, ~1.0 GB at 100k, in-memory backend) — not itself a blocker at these
   sizes for a single-node deployment, but worth tracking for D02's sizing
   guidance since this was measured with the `memory` backend (no persistence) and
   the task's other benchmark (rocksdb backend) was not run in this pass — time
   budget went to the query-shape investigation instead once (d)'s scaling problem
   became the dominant question. This is a stated scope gap, not a claim that
   rocksdb would behave identically.
6. Loading 100,000 tasks plus ~130,000 edges via `surreal import` took ~5.6
   seconds; this is a one-time cost per size in this experiment, not a per-request
   cost, and is reported only for completeness.

## Sources

- All numeric findings above: verified by running against SurrealDB
  `3.2.3+20260721.40522d1`, local `surreal start memory` instance, as described in
  Method.
- Recursive idiom syntax and the 256 depth-bound ceiling: already verified in
  `docs/research/2026-09-14-recursive-traversal.md` (2026-09-14) and relied on
  unchanged here (`{1..50+collect}` used throughout, well under the ceiling).
- `surreal import` requiring `OPTION IMPORT;` as the first statement, and its
  effect (disables events, live queries, field processing, per-statement result
  output): read from the server's own error message when the import was first
  attempted without it, and confirmed by running with it added. Not independently
  cross-checked against a docs page in this pass.

## Implications for D01 Q1 and D02

1. **Answering D01 §3.2 Q1 directly: the derived stream is *not* uniformly
   affordable to compute on every request as tree size grows, but the reason is
   narrow.** Subtree collection and single-task dependency closure (the two
   primitives most of D01's derivation logic would call per-request, per-task) stay
   cheap (low tens of milliseconds or better) up to 100,000 tasks. The specific
   operation that breaks is bulk "all dependency edges inside this subtree" lookups
   at subtree sizes in the tens-of-thousands-of-tasks range and above.
2. **Recommendation for D02: derived-per-request for subtree and single-task
   dependency-closure reads, up to at least 100k tasks; but the subtree-wide
   dependency-edge lookup (query shape (d)) needs a different implementation before
   it is exposed as a per-request operation at all**, not merely cached. Caching a
   243-second query does not make it request-affordable to *populate* the cache
   (e.g. after any edit invalidates it for a large subtree), and if D02 needs "give
   me every enforced dependency inside subtree X" as a real feature (it plausibly
   does, for stream construction per §3.2), the fix belongs in the data model or
   query shape, not in a caching layer bolted onto the current query. Candidates
   worth a follow-up experiment before D02 is written: (i) denormalise a
   `root`/subtree-id field onto `depends_on` edge records themselves (mirroring the
   `task.root` convenience field validated here for query (b)) so the lookup
   becomes an indexed equality scan instead of an array-membership scan against
   every edge row; (ii) check whether `EXPLAIN` shows the planner failing to use
   the `depends_on` table at all for this shape and whether an index on `in`/`out`
   changes that; (iii) re-test after SurrealDB 3.3 stabilises, given its
   advertised "reworked graph engine... much faster traversals" (flagged as a
   follow-up in the edges-vs-links note already).
3. **Sizes at which each option stops being viable, based on what was actually
   measured:**
   - **Derived-per-request** is viable for subtree reads and single-task
     dependency closure at every size tested (up to 100k), and is the simplest
     option — recommended as the default for those two operations. It should
     **not** be used as-is for the "all dependencies inside a subtree" shape (d)
     past roughly 10,000 tasks in the target subtree: at 10k it is already a
     2.4-second query, well outside anything that should run synchronously on an
     agent's request path; at 100k it is a 4-minute query and untenable at any
     frequency above "cold, background, and cached."
   - **Derived-and-cached** does not rescue query shape (d) on its own (see point
     2) — caching helps only if population is itself cheap, and populating a cache
     with a 4-minute query for one subtree is not a workable pattern at
     interactive latencies. It is a reasonable strategy for (a)/(b)/(c) if D02
     wants to avoid even tens-of-milliseconds recomputation on a hot path (e.g. a
     UI stream view refreshed frequently), but is optional at these sizes, not
     required.
   - **Stored ordering** (materialising the derived stream's order on write,
     updated incrementally as edges/tasks change) is the only option this note's
     evidence supports once a project's subtree approaches the 10,000-100,000-task
     range **if** the "dependencies inside a subtree" operation is a required part
     of computing that order per §3.2. If D02 can avoid needing that specific bulk
     lookup (e.g. by deriving the topological order from per-task closures instead
     of a single bulk query), stored ordering may not be required until much
     larger scales — this is a design choice for D02, not something this note can
     settle, and is flagged as exactly the kind of decision the task's escalation
     boundary reserves for D02, not this note.
4. **Gaps to close before D02 relies on this note:** no `EXPLAIN` was captured for
   query (d) to confirm *why* it scales this badly (index absence vs. planner
   behaviour vs. the `INSIDE` operator's implementation) — recommended as a fast,
   cheap follow-up before committing to a specific fix in point 2. The `rocksdb`
   backend was not benchmarked (time budget went to characterising (d)'s scaling
   instead, since it was the dominant finding); persistence overhead could change
   the picture, particularly for the RSS and load-time numbers, and mildly for
   query latency. Only one tree/DAG shape (branching 3-8, one seed) was tested per
   size — variance across shapes (e.g. very wide shallow trees vs. very deep
   narrow ones) was not explored.

## Exact versions used

- SurrealDB: `3.2.3+20260721.40522d1` (`surreal version`), installed via Homebrew
  tap `surrealdb/tap`.
- Run mode: `surreal start --user root --pass root memory` (in-memory, no
  persistence), HTTP endpoint `127.0.0.1:8000`; data loaded via `surreal import`.
- Python: 3.14.7 (data generator only; not part of the product).
- No Rust SDK crate used.
