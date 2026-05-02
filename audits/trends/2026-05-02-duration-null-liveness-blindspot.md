# Duration Null Liveness Blind Spot Trend Audit

Audit timestamp: 2026-05-02T03:24:12+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for `duration_sec` coverage across historical builder and Sanhedrin iteration rows. It did not inspect live liveness, restart processes, run QEMU or VM commands, run SSH/SCP, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

SQL: `audits/trends/2026-05-02-duration-null-liveness-blindspot.sql`

## Summary

Every row in `iterations` has `duration_sec IS NULL`: 1,505 modernization rows, 1,414 inference rows, and 11,687 Sanhedrin rows. This erases the historical signal needed to enforce the Law 7 "running > 25 minutes = likely hung" rule from `temple-central.db`, especially for the modernization loop where 1,154 QEMU rows and 587 timeout rows have no measured duration.

Findings: 4 warnings.

## Findings

### WARNING-1: Builder duration data is completely absent

Evidence:
- Modernization: 1,505 rows, 1,505 null durations.
- Inference: 1,414 rows, 1,414 null durations.
- All builder rows with validation commands also have null durations.

Impact: historical audit cannot distinguish a fast validation from a long-running validation using the DB alone. This weakens Law 7 liveness backtesting and Law 5 validation-quality scoring.

### WARNING-2: QEMU and timeout evidence has no elapsed-time measurement

Evidence:
- Modernization QEMU rows: 1,154, all with null duration.
- Modernization timeout-signal rows: 587, all with null duration.
- Sample rows include normal `exit 0` validations and timeout/error rows, but both classes have the same null duration field.

Impact: the DB can say a timeout happened, but not whether the run exceeded the 25-minute stuck-process threshold, how often QEMU approached the timeout, or whether timeout containment improved over time.

### WARNING-3: Sanhedrin rows cannot support historical watchdog latency analysis

Evidence:
- Sanhedrin: 11,687 rows, 11,687 null durations.
- Sanhedrin status mix includes 8,850 `pass`, 2,740 `skip`, 94 `fail`, and 3 `blocked`; all have null durations.

Impact: historical analysis cannot show whether audit/cleanup/email-check rows were cheap, saturated, or blocking the watcher loop. That makes process liveness trend analysis depend on timestamps and status text rather than measured execution time.

### WARNING-4: Daily builder coverage shows the null-duration pattern persisted for the full recorded window

Evidence:
- Every recorded builder day from 2026-04-12 through 2026-04-23 has 100% null durations.
- Daily builder rows with commands are also 100% null duration.

Impact: this is not a one-day ingestion bug. It is a schema-population gap across the whole historical window.

## Key Aggregates

| Agent | Rows | Null duration rows | Rows with validation command | Command rows with null duration |
| --- | ---: | ---: | ---: | ---: |
| inference | 1,414 | 1,414 | 1,414 | 1,414 |
| modernization | 1,505 | 1,505 | 1,505 | 1,505 |
| sanhedrin | 11,687 | 11,687 | 0 | 0 |

| Agent | QEMU rows | QEMU rows with null duration | Timeout rows | Timeout rows with null duration | Python rows | Python rows with null duration |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| inference | 0 | 0 | 1 | 1 | 1,413 | 1,413 |
| modernization | 1,154 | 1,154 | 587 | 587 | 1 | 1 |

## Recommendations

- Populate `duration_sec` at insertion time for every builder and Sanhedrin iteration row.
- Add `started_at`, `ended_at`, and `duration_ms` fields or a side table for command-level timing when one iteration runs multiple validations.
- Treat historical `duration_sec IS NULL` rows as unknown duration, not zero duration, in Law 7 scoring.
- Add an audit query that flags QEMU or validation rows whose measured duration exceeds 1,500 seconds.

## Read-Only Verification Command

```bash
sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-02-duration-null-liveness-blindspot.sql
```
