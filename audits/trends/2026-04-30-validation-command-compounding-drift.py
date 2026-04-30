#!/usr/bin/env python3
"""Read-only identifier compounding scan for validation_cmd paths."""

import os
import re
import sqlite3
from collections import defaultdict

DB_PATH = "/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db"

PATH_RE = re.compile(
    r"(?<![A-Za-z0-9_./-])"
    r"(?:[./A-Za-z0-9_-]+/)?"
    r"([A-Za-z0-9_][A-Za-z0-9_.-]*\.(?:py|sh|HC|HH|md|json|csv|txt|xml|q4_0))"
    r"(?![A-Za-z0-9_./-])"
)


def pieces_for(name):
    stem = name.rsplit(".", 1)[0]
    return [piece for piece in re.split(r"[-_]+", stem) if piece]


def main():
    con = sqlite3.connect(f"file:{DB_PATH}?mode=ro", uri=True)
    rows = con.execute(
        """
        select id, ts, agent, task_id, validation_cmd
        from iterations
        where agent in ('inference', 'modernization')
        """
    ).fetchall()

    aggregate = defaultdict(
        lambda: {
            "rows_with_bad_names": 0,
            "bad_identifiers": 0,
            "over_40_chars": 0,
            "over_5_tokens": 0,
            "max_len": 0,
            "max_tokens": 0,
        }
    )
    samples = []

    for row_id, ts, agent, task_id, cmd in rows:
        bad_names = []
        for match in PATH_RE.finditer(cmd or ""):
            basename = os.path.basename(match.group(1))
            token_count = len(pieces_for(basename))
            name_len = len(basename)
            if name_len > 40 or token_count > 5:
                bad_names.append((basename, name_len, token_count))

        if not bad_names:
            continue

        stats = aggregate[agent]
        stats["rows_with_bad_names"] += 1
        stats["bad_identifiers"] += len(bad_names)
        for basename, name_len, token_count in bad_names:
            stats["over_40_chars"] += int(name_len > 40)
            stats["over_5_tokens"] += int(token_count > 5)
            stats["max_len"] = max(stats["max_len"], name_len)
            stats["max_tokens"] = max(stats["max_tokens"], token_count)

        sample = max(bad_names, key=lambda item: (item[1], item[2]))
        samples.append((sample, row_id, ts, agent, task_id))

    print("agent,rows_with_bad_names,bad_identifiers,over_40_chars,over_5_tokens,max_len,max_tokens")
    for agent in sorted(aggregate):
        stats = aggregate[agent]
        print(
            f"{agent},{stats['rows_with_bad_names']},{stats['bad_identifiers']},"
            f"{stats['over_40_chars']},{stats['over_5_tokens']},"
            f"{stats['max_len']},{stats['max_tokens']}"
        )

    print()
    print("agent,id,ts,task_id,name_len,token_count,basename")
    for (basename, name_len, token_count), row_id, ts, agent, task_id in sorted(
        samples, key=lambda item: (item[0][1], item[0][2]), reverse=True
    )[:15]:
        print(f"{agent},{row_id},{ts},{task_id},{name_len},{token_count},{basename}")


if __name__ == "__main__":
    main()
