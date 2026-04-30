# Sanhedrin Status Evidence Null-Field Drift

Audit timestamp: 2026-04-30T12:50:15+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for Sanhedrin iteration rows whose status fields are populated while the structured evidence fields are empty. It did not inspect live liveness, restart processes, run QEMU or VM commands, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

SQL: `audits/trends/2026-04-30-sanhedrin-status-evidence-null-drift.sql`

## Summary

The builder rows in `temple-central.db` keep validation command/result fields populated, but the Sanhedrin stream is status-heavy and evidence-light. All 11,687 Sanhedrin rows have empty `validation_cmd`, empty `validation_result`, empty `error_msg`, and empty `duration_sec`. Notes carry useful prose, but the normalized columns needed for Law 5 progress evidence, Law 7 blocker recurrence, Law 2 QEMU/air-gap proof, and historical CI/liveness trend replay are mostly blank.

Findings: 5 total.

## Findings

### WARNING-1: Sanhedrin rows are entirely missing structured command and result evidence

Evidence:
- Sanhedrin rows: 11,687.
- Rows missing `validation_cmd`: 11,687.
- Rows missing `validation_result`: 11,687.
- Rows missing `duration_sec`: 11,687.
- Rows missing `error_msg`: 11,687.

Impact: the Sanhedrin ledger records that checks passed, failed, skipped, or blocked, but not the exact command, parsed result, elapsed time, or structured error that produced each status. Historical audits must parse prose in `notes`, which is weaker than the normalized schema already used by the builder rows.

### WARNING-2: All non-pass Sanhedrin rows lack structured error messages

Evidence:
- `fail` rows: 94; all 94 have empty `error_msg`.
- `blocked` rows: 3; all 3 have empty `error_msg`.
- Combined non-pass rows missing `error_msg`: 97.

Impact: Law 7 requires recurrence detection for the same error string across consecutive iteration logs. If Sanhedrin non-pass rows keep the error only in `notes`, recurrence queries over `error_msg` will see zero repeat errors even when the note text clearly mentions repeated CI failures, VM compile failures, or blockers.

### WARNING-3: High-risk Sanhedrin task classes are status-only in the structured fields

Evidence:
- `AUDIT`: 2,792 pass rows and 31 fail rows; all missing command, result, and error fields.
- `LAW-CHECK`: 85 pass rows and 3 fail rows; all missing command, result, and error fields.
- `LIVENESS`: 124 pass rows and 1 skip row; all missing command, result, and error fields.
- `VM-COMPILE`: 1,244 pass, 12 skip, 10 fail, and 3 blocked rows; all missing command, result, and error fields.
- CI rows (`CI-CHECK`, `CI-TEMPLEOS`, `CI-INFERENCE`) have 2,129 combined rows; all missing command, result, and error fields.

Impact: these are exactly the task families that later historical analysis wants to replay: law checks, liveness checks, VM/QEMU-adjacent compile evidence, and CI status. Without structured command/result fields, a pass/fail count is available but the reason and proof surface are not.

### WARNING-4: Air-gap and QEMU evidence exists only as prose notes

Evidence:
- Sanhedrin `pass` notes mention QEMU in 116 rows and air-gap markers (`nic none` or `-net none`) in 232 rows.
- Sanhedrin `fail` notes mention QEMU in 2 rows and air-gap markers in 2 rows.
- The corresponding `validation_cmd` and `validation_result` fields are empty for every Sanhedrin row.

Impact: this does not prove an air-gap violation. It shows that Law 2 evidence for Sanhedrin-observed QEMU/VM checks is not queryable as structured command proof. A historical auditor cannot answer "which Sanhedrin VM checks explicitly observed `-nic none`?" without free-text parsing and manual review.

### INFO-5: Notes preserve useful content, but the schema is being used inconsistently

Evidence:
- `notes` is populated on all non-pass rows and all but one pass row.
- `files_changed` is populated for only 74 Sanhedrin rows, almost all `RESEARCH` rows plus two `AUDIT` rows.
- Negative words appear in notes for 4,990 pass rows, 1,980 skip rows, 87 fail rows, and all 3 blocked rows.

Impact: the raw information is often present, but it is not separated into stable fields. Storing exact command, exact result, normalized error class, and duration would let trend reports distinguish "pass with historical warning in notes" from "current failure" without brittle text matching.

## Source Counts

| Metric | Count |
| --- | ---: |
| Sanhedrin rows | 11,687 |
| Missing `validation_cmd` | 11,687 |
| Missing `validation_result` | 11,687 |
| Missing `error_msg` | 11,687 |
| Missing `duration_sec` | 11,687 |
| Missing `files_changed` | 11,613 |
| Non-pass rows missing `error_msg` | 97 |

## Status Breakdown

| Status | Rows | Missing notes | Missing files_changed | Missing duration | First ts | Last ts |
| --- | ---: | ---: | ---: | ---: | --- | --- |
| blocked | 3 | 0 | 3 | 3 | 2026-04-20T02:58:03 | 2026-04-20T17:04:17 |
| fail | 94 | 0 | 93 | 94 | 2026-04-13T07:22:49 | 2026-04-22T23:55:13 |
| pass | 8,850 | 1 | 8,777 | 8,850 | 1776539926 | 2026-04-23T11:54:59 |
| skip | 2,740 | 0 | 2,740 | 2,740 | 1776539926 | 2026-04-23T11:54:25 |

## Recommendations

- Populate `validation_cmd`, `validation_result`, `error_msg`, and `duration_sec` for Sanhedrin checks the same way builder rows do.
- Add a `check_class` or normalized `task_family` column so `AUDIT`, `LAW-CHECK`, `LIVENESS`, `VM-COMPILE`, and CI rows can be trended without parsing `task_id`.
- For VM/QEMU checks, store parsed booleans such as `qemu_seen`, `nic_none_seen`, `net_none_seen`, and `readonly_drive_seen`.
- For Law 7, write the repeatable error signature into `error_msg` even when the full human-readable explanation remains in `notes`.
- Keep `notes` as supplemental prose, not the only evidence surface.

## Read-Only Verification Command

```bash
sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-30-sanhedrin-status-evidence-null-drift.sql
```

Finding count: 5 total, 4 warnings and 1 info.
