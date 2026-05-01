# temple-central.db Validation Timeout Containment Drift

Audit timestamp: 2026-05-01T04:01:23+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for whether stored builder validation commands carry explicit timeout or hang-containment evidence. It did not inspect live liveness, restart processes, run QEMU or VM commands, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

SQL: `audits/trends/2026-05-01-validation-timeout-containment-drift.sql`

## Summary

Historical builder validation rows do not expose a consistent timeout contract. Inference records 1,414 validation commands and zero explicit timeout wrappers, including 286 `pytest` command rows. Modernization is better but still mixed: 587 of 1,505 rows mention `timeout`, `TIMEOUT_SEC`, or `gtimeout`, while 918 rows do not. Because every builder row also has `duration_sec = NULL`, the DB cannot reconstruct whether long-running validation was bounded, merely quick in practice, or potentially capable of hiding a Law 7 hang.

Findings: 5 total.

## Findings

### WARNING-1: Inference validation has zero recorded timeout containment

Evidence:
- Inference builder rows: 1,414.
- Inference rows with timeout markers in `validation_cmd`: 0.
- Inference rows with no timeout markers: 1,414.
- Inference rows using `pytest`: 286; all 286 have no timeout marker.

Impact: inference validation may be reliable operationally, but the long-window DB cannot prove each validation command was bounded. That weakens retroactive Law 7 analysis because a blocked Python or pytest command would not be distinguishable from a completed command using only `temple-central.db`.

### WARNING-2: Modernization timeout coverage is partial, not a universal gate

Evidence:
- Modernization builder rows: 1,505.
- Modernization rows with timeout markers: 587 (`39.0%`).
- Modernization rows without timeout markers: 918.
- Modernization rows mentioning QEMU: 1,153; QEMU rows without timeout markers: 566.

Impact: TempleOS validation often touches QEMU-related host automation. Rows that mention QEMU without any recorded timeout marker make historical hang containment and air-gap validation replay depend on unstructured script internals instead of an explicit row-level proof.

### WARNING-3: Timeout coverage improved over time but remained uneven

Evidence:
- Modernization had 0 timeout rows out of 137 on 2026-04-13.
- Modernization later recorded 110 timeout rows out of 246 on 2026-04-22 and 19 out of 34 on 2026-04-23.
- Inference stayed at 0 timeout rows for every recorded day from 2026-04-12 through 2026-04-23.

Impact: this looks like an adoption drift, not a schema-enforced invariant. Future audits should treat timeout containment as absent unless either the command text or a structured column proves it.

### WARNING-4: All builder rows are `pass`, and none record timeout outcomes

Evidence:
- Inference: 1,414 `pass` rows, 0 command timeout markers, 0 timeout mentions in `validation_result` or `error_msg`.
- Modernization: 1,505 `pass` rows, 587 command timeout markers, 0 timeout mentions in `validation_result` or `error_msg`.

Impact: a timeout wrapper that exits nonzero would likely prevent a `pass`, but the historical data has no examples or normalized status vocabulary for bounded failure. Law 7 blocker and hang analyses therefore cannot separate "bounded command completed" from "timeout class not represented in this data window."

### INFO-5: The database can support a narrow backfill query without source writes

Evidence:
- The timeout signal is derivable from existing `validation_cmd` text using a simple marker search for `timeout`, `TIMEOUT_SEC`, and `gtimeout`.
- High-risk command families are also visible by text: QEMU appears in 1,153 modernization rows, while pytest appears in 286 inference rows.
- No TempleOS or holyc-inference source inspection is required for this trend; the issue is the row-level evidence contract.

Impact: a future read-only backfill can score historical validation rows by `bounded`, `unbounded`, and `unknown-script-internal` without mutating the DB. The durable fix would be a normalized field such as `validation_timeout_sec` plus `timed_out BOOLEAN`, not another prose convention inside `validation_cmd`.

## Key Aggregates

| Agent | Rows | Timeout rows | No-timeout rows | Timeout coverage | Null duration rows |
| --- | ---: | ---: | ---: | ---: | ---: |
| inference | 1,414 | 0 | 1,414 | 0.0% | 1,414 |
| modernization | 1,505 | 587 | 918 | 39.0% | 1,505 |

| Agent | QEMU rows | QEMU no-timeout rows | Pytest rows | Pytest no-timeout rows |
| --- | ---: | ---: | ---: | ---: |
| inference | 0 | 0 | 286 | 286 |
| modernization | 1,153 | 566 | 0 | 0 |

## Recommendations

- Add row-level `validation_timeout_sec` and `validation_timed_out` fields for builder inserts.
- Require explicit timeout evidence for QEMU and pytest validation commands in future historical audit scoring.
- Keep script-internal timeout handling visible in DB notes only as secondary evidence; the primary contract should be structured.
- Treat prior no-timeout rows as `unknown boundedness`, not as proof of noncompliance by themselves.

## Read-Only Verification Command

```bash
sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-validation-timeout-containment-drift.sql
```

Finding count: 5 total, 4 warnings and 1 info.
