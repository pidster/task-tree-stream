-- DISPOSABLE experiment. Not product code. Lives only under docs/research/.
-- Purpose: compare strategies for arbitrary user-defined K/V metadata that must be
-- queryable and indexable without a schema migration, on SurrealDB 3.2.3.
-- Run statements individually via HTTP /sql (see note in the research doc); the
-- surreal sql REPL aborts the rest of a piped file on the first parse error.

-- ===== Option A: schema-full table + FLEXIBLE object field =====
DEFINE TABLE task2 SCHEMAFULL;
DEFINE FIELD title ON task2 TYPE string;
DEFINE FIELD meta ON task2 TYPE option<object> FLEXIBLE;

CREATE task2:x SET title = 'x', meta = { priority: 'high', customer: 'acme' };
CREATE task2:y SET title = 'y', meta = { region: 'eu' };

-- Query an arbitrary nested key without a predefined field/index
SELECT * FROM task2 WHERE meta.priority = 'high';
SELECT * FROM task2 WHERE meta.region = 'eu';

-- Attempt to index a specific nested key inside the flexible object
DEFINE INDEX task2_meta_priority_idx ON task2 FIELDS meta.priority;
SELECT * FROM task2 WHERE meta.priority = 'high' EXPLAIN;

-- ===== Option B: array<object> k/v pairs with a multi-value index =====
DEFINE TABLE task3 SCHEMAFULL;
DEFINE FIELD title ON task3 TYPE string;
DEFINE FIELD meta ON task3 TYPE array<object>;
DEFINE FIELD meta.*.k ON task3 TYPE string;
DEFINE FIELD meta.*.v ON task3 TYPE string;
DEFINE INDEX task3_meta_k_idx ON task3 FIELDS meta.*.k;
DEFINE INDEX task3_meta_kv_idx ON task3 FIELDS meta.*.k, meta.*.v;

CREATE task3:x SET title = 'x', meta = [{k: 'priority', v: 'high'}, {k: 'customer', v: 'acme'}];
CREATE task3:y SET title = 'y', meta = [{k: 'region', v: 'eu'}];

SELECT * FROM task3 WHERE meta.*.k CONTAINS 'priority';
SELECT * FROM task3 WHERE meta CONTAINS {k: 'priority', v: 'high'};
SELECT * FROM task3 WHERE meta.*.k CONTAINS 'priority' EXPLAIN;

-- ===== Option C: schemaless side table, one row per key/value =====
DEFINE TABLE task_meta SCHEMALESS;
DEFINE FIELD task ON task_meta TYPE record<task2>;
DEFINE FIELD key ON task_meta TYPE string;
DEFINE FIELD value ON task_meta TYPE string;
DEFINE INDEX task_meta_key_value_idx ON task_meta FIELDS key, value;
DEFINE INDEX task_meta_task_idx ON task_meta FIELDS task;

CREATE task_meta SET task = task2:x, key = 'priority', value = 'high';
CREATE task_meta SET task = task2:x, key = 'customer', value = 'acme';
CREATE task_meta SET task = task2:y, key = 'region', value = 'eu';

SELECT task FROM task_meta WHERE key = 'priority' AND value = 'high';
SELECT task FROM task_meta WHERE key = 'priority' AND value = 'high' EXPLAIN;

-- ===== Option D: fully schemaless table, no predefined fields at all =====
DEFINE TABLE task4 SCHEMALESS;
CREATE task4:z SET title = 'z', anything_goes = true, nested = { a: 1, b: [1,2,3] };
SELECT * FROM task4 WHERE anything_goes = true;
SELECT * FROM task4 WHERE anything_goes = true EXPLAIN;
