# temple-central.db Sanhedrin CLEANUP No-Op Saturation Drift

Audit timestamp: 2026-05-02T02:00:53+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for long-window Sanhedrin `CLEANUP` rows. It did not inspect live liveness, restart processes, run QEMU or VM commands, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

SQL: `audits/trends/2026-05-02-sanhedrin-cleanup-noop-saturation-drift.sql`

## Summary

The historical Sanhedrin ledger records 1,918 `CLEANUP` rows from 2026-04-15 through 2026-04-23, at an average rate of 10.32 rows per hour. At least 1,914 of those rows were observable zero-delete cleanups, while all 1,918 rows were marked `pass` and all lack structured `validation_cmd`, `validation_result`, `duration_sec`, and `error_msg` evidence.

Findings: 5 total.

## Findings

### WARNING-1: CLEANUP no-ops occupy high Sanhedrin volume

Evidence:
- `CLEANUP` rows: 1,918.
- First recorded: `2026-04-15T17:58:39`.
- Last recorded: `2026-04-23T11:54:26`.
- Average rate: 10.32 cleanup rows per hour.
- Daily cleanup share reached 30.2% of all Sanhedrin rows on 2026-04-23, 20.0% on 2026-04-19, and 19.1% on 2026-04-20.

Impact: Law 5 bans busywork. A housekeeping task can be valid, but repeated pass rows for no-op cleanup dominate historical activity metrics and make meaningful audit work harder to distinguish from maintenance churn.

### WARNING-2: The cleanup action almost always deleted nothing

Evidence:
- Classified zero-delete rows: 1,914.
- Nonzero or unparsed count rows: 2.
- Unparsed blank-note rows: 1.
- Test insert rows: 1.
- The two nonzero rows were `count=6` at `2026-04-20T02:34:20` and `count=1` at `2026-04-20T02:52:36`.

Impact: The ledger records nearly every cleanup attempt as successful work even when no artifact changed. For historical Law 5 scoring, these rows should be collapsed, suppressed, or represented as heartbeat metadata rather than full pass iterations.

### WARNING-3: Consecutive zero-delete streaks greatly exceed a reasonable dedupe threshold

Evidence:
- Longest zero-delete streak: 651 consecutive `CLEANUP` rows from `2026-04-17 17:19:07` through `2026-04-20T02:29:50`.
- Other long zero-delete streaks: 553 rows, 524 rows, and 182 rows.

Impact: Repeated no-op housekeeping has the same historical shape as a repeated blocker, but without Law 7-style dedupe or escalation metadata. The ledger should preserve that cleanup was checked, not spend hundreds of rows on identical no-op outcomes.

### WARNING-4: CLEANUP rows have no structured provenance fields

Evidence:
- Rows with empty `validation_cmd`: 1,918 of 1,918.
- Rows with empty `validation_result`: 1,918 of 1,918.
- Rows with null `duration_sec`: 1,918 of 1,918.
- Rows with empty `error_msg`: 1,918 of 1,918.

Impact: The cleanup command, target directory, retention policy, and runtime are only inferable from prose. A future auditor cannot reliably prove whether the cleanup was a dry-run, a deletion command, or an artifact-index operation without out-of-band context.

### INFO-5: CLEANUP note taxonomy drifted across many equivalent strings

Evidence:
- The same zero-delete outcome appears as `Deleted audit markdown files older than 7d count=0.`, `Deleted 0 audit markdown files older than 7 days.`, `Deleted old audit markdown files >7d: 0.`, and `cleanup_old_audit_md_deleted=0`.
- A production ledger row says only `test insert` at `2026-04-21T06:07:58`.

Impact: Equivalent no-op cleanup rows require fragile text parsing. A normalized key such as `cleanup_old_audit_md_deleted` plus numeric `deleted_count` would preserve the signal without proliferating note variants.

## Key Aggregates

| Metric | Count |
| --- | ---: |
| `CLEANUP` rows | 1,918 |
| Classified zero-delete rows | 1,914 |
| Nonzero or unparsed count rows | 2 |
| Unparsed blank-note rows | 1 |
| Test insert rows | 1 |
| Rows missing `validation_cmd` | 1,918 |
| Rows missing `validation_result` | 1,918 |
| Rows missing `duration_sec` | 1,918 |

| Day | Sanhedrin Rows | CLEANUP Rows | Zero-Delete Rows | CLEANUP % |
| --- | ---: | ---: | ---: | ---: |
| 2026-04-15 | 273 | 29 | 29 | 10.6 |
| 2026-04-16 | 646 | 104 | 104 | 16.1 |
| 2026-04-17 | 1,329 | 207 | 206 | 15.6 |
| 2026-04-18 | 1,275 | 203 | 203 | 15.9 |
| 2026-04-19 | 1,231 | 246 | 246 | 20.0 |
| 2026-04-20 | 2,341 | 448 | 446 | 19.1 |
| 2026-04-21 | 2,734 | 478 | 477 | 17.5 |
| 2026-04-22 | 1,222 | 111 | 111 | 9.1 |
| 2026-04-23 | 305 | 92 | 92 | 30.2 |

| Zero-Delete Streak | First TS | Last TS |
| ---: | --- | --- |
| 651 | 2026-04-17 17:19:07 | 2026-04-20T02:29:50 |
| 553 | 2026-04-21T06:11:57 | 2026-04-23T11:54:26 |
| 524 | 2026-04-20T02:52:47 | 2026-04-21T06:05:52 |
| 182 | 2026-04-15T17:58:39 | 2026-04-17T04:44:57 |

## Recommendations

- Convert repeated zero-delete cleanup checks into one daily aggregate row or a metric field on the surrounding audit row.
- Record `cleanup_deleted_count` as a structured integer instead of encoding it in prose.
- Populate `validation_cmd`, `validation_result`, and `duration_sec` for cleanup rows that remain first-class iterations.
- Remove test/probe inserts from production trend ledgers or mark them with a dedicated `status='skip'` and test flag.

## Read-Only Verification Command

```bash
sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-02-sanhedrin-cleanup-noop-saturation-drift.sql
```

Finding count: 5 total, 4 warnings and 1 info.
