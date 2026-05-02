# Pending Central-DB Replay Drift

Audit timestamp: 2026-05-02T04:18:45+02:00

Audit angle: historical drift trends. This pass inspected Sanhedrin `audit/pending-central-db-insert-*.sql` replay artifacts and queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only. It did not inspect live liveness, restart processes, run QEMU or VM commands, execute WS8 networking tasks, modify TempleOS or holyc-inference source code, or write to the central database. The TempleOS guest air-gap was not touched.

Script: `audits/trends/2026-05-02-pending-db-replay-drift.py`

## Summary

The pending central-DB replay backlog is not just delayed telemetry. It has schema drift that prevents direct replay: 266 pending SQL files contain 274 `iterations.status` values of `warning` or `critical`, but the `iterations` table CHECK only permits `pass`, `fail`, `skip`, or `blocked`. The backlog also contains 719 raw iteration insert statements across 393 files while the live `violations` table remains empty, so replay needs normalization before it can safely backfill historical Law evidence.

Findings: 5 total.

## Findings

### CRITICAL-1: Direct replay would hit the `iterations.status` CHECK constraint

Evidence:
- Pending SQL files: 393.
- Raw pending iteration inserts: 719.
- Parsed pending iteration rows with explicit status: 710.
- Invalid pending status inserts: 274.
- Files containing invalid statuses: 266.
- Invalid statuses found: `warning` 266 times and `critical` 8 times.
- Current DB schema allows only `pass`, `fail`, `skip`, and `blocked`.

Impact: a naive `sqlite3 temple-central.db < audit/pending-central-db-insert-*.sql` backfill would fail or partially apply unless it maps audit severity to a separate field. `warning` and `critical` are compliance severity, not process status.

### WARNING-2: The replay backlog is larger than the live structured violation ledger

Evidence:
- Pending files contain 719 raw `INSERT INTO iterations` statements.
- 710 of those statements matched the status parser used for this audit.
- Pending files contain 1 `INSERT INTO violations` statement.
- The live DB has 14,606 `iterations` rows and 0 `violations` rows.
- Pending notes contain `Severity=CRITICAL` 42 times and `Severity=WARNING` 234 times.

Impact: the pending artifacts preserve severity signals that never reached the normalized violation sink. Historical compliance reports that query only the live DB still see zero structured violations.

### WARNING-3: One pending file can carry multiple rows, so file count is not event count

Evidence:
- 156 pending SQL files contain more than one iteration insert.
- The largest observed file contains 5 iteration inserts.
- 393 files expand to 719 raw iteration insert statements.

Impact: backlog aging and replay dashboards that count files understate event volume by 326 rows. A replay tool must parse statements, not assume one file equals one audit event.

### WARNING-4: Filename timestamp formats are not canonical

Evidence:
- `compact_offset`: 283 files.
- `compact_cest`: 94 files.
- `colon_time_offset`: 9 files.
- `colon_time_colon_offset`: 1 file.
- `dash_compact`: 1 file.
- `minute_precision_offset`: 1 file.
- `manual`: 1 file.
- `other`: 3 files.

Impact: replay ordering based on filename parsing needs a tolerant normalizer. The backlog includes `CEST`, `+0200`, `+02:00`, colon-bearing times, minute-only precision, a dash-only timestamp, and a manual file.

### INFO-5: The backlog confirms the air-gap was preserved during blocked central-DB writes

Evidence:
- All 393 pending files mention blocked or readonly DB/write conditions.
- Pending notes contain `ci_check_blocked_no_network` 333 times and `vm_check_blocked` 151 times.
- The inspected artifacts record blocked network/SSH checks rather than executing WS8 networking or VM networking work.

Impact: this is an audit-ingestion drift, not evidence of a guest networking breach. Backfill should preserve the blocked/no-network fields instead of treating missing DB rows as missing audit execution.

## Key Aggregates

| Metric | Count |
| --- | ---: |
| Pending SQL files | 393 |
| Raw pending iteration inserts | 719 |
| Parsed pending iteration status rows | 710 |
| Raw pending violation inserts | 1 |
| Parsed pending violation severity rows | 1 |
| Live DB iteration rows | 14,606 |
| Live DB violation rows | 0 |
| Files with invalid pending status | 266 |
| Invalid pending status inserts | 274 |
| Multi-insert pending files | 156 |
| Max inserts in one pending file | 5 |

| Pending `iterations.status` | Count | Schema status |
| --- | ---: | --- |
| `blocked` | 5 | valid |
| `critical` | 8 | invalid |
| `fail` | 34 | valid |
| `pass` | 219 | valid |
| `skip` | 178 | valid |
| `warning` | 266 | invalid |

| Filename Date | Files |
| --- | ---: |
| 2026-04-24 | 23 |
| 2026-04-25 | 163 |
| 2026-04-26 | 182 |
| 2026-04-27 | 24 |
| none | 1 |

## Recommendations

- Before replay, transform pending rows with `status in ('warning','critical')` to a valid process status plus a separate `severity` value.
- Insert one `violations` row per CRITICAL/WARNING finding instead of storing severity only in `iterations.notes`.
- Replay pending files statement-by-statement with a manifest of source path, statement hash, normalized timestamp, and applied/skipped/error result.
- Treat filename timestamps as weak ordering hints; derive canonical replay time from parsed note timestamps or statement metadata when present.

## Read-Only Verification Command

```bash
python3 audits/trends/2026-05-02-pending-db-replay-drift.py
```

Finding count: 5 total, 1 critical, 3 warnings, and 1 info.
