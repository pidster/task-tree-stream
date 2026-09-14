-- DISPOSABLE experiment. Not product code. Lives only under docs/research/.
-- Run with: surreal sql --conn http://127.0.0.1:8000 --user root --pass root --ns research --db edges --pretty < this-file
-- Purpose: compare graph edge tables (RELATE) vs in-record links (record-id fields / arrays)
-- for containment (tree), dependency (graph), and user-defined edges. SurrealDB 3.2.3.

-- ===== Setup: schema-full task table with a record link (parent) =====
DEFINE TABLE task SCHEMAFULL;
DEFINE FIELD title ON task TYPE string;
DEFINE FIELD parent ON task TYPE option<record<task>>;
DEFINE FIELD status ON task TYPE string DEFAULT 'todo';
DEFINE INDEX task_parent_idx ON task FIELDS parent;

CREATE task:root SET title = 'Project root', parent = NONE;
CREATE task:a SET title = 'Task A', parent = task:root;
CREATE task:b SET title = 'Task B', parent = task:root;
CREATE task:a1 SET title = 'Task A.1', parent = task:a;
CREATE task:a2 SET title = 'Task A.2', parent = task:a;
CREATE task:a1x SET title = 'Task A.1.x', parent = task:a1;

-- Direct children via record link (reverse lookup by parent field)
SELECT * FROM task WHERE parent = task:a;

-- Ancestor walk UP a record-link chain works with the recursion operator on a plain
-- field idiom (no WHERE-filtered reverse lookup is possible this way):
RETURN task:a1x.{..+collect}(.parent); -- => [task:a1, task:a, task:root]

-- Descending (subtree/children) via a record-link field is NOT supported by the
-- recursion operator: there is no arrow-free way to express "reverse lookup by
-- field, filtered, repeated N times" inside .{..}(...). Both of these fail to parse:
-- RETURN task:a.{..+collect}(<-task WHERE parent = $this);
-- RETURN task:a.{..+collect}((SELECT VALUE id FROM task WHERE parent = $this));
-- Getting a subtree from a record-link parent field therefore requires either
-- one query per depth level from the client, or a stored FUNCTION performing
-- manual recursion.

-- ===== Edge-table approach: RELATE for containment =====
DEFINE TABLE contains TYPE RELATION FROM task TO task SCHEMAFULL;
RELATE task:root->contains->task:a;
RELATE task:root->contains->task:b;
RELATE task:a->contains->task:a1;
RELATE task:a->contains->task:a2;
RELATE task:a1->contains->task:a1x;

-- One-hop children via edge
SELECT ->contains->task AS children FROM task:a;

-- Multi-hop subtree via edge, fixed depth chained arrows (no recursion needed for shallow trees)
SELECT ->contains->task->contains->task AS grandchildren FROM task:root;

-- SurrealDB 3.x recursive graph traversal operator: {depth+algorithm}(path).
-- The recursive path MUST be wrapped in parentheses for the whole graph hop to
-- repeat; `.{..+inclusive}` with no +collect/+path/+shortest algorithm, and no
-- parens, is a parse error ("expected `path`, `collect`, or `shortest`").
-- +collect: deduplicated node list, any order encountered.
RETURN task:root.{..+collect}(->contains->task);            -- => [b, a, a1, a2, a1x]
RETURN task:root.{..+collect+inclusive}(->contains->task);  -- includes task:root itself
-- +path: every distinct root-to-leaf path, as an array of arrays. Using +path
-- with an UNBOUNDED range ({..}) on even a 6-node graph hit the engine's
-- internal recursion limit ("Exceeded the idiom recursion limit of 256") —
-- always bound +path queries with an explicit upper depth, e.g. {1..5+path}.
RETURN task:root.{1..5+path}(->contains->task);

-- ===== Dependency graph: edge with metadata (edge-as-table pattern) =====
DEFINE TABLE depends_on TYPE RELATION FROM task TO task SCHEMAFULL;
DEFINE FIELD kind ON depends_on TYPE string DEFAULT 'blocks';
DEFINE FIELD created_at ON depends_on TYPE datetime DEFAULT time::now();

RELATE task:a2->depends_on->task:a1 SET kind = 'blocks';
RELATE task:b->depends_on->task:a SET kind = 'blocks';

-- Dependency closure: everything that must complete before task:b can start
RETURN task:b.{..+collect}(->depends_on->task);        -- => [task:a]

-- Reverse: everything blocked (directly or transitively) by task:a1
RETURN task:a1.{..+collect}(<-depends_on<-task);        -- => [task:a2]

-- ===== User-defined edges (arbitrary relationship types created by users) =====
DEFINE TABLE related_to TYPE RELATION FROM task TO task SCHEMALESS;
RELATE task:a->related_to->task:b SET note = 'shares a reviewer', weight = 3;
SELECT ->related_to->task, ->related_to.* AS edge_meta FROM task:a;

-- ===== Cost/constraint probe: can we DEFINE INDEX on an edge table field? =====
DEFINE INDEX depends_on_kind_idx ON depends_on FIELDS kind;
SELECT * FROM depends_on WHERE kind = 'blocks';

-- ===== Depth limit probe: does {..} recursion have a default/maximum depth? =====
-- Build a deeper chain to test.
CREATE task:c1 SET title='c1'; CREATE task:c2 SET title='c2'; CREATE task:c3 SET title='c3';
CREATE task:c4 SET title='c4'; CREATE task:c5 SET title='c5'; CREATE task:c6 SET title='c6';
RELATE task:c1->contains->task:c2;
RELATE task:c2->contains->task:c3;
RELATE task:c3->contains->task:c4;
RELATE task:c4->contains->task:c5;
RELATE task:c5->contains->task:c6;
RETURN task:c1.{..+collect}(->contains->task);        -- => [c2, c3, c4, c5, c6], no problem at 5 hops
RETURN task:c1.{1..300+collect}(->contains->task);     -- ERROR: "Found 300 for bound but expected 256 at most."
RETURN task:c1.{1..256+collect}(->contains->task);      -- OK: 256 is the maximum bound accepted
