#!/usr/bin/env python3
"""Read-only audit for research table vs filesystem research artifacts."""

from __future__ import annotations

import sqlite3
from collections import Counter
from pathlib import Path


REPO = Path("/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55")
DB = Path("/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db")
RESEARCH_DIR = REPO / "research"


def scalar(cur: sqlite3.Cursor, query: str):
    return cur.execute(query).fetchone()[0]


def main() -> None:
    con = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
    con.row_factory = sqlite3.Row
    cur = con.cursor()

    db_rows = scalar(cur, "SELECT COUNT(*) FROM research")
    db_last = scalar(cur, "SELECT MAX(ts) FROM research")
    db_first = scalar(cur, "SELECT MIN(ts) FROM research")
    db_missing_refs = scalar(
        cur,
        "SELECT COUNT(*) FROM research "
        "WHERE references_urls IS NULL OR TRIM(references_urls) = ''",
    )
    iteration_after_last_research = scalar(
        cur,
        "SELECT COUNT(*) FROM iterations "
        "WHERE ts > (SELECT MAX(ts) FROM research)",
    )
    sanhedrin_after_last_research = scalar(
        cur,
        "SELECT COUNT(*) FROM iterations "
        "WHERE agent = 'sanhedrin' AND ts > (SELECT MAX(ts) FROM research)",
    )
    law_audit_after_last_research = scalar(
        cur,
        "SELECT COUNT(*) FROM iterations "
        "WHERE agent = 'sanhedrin' "
        "AND task_id = 'AUDIT' "
        "AND ts > (SELECT MAX(ts) FROM research) "
        "AND LOWER(COALESCE(notes,'') || ' ' || COALESCE(validation_cmd,'')) LIKE '%law%'",
    )

    files = sorted(RESEARCH_DIR.glob("*.md"))
    file_dates = Counter(path.name[:10] for path in files if path.name[:4].isdigit())
    files_after_db_last_date = [
        path
        for path in files
        if path.name[:10] > db_last[:10]
    ]
    post_law_reform_files = [
        path for path in files if path.name[:10] >= "2026-04-27"
    ]

    print("metric,value")
    print(f"db_research_rows,{db_rows}")
    print(f"db_first_research_ts,{db_first}")
    print(f"db_last_research_ts,{db_last}")
    print(f"db_missing_reference_rows,{db_missing_refs}")
    print(f"filesystem_research_md_files,{len(files)}")
    print(f"filesystem_files_after_db_last_date,{len(files_after_db_last_date)}")
    print(f"filesystem_files_on_or_after_2026_04_27,{len(post_law_reform_files)}")
    print(f"iterations_after_last_research,{iteration_after_last_research}")
    print(f"sanhedrin_iterations_after_last_research,{sanhedrin_after_last_research}")
    print(f"sanhedrin_law_audits_after_last_research,{law_audit_after_last_research}")
    print()

    print("db_research_rows_by_date")
    for row in cur.execute(
        "SELECT DATE(ts) AS day, COUNT(*) AS rows "
        "FROM research GROUP BY DATE(ts) ORDER BY day"
    ):
        print(f"{row['day']},{row['rows']}")
    print()

    print("filesystem_research_files_by_date")
    for day, count in sorted(file_dates.items()):
        print(f"{day},{count}")
    print()

    print("filesystem_research_files_after_db_last_date")
    for path in files_after_db_last_date:
        print(path.relative_to(REPO))


if __name__ == "__main__":
    main()
