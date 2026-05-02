#!/usr/bin/env python3
"""Read-only GPT55 audit-log timestamp drift summary."""

from __future__ import annotations

from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
import re
import sqlite3


ROOT = Path(__file__).resolve().parents[2]
LOG = ROOT / "GPT55_AUDIT_LOG.md"
DB = Path("/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db")


def parse_ts(raw: str) -> datetime:
    return datetime.fromisoformat(raw.replace("Z", "+00:00")).astimezone(timezone.utc)


def main() -> None:
    rows = []
    for line_no, line in enumerate(LOG.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip():
            continue
        ts, summary = line.split("|", 1)
        rows.append((line_no, ts.strip(), parse_ts(ts.strip()), summary.strip()))

    regressions = []
    for prev, cur in zip(rows, rows[1:]):
        if cur[2] < prev[2]:
            regressions.append((prev, cur, prev[2] - cur[2]))

    summaries: dict[str, list[tuple[int, str]]] = {}
    for line_no, ts, _dt, summary in rows:
        summaries.setdefault(summary, []).append((line_no, ts))
    duplicate_summaries = {k: v for k, v in summaries.items() if len(v) > 1}

    day_counts = Counter(dt.date().isoformat() for _line_no, _ts, dt, _summary in rows)

    with sqlite3.connect(f"file:{DB}?mode=ro", uri=True) as con:
        db_iterations = con.execute("select count(*) from iterations").fetchone()[0]
        db_sanhedrin = con.execute(
            "select count(*) from iterations where agent='sanhedrin'"
        ).fetchone()[0]
        db_min, db_max = con.execute(
            "select min(ts), max(ts) from iterations"
        ).fetchone()
        db_tz = con.execute(
            "select count(*) from iterations where ts like '%+__:__' or ts like '%Z'"
        ).fetchone()[0]

    print(f"log_lines: {len(rows)}")
    print(f"log_parse_failures: 0")
    print(f"log_z_timestamps: {sum(ts.endswith('Z') for _n, ts, _d, _s in rows)}")
    print(
        "log_offset_timestamps: "
        f"{sum(bool(re.search(r'[+-]\d\d:\d\d$', ts)) and not ts.endswith('Z') for _n, ts, _d, _s in rows)}"
    )
    print(f"adjacent_utc_regressions: {len(regressions)}")
    for prev, cur, delta in regressions:
        print(
            "regression: "
            f"line {prev[0]} {prev[1]} -> line {cur[0]} {cur[1]} "
            f"backs_up={delta}"
        )
    print(f"duplicate_summary_count: {len(duplicate_summaries)}")
    print(f"duplicate_summary_rows: {sum(len(v) for v in duplicate_summaries.values())}")
    print("utc_day_counts:")
    for day, count in sorted(day_counts.items()):
        print(f"  {day}: {count}")
    print(f"central_db_iterations: {db_iterations}")
    print(f"central_db_sanhedrin_iterations: {db_sanhedrin}")
    print(f"central_db_min_ts: {db_min}")
    print(f"central_db_max_ts: {db_max}")
    print(f"central_db_tz_qualified_ts_rows: {db_tz}")


if __name__ == "__main__":
    main()
