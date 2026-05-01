# temple-central.db CI Blocker Dedup Law 7 Drift

Audit timestamp: 2026-05-02T01:12:17+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for Sanhedrin CI rows that repeatedly recorded the same historical CI blocker. It did not inspect live liveness, restart processes, run QEMU or VM commands, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

SQL: `audits/trends/2026-05-02-ci-blocker-dedup-law7-drift.sql`

## Summary

The historical Sanhedrin CI ledger repeatedly re-reported the same TempleOS CI run (`24308638070`) instead of collapsing it into a single known-blocker record with explicit Law 7 escalation state. Across `CI%` task rows, 363 rows mention that same run over 2026-04-12 through 2026-04-17. The row status for that repeated blocker drifted from `skip` to `fail` to `pass`, and all 44 CI rows marked `fail` have empty `error_msg`, `validation_cmd`, and `validation_result` columns.

Findings: 4 total.

## Findings

### WARNING-1: One historical CI run was re-reported 363 times

Evidence:
- `run_24308638070` appears in 363 Sanhedrin `CI%` task rows.
- First recorded: `2026-04-12T19:07:45`.
- Last recorded: `2026-04-17T18:05:48`.
- Daily counts: 17 rows on 2026-04-12, 69 on 2026-04-13, 49 on 2026-04-15, 106 on 2026-04-16, and 122 on 2026-04-17.

Impact: Law 7 says repeated blocker strings across 3+ consecutive iteration logs should escalate rather than silently retry. The DB shows the same old CI run stayed in circulation for days, which weakens trend analysis because repeated historical noise looks like fresh CI risk.

### WARNING-2: Consecutive repeated-run streaks exceed the Law 7 threshold

Evidence:
- Consecutive `run_24308638070` streaks reached 22 rows from `2026-04-13T02:06:40` through `2026-04-13T05:36:13`.
- Other consecutive repeated-run streaks reached 14 rows, 9 rows, 7 rows, and 4 rows.
- The threshold in Law 7 is 3+ consecutive appearances of the same blocker string.

Impact: the repeated-run rows should have been represented as one escalated blocker with suppress/dedupe state. Without that, the audit ledger keeps spending rows on the same known CI artifact instead of distinguishing new failures from already-reviewed failures.

### WARNING-3: CI failure payloads are not mapped consistently to structured status

Evidence:
- Among `CI%` rows whose notes contain `failed` or `failure`, 1,495 rows have `status='pass'`, 200 have `status='skip'`, and 44 have `status='fail'`.
- For run `24308638070`, statuses changed by day: all 17 rows on 2026-04-12 were `skip`; 68 of 69 rows on 2026-04-13 were `skip`; 42 of 106 rows on 2026-04-16 were `fail`; 120 of 122 rows on 2026-04-17 were `pass`.

Impact: some `pass` rows correctly mean "historical failure reviewed and latest CI acceptable," but that meaning is only in free text. A retroactive query cannot safely tell whether a row means active CI health, waived historical failure, or stale blocker recurrence without parsing prose.

### WARNING-4: CI fail rows have no structured error evidence

Evidence:
- CI rows with `status='fail'`: 44.
- Rows among those with empty `error_msg`: 44.
- Rows among those with empty `validation_cmd`: 44.
- Rows among those with empty `validation_result`: 44.

Impact: failed CI rows lack replayable evidence in the structured fields. For historical Law 7 enforcement, the blocker key, source run ID, observed command, and escalation/suppression state should be queryable without scraping `notes`.

## Key Aggregates

| Repeat key | Rows | First TS | Last TS | Fail | Skip | Pass |
| --- | ---: | --- | --- | ---: | ---: | ---: |
| `other_ci` | 1,979 | 2026-04-12T21:14:34 | 2026-04-22T03:18:55 | 0 | 455 | 1,524 |
| `run_24308638070` | 363 | 2026-04-12T19:07:45 | 2026-04-17T18:05:48 | 44 | 158 | 161 |
| `unknown_step` | 5 | 2026-04-13T08:46:37 | 2026-04-13T11:11:23 | 0 | 5 | 0 |

| Day | Rows mentioning `24308638070` | Pass | Skip | Fail |
| --- | ---: | ---: | ---: | ---: |
| 2026-04-12 | 17 | 0 | 17 | 0 |
| 2026-04-13 | 69 | 0 | 68 | 1 |
| 2026-04-15 | 49 | 1 | 48 | 0 |
| 2026-04-16 | 106 | 40 | 24 | 42 |
| 2026-04-17 | 122 | 120 | 1 | 1 |

## Recommendations

- Add a Sanhedrin blocker-dedupe key for CI checks, such as `ci:<repo>:<run_id>:<failure_class>`.
- After 3 consecutive appearances, write one Law 7 escalation row and suppress repeated known-blocker rows until the run ID or failure class changes.
- Split CI status into `latest_ci_status` and `historical_failure_status` rather than overloading `iterations.status`.
- Populate `error_msg`, `validation_cmd`, and `validation_result` for `status='fail'` Sanhedrin CI rows.

## Read-Only Verification Command

```bash
sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-02-ci-blocker-dedup-law7-drift.sql
```

Finding count: 4 warnings.
