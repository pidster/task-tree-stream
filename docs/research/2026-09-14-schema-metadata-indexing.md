# Schema-full vs. schema-less tables, and indexing user-defined metadata keys

**Disposable research note.** Not product code. Supports D01/D02. See `docs/research/experiments/2026-09-14-metadata-indexing.surql` for the runnable (disposable) SurrealQL.

## Question

Objective O2 requires users to attach arbitrary key/value metadata to tasks, then filter and query on it, with no schema migration. What table/field strategy on SurrealDB 3.x lets us do that while keeping the metadata queryable, and — for keys worth it — indexable?

## Method

Verified by running against a local `surreal start --user root --pass root memory` instance (SurrealDB 3.2.3), via the HTTP `/sql` endpoint. Compared four strategies on a `task`-like table, each described below, checking: can I write an arbitrary, previously-undeclared key; can I query on it; can I index a specific key after the fact; does `EXPLAIN` show the index being used.

## Findings

**Strategy A — `SCHEMAFULL` table with a `FLEXIBLE` object field.**
```
DEFINE TABLE task2 SCHEMAFULL;
DEFINE FIELD title ON task2 TYPE string;
DEFINE FIELD meta ON task2 TYPE option<object> FLEXIBLE;
```
- `FLEXIBLE` must appear **after** the `TYPE` clause (`TYPE option<object> FLEXIBLE`), not before it — `FLEXIBLE TYPE option<object>` is a parse error (`"FLEXIBLE must be specified after TYPE"`). This is a real gotcha worth documenting since several blog-era examples online show the old ordering.
- `FLEXIBLE` is only legal on a field of a `SCHEMAFULL` table (documented and confirmed: attempting it on a table not yet marked `SCHEMAFULL` in the same session errored `"FLEXIBLE can only be used in SCHEMAFULL tables"`).
- Once defined, arbitrary nested keys can be written (`CREATE task2:x SET meta = { priority: 'high', customer: 'acme' }`) and queried (`SELECT * FROM task2 WHERE meta.priority = 'high'` and `WHERE meta.region = 'eu'` both worked, for two records with entirely different key sets) with **no field/key predeclared** beyond the top-level `meta` field itself.
- Un-indexed keys are found via a `TableScan` (confirmed via `EXPLAIN`: `"operator":"TableScan"`, `"predicate":"meta.region = 'eu'"`) — correct results, but a full scan.
- **A specific key can be indexed after the fact, with no migration of existing rows**: `DEFINE INDEX task2_meta_priority_idx ON task2 FIELDS meta.priority;` and confirmed via `EXPLAIN` that subsequent queries on `meta.priority` use `IndexScan` via that index. This is the key finding for O2: "arbitrary metadata, indexable on demand, no migration" is achievable — defining an index on a nested flexible-object path is a same-class operation to defining one on a normal field, and does not require touching existing data or the table's `SCHEMAFULL` contract.

**Strategy B — `array<object>` k/v pairs with typed sub-fields and a multi-value index.**
```
DEFINE TABLE task3 SCHEMAFULL;
DEFINE FIELD meta ON task3 TYPE array<object>;
DEFINE FIELD meta.*.k ON task3 TYPE string;
DEFINE FIELD meta.*.v ON task3 TYPE string;
DEFINE INDEX task3_meta_k_idx ON task3 FIELDS meta.*.k;
```
- `meta = [{k:'priority', v:'high'}, {k:'customer', v:'acme'}]` writes and reads back correctly; `SELECT * FROM task3 WHERE meta.*.k CONTAINS 'priority'` and `WHERE meta CONTAINS {k:'priority', v:'high'}` both matched. `EXPLAIN` on the `CONTAINS 'priority'` form showed `IndexScan` via `task3_meta_k_idx` — the multi-value index (`FIELDS meta.*.k`) is usable for "does any element's key equal X" queries.
- This shape is closer to a literal "list of key/value pairs" than Strategy A's nested object, and would suit an API where users add named tags/facets rather than a free-form document. It is more verbose to write to (an array append vs. a single object-key set) and every element goes through the same typed `k`/`v` fields — no per-key type flexibility (both are forced to `string` here; you could relax to `TYPE any` at the cost of type safety).

**Strategy C — schemaless side table, one row per (task, key, value).**
```
DEFINE TABLE task_meta SCHEMALESS;
DEFINE FIELD task ON task_meta TYPE record<task2>;
DEFINE FIELD key ON task_meta TYPE string;
DEFINE FIELD value ON task_meta TYPE string;
DEFINE INDEX task_meta_key_value_idx ON task_meta FIELDS key, value;
```
- `CREATE task_meta SET task = task2:x, key = 'priority', value = 'high';` then `SELECT task FROM task_meta WHERE key = 'priority' AND value = 'high';` returned `task2:x`, and `EXPLAIN` showed `IndexScan` on the composite `(key, value)` index.
- This is the classic EAV (entity-attribute-value) pattern. It fully decouples metadata from the task table's own schema (the task table need not have a `meta` field at all), scales to unboundedly many keys per task without widening a single row/object, and gives every key/value pair the same composite index for free. The cost is an extra join-like query (or a `FETCH`) to get from a metadata match back to full task rows, and no natural place to enforce "one value per key" without an additional unique index on `(task, key)`.

