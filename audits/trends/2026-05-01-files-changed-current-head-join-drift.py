#!/usr/bin/env python3
"""Check whether temple-central files_changed paths still resolve at current heads."""

import collections
import os
import re
import sqlite3


DB = "/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db"
ROOTS = {
    "modernization": "/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS",
    "inference": "/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference",
}
CORE_PREFIX = re.compile(r"^(Kernel|Adam|Apps|Compiler|0000Boot|src)/")


def split_files(value):
    parts = []
    for raw in re.split(r"[,;\n]+", value or ""):
        part = re.sub(r"^[-*]\s*", "", raw.strip())
        if part:
            parts.append(part)
    return parts


def is_path_token(part):
    if part in {"(none)", "(superseded)", "-"}:
        return False
    if part.isdigit():
        return False
    return "/" in part or "." in os.path.basename(part)


def main():
    conn = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
    rows = conn.execute(
        """
        SELECT id, ts, agent, task_id, status, files_changed
        FROM iterations
        WHERE agent IN ('modernization','inference')
          AND files_changed IS NOT NULL
          AND trim(files_changed) <> ''
        ORDER BY id
        """
    ).fetchall()

    stats = collections.defaultdict(collections.Counter)
    missing_paths = collections.defaultdict(collections.Counter)
    invalid_examples = []
    missing_examples = []
    core_examples = []

    for row_id, ts, agent, task_id, status, files_changed in rows:
        raw_parts = split_files(files_changed)
        path_parts = [part for part in raw_parts if is_path_token(part)]
        invalid_parts = [part for part in raw_parts if not is_path_token(part)]

        stats[agent]["rows"] += 1
        stats[agent]["raw_tokens"] += len(raw_parts)
        stats[agent]["valid_paths"] += len(path_parts)
        stats[agent]["invalid_tokens"] += len(invalid_parts)
        if invalid_parts:
            stats[agent]["rows_with_invalid"] += 1
            if len(invalid_examples) < 8:
                invalid_examples.append((row_id, ts, agent, task_id, files_changed, invalid_parts))
        if not path_parts:
            stats[agent]["rows_without_valid_path"] += 1

        row_missing = []
        row_core_missing = []
        for path in path_parts:
            if os.path.exists(os.path.join(ROOTS[agent], path)):
                stats[agent]["current_head_present_paths"] += 1
                continue
            stats[agent]["current_head_missing_paths"] += 1
            row_missing.append(path)
            missing_paths[agent][path] += 1
            if CORE_PREFIX.match(path):
                row_core_missing.append(path)

        if row_missing:
            stats[agent]["rows_with_current_missing"] += 1
            if len(missing_examples) < 10:
                missing_examples.append((row_id, ts, agent, task_id, row_missing[:5]))
        if row_core_missing:
            stats[agent]["rows_with_core_current_missing"] += 1
            if len(core_examples) < 10:
                core_examples.append((row_id, ts, agent, task_id, row_core_missing[:5]))

    print("SUMMARY")
    for agent in sorted(stats):
        print(agent, dict(stats[agent]))

    print("\nTOP_MISSING")
    for agent in sorted(missing_paths):
        print(agent)
        for path, count in missing_paths[agent].most_common(15):
            print(count, path)

    print("\nINVALID_EXAMPLES")
    for item in invalid_examples:
        print(item)

    print("\nMISSING_EXAMPLES")
    for item in missing_examples:
        print(item)

    print("\nCORE_MISSING_EXAMPLES")
    for item in core_examples:
        print(item)


if __name__ == "__main__":
    main()
