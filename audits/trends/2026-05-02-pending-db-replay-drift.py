#!/usr/bin/env python3
"""Summarize Sanhedrin pending central-DB replay backlog drift."""

from collections import Counter
from pathlib import Path
import re
import sqlite3


ROOT = Path(__file__).resolve().parents[2]
DB_PATH = Path("/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db")
VALID_ITERATION_STATUS = {"pass", "fail", "skip", "blocked"}


def status_shape(name: str) -> str:
    stamp = name.removeprefix("pending-central-db-insert-").removesuffix(".sql")
    shapes = [
        (r"\d{4}-\d{2}-\d{2}T\d{6}\+\d{4}", "compact_offset"),
        (r"\d{4}-\d{2}-\d{2}T\d{6}CEST", "compact_cest"),
        (r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\+\d{4}", "colon_time_offset"),
        (r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\+\d{2}:\d{2}", "colon_time_colon_offset"),
        (r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}\+\d{4}", "minute_precision_offset"),
        (r"\d{4}-\d{2}-\d{2}-\d{6}", "dash_compact"),
    ]
    if stamp == "manual":
        return "manual"
    for pattern, shape in shapes:
        if re.fullmatch(pattern, stamp):
            return shape
    return "other"


def main() -> None:
    files = sorted((ROOT / "audit").glob("pending-central-db-insert-*.sql"))
    text_by_file = [(path, path.read_text(errors="ignore")) for path in files]

    iteration_status = Counter()
    invalid_files = 0
    invalid_inserts = 0
    multi_insert_files = 0
    max_inserts = 0
    violation_severity = Counter()
    date_counts = Counter()
    shape_counts = Counter()
    signal_counts = Counter()
    raw_iteration_inserts = 0
    raw_violation_inserts = 0

    for path, text in text_by_file:
        raw_iteration_inserts += text.count("INSERT INTO iterations")
        raw_violation_inserts += text.count("INSERT INTO violations")
        statuses = re.findall(
            r"INSERT INTO iterations \(agent,task_id,status,notes\) VALUES \(\s*'[^']+',\s*'[^']+',\s*'([^']+)'",
            text,
            re.S,
        )
        iteration_status.update(statuses)
        invalid = [status for status in statuses if status not in VALID_ITERATION_STATUS]
        invalid_files += bool(invalid)
        invalid_inserts += len(invalid)
        multi_insert_files += len(statuses) > 1
        max_inserts = max(max_inserts, len(statuses))
        violation_severity.update(
            re.findall(
                r"INSERT INTO violations \(law_id,agent,severity,evidence,resolved\) VALUES \(\s*\d+,\s*'[^']+',\s*'([^']+)'",
                text,
                re.S,
            )
        )
        day_match = re.search(r"(\d{4}-\d{2}-\d{2})", path.name)
        date_counts[day_match.group(1) if day_match else "none"] += 1
        shape_counts[status_shape(path.name)] += 1
        lower = text.lower()
        for signal in (
            "Severity=CRITICAL",
            "Severity=WARNING",
            "central_db_write=blocked_readonly",
            "ci_check_blocked_no_network",
            "vm_check_blocked",
        ):
            signal_counts[signal] += text.count(signal)
        signal_counts["blocked_or_readonly_files"] += "blocked" in lower or "readonly" in lower

    with sqlite3.connect(f"file:{DB_PATH}?mode=ro", uri=True) as con:
        db_iterations = con.execute("SELECT count(*) FROM iterations").fetchone()[0]
        db_violations = con.execute("SELECT count(*) FROM violations").fetchone()[0]

    print("== backlog totals ==")
    print(f"pending_files|{len(files)}")
    print(f"raw_pending_iteration_inserts|{raw_iteration_inserts}")
    print(f"parsed_pending_iteration_status_rows|{sum(iteration_status.values())}")
    print(f"raw_pending_violation_inserts|{raw_violation_inserts}")
    print(f"parsed_pending_violation_severity_rows|{sum(violation_severity.values())}")
    print(f"db_iterations|{db_iterations}")
    print(f"db_violations|{db_violations}")
    print(f"invalid_status_files|{invalid_files}")
    print(f"invalid_status_inserts|{invalid_inserts}")
    print(f"multi_insert_files|{multi_insert_files}")
    print(f"max_iteration_inserts_per_file|{max_inserts}")

    print("\n== pending iteration status ==")
    for key, value in sorted(iteration_status.items()):
        marker = "invalid" if key not in VALID_ITERATION_STATUS else "valid"
        print(f"{key}|{value}|{marker}")

    print("\n== pending violation severity ==")
    for key, value in sorted(violation_severity.items()):
        print(f"{key}|{value}")

    print("\n== filename date counts ==")
    for key, value in sorted(date_counts.items()):
        print(f"{key}|{value}")

    print("\n== filename timestamp shapes ==")
    for key, value in sorted(shape_counts.items()):
        print(f"{key}|{value}")

    print("\n== signal counts ==")
    for key, value in sorted(signal_counts.items()):
        print(f"{key}|{value}")


if __name__ == "__main__":
    main()
