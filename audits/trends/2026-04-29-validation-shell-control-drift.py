#!/usr/bin/env python3
"""Read-only shell-control drift scan for temple-central.db validation commands."""

from __future__ import annotations

import collections
import sqlite3

DB = "/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db"


def unquoted_positions(text: str, needle: str) -> list[int]:
    positions: list[int] = []
    single = False
    double = False
    escaped = False
    for index, char in enumerate(text):
        if escaped:
            escaped = False
            continue
        if char == "\\":
            escaped = True
            continue
        if char == "'" and not double:
            single = not single
            continue
        if char == '"' and not single:
            double = not double
            continue
        if char == needle and not single and not double:
            positions.append(index)
    return positions


def main() -> None:
    conn = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
    rows = conn.execute(
        """
        SELECT id, ts, agent, task_id, validation_cmd, validation_result
        FROM iterations
        WHERE agent IN ('modernization', 'inference')
        ORDER BY id
        """
    ).fetchall()

    pipe_rows = []
    semicolon_rows = []
    for row in rows:
        command = row[4] or ""
        pipe_positions = unquoted_positions(command, "|")
        semicolon_positions = unquoted_positions(command, ";")
        if pipe_positions:
            pipe_rows.append((row, pipe_positions))
        if semicolon_positions:
            semicolon_rows.append((row, semicolon_positions))

    print("summary")
    print(f"builder_rows={len(rows)}")
    print(f"unquoted_pipe_rows={len(pipe_rows)}")
    print(
        "pipe_rows_without_pipefail="
        f"{sum('pipefail' not in (row[4] or '').lower() for row, _ in pipe_rows)}"
    )
    print(f"unquoted_semicolon_rows={len(semicolon_rows)}")
    print()

    print("pipe_rows_by_agent")
    for agent, count in sorted(collections.Counter(row[2] for row, _ in pipe_rows).items()):
        print(f"{agent}={count}")
    print()

    print("semicolon_rows_by_agent")
    for agent, count in sorted(collections.Counter(row[2] for row, _ in semicolon_rows).items()):
        print(f"{agent}={count}")
    print()

    print("pipe_rows")
    for row, positions in pipe_rows:
        command = (row[4] or "").replace("\n", "\\n")
        print(f"{row[0]}|{row[1]}|{row[2]}|{row[3]}|{positions}|{command}")
    print()

    print("semicolon_rows")
    for row, positions in semicolon_rows:
        command = (row[4] or "").replace("\n", "\\n")
        print(f"{row[0]}|{row[1]}|{row[2]}|{row[3]}|{positions}|{command}")


if __name__ == "__main__":
    main()
