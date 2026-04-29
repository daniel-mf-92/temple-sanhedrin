#!/usr/bin/env python3
"""Exact commit-SHA evidence scan for temple-central iteration rows."""

import re
import sqlite3
from collections import defaultdict

DB = "/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db"

sha40 = re.compile(r"(?<![0-9a-f])[0-9a-f]{40}(?![0-9a-f])", re.IGNORECASE)
sha7 = re.compile(r"(?<![0-9a-f])[0-9a-f]{7,12}(?![0-9a-f])", re.IGNORECASE)

conn = sqlite3.connect(DB)
rows = conn.execute(
    """
    SELECT agent, ts, task_id, files_changed, validation_cmd, validation_result, notes
    FROM iterations
    WHERE agent IN ('modernization', 'inference')
    ORDER BY ts
    """
).fetchall()

counts = defaultdict(lambda: {"rows": 0, "sha40": 0, "sha7_12": 0})
examples = []

for agent, ts, task_id, *fields in rows:
    text = " ".join(field or "" for field in fields)
    counts[agent]["rows"] += 1
    if sha40.search(text):
        counts[agent]["sha40"] += 1
    short = sha7.search(text)
    if short:
        counts[agent]["sha7_12"] += 1
        if len(examples) < 12:
            examples.append((agent, ts, task_id, short.group(0), text[:140]))

print("agent rows exact_40_hex_sha loose_7_12_hex_token")
for agent in sorted(counts):
    c = counts[agent]
    print(f"{agent} {c['rows']} {c['sha40']} {c['sha7_12']}")

print()
print("loose_7_12_hex_examples")
for agent, ts, task_id, token, snippet in examples:
    print(f"{agent} | {ts} | {task_id} | {token} | {snippet}")
