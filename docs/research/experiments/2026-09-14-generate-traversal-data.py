# DISPOSABLE RESEARCH EXPERIMENT. Not product code. Lives only under docs/research/.
# Supports docs/research/2026-09-14-traversal-at-scale.md. Never imported by product code.
#
# Generates synthetic SurrealQL data (a containment tree plus a dependency DAG)
# for benchmarking recursive-traversal query performance at scale.
#
# Usage:
#   python3 2026-09-14-generate-traversal-data.py --n 1000 --seed 1 > data_1000.surql
#
# Tree shape: BFS growth, branching factor uniform in [3, 8] per node, depth capped
# at 10. Stops once N task records have been generated (the last level is truncated).
# Each task record also carries denormalised `parent` and `root` record-link fields
# (for query (b), the denormalised-field comparison).
#
# Dependency DAG: for every non-root task, with probability 0.3 a `depends_on` edge
# is added from that task to a uniformly-chosen task with a strictly earlier creation
# index. Because edges only ever point from a later index to an earlier one, the
# result is guaranteed acyclic (topological order == creation order) with no need to
# check for cycles.
#
# Output: a single .surql script containing schema DEFINE statements, batched
# INSERT INTO task [...] statements, batched INSERT RELATION INTO contains [...]
# statements, and batched INSERT RELATION INTO depends_on [...] statements. Also
# writes, to stderr, the record id of a genuine leaf task (deepest, no children) and
# the observed max depth and dependency-edge count, so the benchmark runner can pick
# a leaf for the dependency-closure query without re-parsing the data file.

import argparse
import random
import sys

BATCH = 500


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, required=True, help="total number of task records")
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--max-depth", type=int, default=10)
    ap.add_argument("--dep-prob", type=float, default=0.3)
    args = ap.parse_args()

    rng = random.Random(args.seed)
    n = args.n

    # node i (0-based) -> (parent_index_or_None, depth, root_index)
    parent = [None] * n
    depth = [0] * n
    children_count = [0] * n

    queue = [0]
    depth[0] = 0
    next_index = 1
    while queue and next_index < n:
        cur = queue.pop(0)
        if depth[cur] >= args.max_depth:
            continue
        k = rng.randint(3, 8)
        for _ in range(k):
            if next_index >= n:
                break
            parent[next_index] = cur
            depth[next_index] = depth[cur] + 1
            children_count[cur] += 1
            queue.append(next_index)
            next_index += 1

    max_depth_seen = max(depth)
    leaf_candidates = [i for i in range(n) if children_count[i] == 0]
    # prefer a deep leaf for a more interesting dependency chain
    leaf_candidates.sort(key=lambda i: -depth[i])
    leaf = leaf_candidates[0] if leaf_candidates else 0

    print(f"-- generated: n={n} seed={args.seed} max_depth_seen={max_depth_seen}")
    print("DEFINE TABLE task SCHEMALESS;")
    print("DEFINE FIELD parent ON task TYPE option<record<task>>;")
    print("DEFINE FIELD root ON task TYPE option<record<task>>;")
    print("DEFINE INDEX task_root_idx ON task FIELDS root;")
    print("DEFINE INDEX task_parent_idx ON task FIELDS parent;")
    print("DEFINE TABLE contains TYPE RELATION FROM task TO task SCHEMAFULL;")
    print("DEFINE TABLE depends_on TYPE RELATION FROM task TO task SCHEMAFULL;")

    def tid(i):
        return f"task:t{i}"

    # task records, batched
    dep_edges = []
    for start in range(0, n, BATCH):
        end = min(start + BATCH, n)
        rows = []
        for i in range(start, end):
            if parent[i] is None:
                rows.append(f'{{id: {tid(i)}}}')
            else:
                rows.append(f'{{id: {tid(i)}, parent: {tid(parent[i])}, root: {tid(0)}}}')
        print("INSERT INTO task [" + ", ".join(rows) + "];")

    # contains edges, batched
    contains_pairs = [(parent[i], i) for i in range(n) if parent[i] is not None]
    for start in range(0, len(contains_pairs), BATCH):
        chunk = contains_pairs[start:start + BATCH]
        rows = [f'{{in: {tid(p)}, out: {tid(c)}}}' for p, c in chunk]
        print("INSERT RELATION INTO contains [" + ", ".join(rows) + "];")

    # depends_on edges: later index depends on an earlier index, guarantees a DAG
    for i in range(1, n):
        if rng.random() < args.dep_prob:
            dep_edges.append((i, rng.randint(0, i - 1)))
    for start in range(0, len(dep_edges), BATCH):
        chunk = dep_edges[start:start + BATCH]
        rows = [f'{{in: {tid(a)}, out: {tid(b)}}}' for a, b in chunk]
        print("INSERT RELATION INTO depends_on [" + ", ".join(rows) + "];")

    sys.stderr.write(f"leaf={tid(leaf)}\n")
    sys.stderr.write(f"max_depth_seen={max_depth_seen}\n")
    sys.stderr.write(f"contains_edges={len(contains_pairs)}\n")
    sys.stderr.write(f"depends_on_edges={len(dep_edges)}\n")


if __name__ == "__main__":
    main()