**Strategy D — fully `SCHEMALESS` table, no predefined fields at all.**
```
DEFINE TABLE task4 SCHEMALESS;
CREATE task4:z SET title = 'z', anything_goes = true, nested = { a: 1, b: [1,2,3] };
```
- Writes and top-level-field queries work with zero prior `DEFINE FIELD` statements (`SELECT * FROM task4 WHERE anything_goes = true` matched). `EXPLAIN` showed a `TableScan` with `pre_decode_filter`. No `DEFINE FIELD`/`DEFINE INDEX` at all was attempted against a genuinely undeclared top-level field in this note (only object-nested keys were indexed, under Strategy A); indexing a wholly undeclared top-level field on a `SCHEMALESS` table was not tested here and should be checked before relying on it — flagged as a gap, not a negative result.
- `SCHEMALESS` at the whole-table level gives up all of `SCHEMAFULL`'s protection for the task's own core fields (title, status, timestamps) — those should stay governed, so a fully schemaless *task* table is not appropriate; schemaless is more defensible for a purpose-built metadata table (Strategy C) than for the primary `task` table itself.

## Sources

- `FLEXIBLE` field syntax and the "FLEXIBLE must be specified after TYPE" ordering requirement: verified by running (error message quoted above), SurrealDB 3.2.3. Not found stated explicitly in a docs page checked for this note; flagging as a gotcha discovered empirically.
- 2.x→3.x migration notes on schema strictness ("extra fields cause error" for `SCHEMAFULL` tables, non-existing table queries now error rather than returning empty arrays): https://surrealdb.com/docs/build/migrating/from-old-surrealdb-versions/2x-to-3x — checked 2026-09-14, read in docs. Consistent with what we saw when a `CREATE` was attempted against a `SCHEMAFULL` table missing a `title` field definition (`"Found field 'title', but no such field exists for table 'task2'"`).
- Index and `EXPLAIN` behaviour, `CONTAINS` on arrays/multi-value indexes: verified by running only, SurrealDB 3.2.3. Not separately cross-checked against a docs page in this pass — follow-up if D02 needs the formal multi-value-index semantics spelled out (e.g. exact index-selectivity/uniqueness rules) beyond "it works for equality/contains lookups".

## Exact versions used

- SurrealDB: `3.2.3+20260721.40522d1`, installed via Homebrew tap `surrealdb/tap`.
- Run mode: `surreal start --user root --pass root memory`; queries via the HTTP `/sql` endpoint on `127.0.0.1:8000`, namespace `research`.

## Implications for design

1. **Recommend Strategy A (`SCHEMAFULL` task table + a `FLEXIBLE TYPE option<object>` metadata field) as the default for arbitrary user-defined K/V metadata**, because it: keeps the task table's own core fields governed (`SCHEMAFULL`), lets users write any nested key with no migration, is queryable immediately via table scan, and — critically for O2 — lets an operator promote a specific hot key to an index after the fact with `DEFINE INDEX ... FIELDS meta.<key>` and no data migration. This directly satisfies O2's "no migration" requirement for both the write side and the "make it indexable later" side.
2. **Use Strategy C (schemaless `task_meta` side table) only if/when a use case needs cross-task queries by key regardless of which task it lives on at scale** (e.g. "find every task anywhere in the org tagged `customer=acme`") where a single composite `(key, value)` index across all tasks is more valuable than per-key indexes scoped to the `task` table. This can be added later without disturbing Strategy A; the two are not mutually exclusive. Do not adopt it as the default because it adds a join for the common "read a task with its metadata" path.
3. Strategy B (array of `{k,v}` objects) is not recommended as the general metadata mechanism — Strategy A gives the same queryability with a more natural write shape (`SET meta.priority = 'high'` vs. array manipulation) — but keep it in mind for a specifically list-shaped, possibly-repeating-key use case (e.g. multiple labels of the same kind) if that need arises later.
4. Record the exact `FLEXIBLE` field ordering gotcha (`TYPE ... FLEXIBLE`, not `FLEXIBLE TYPE ...`) in D02 or in an implementation note, since it is easy to get wrong from memory or from older examples.
5. Open follow-up, not answered here: indexing a genuinely undeclared top-level field on a `SCHEMALESS` table (relevant only if Strategy D or a schemaless task table is reconsidered later) was not tested. Given Strategy A is the recommendation, this gap is not blocking, but should not be assumed to work the same way without checking.
