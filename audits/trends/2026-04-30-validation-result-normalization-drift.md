# temple-central.db Validation Result Normalization Drift Audit

Audit timestamp: 2026-04-30T03:46:05+02:00

Audit angle: historical drift trends. This pass queried `temple-central.db` read-only for long-window agreement between `status`, `validation_cmd`, `validation_result`, and `error_msg`.

## Scope

- Database: `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`
- Table: `iterations`
- Rows: 14,606
- Window reported by raw `MIN(ts)`/`MAX(ts)`: `1776539926` through `2026-04-23T12:06:44`
- Query pack: `audits/trends/2026-04-30-validation-result-normalization-drift.sql`
- LAWS.md focus: Law 5 meaningful evidence, Law 7 blocker escalation, and Sanhedrin auditability.

No TempleOS or holyc-inference source files were modified. No QEMU or VM command was executed.

## Summary

Builder rows have complete validation command/result fields, but Sanhedrin rows do not: all 11,687 Sanhedrin iteration rows have empty `validation_cmd` and `validation_result`. The same gap includes 97 Sanhedrin `fail`/`blocked` rows with no `error_msg`, so historical Law 7 blocker escalation cannot reconstruct why those non-pass states happened from the central DB alone.

## Findings

1. **WARNING - Sanhedrin validation evidence is absent in 11,687 / 11,687 rows.**
   Evidence: Sanhedrin has 8,850 pass rows, 2,740 skip rows, 94 fail rows, and 3 blocked rows; every one has blank `validation_cmd` and blank `validation_result`. This leaves the DB unable to distinguish a substantive audit pass from a bookkeeping pass without external audit markdown.

2. **WARNING - Sanhedrin non-pass rows lack error causes in 97 / 97 cases.**
   Evidence: all 94 Sanhedrin `fail` rows and all 3 `blocked` rows have empty `error_msg`. Law 7 requires repeated blocker escalation by error string, but these rows provide no string to group.

3. **WARNING - Result classes are not normalized across agents.**
   Evidence: inference has 994 `coarse_success` rows, 389 `specific_success` rows, and 1 `success_with_skip` row; modernization has 1,391 `coarse_success`, 109 `success_with_skip`, and 1 `specific_success` row; Sanhedrin has only `missing` result classes. Long-window reporting must branch by agent instead of aggregating one consistent validation schema.

4. **INFO - Three modernization pass rows contain negative tokens that are successful remote validations, not actual failures.**
   Evidence: CQ-584, CQ-656, and CQ-699 have `status = pass` and results containing `no compile errors`; each also records a local ISO skip and a remote QEMU compile pass. This is not a violation, but it shows that naive `fail/error` keyword searches produce false positives unless result causes are structured.

5. **INFO - Fourteen iteration timestamps are not ISO `YYYY-MM-DDTHH:MM:SS` values.**
   Evidence: six rows use a space separator on 2026-04-17, five rows use a space separator on 2026-04-19, and three rows use the raw numeric value `1776539926`. This is not the primary audit target, but it makes raw `MIN(ts)`/`MAX(ts)` misleading and should be normalized before trend dashboards consume the table.

## Key Aggregates

| Agent | Rows | Missing cmd | Missing result | Non-pass without error | Pass with negative token |
| --- | ---: | ---: | ---: | ---: | ---: |
| inference | 1,414 | 0 | 0 | 0 | 0 |
| modernization | 1,505 | 0 | 0 | 0 | 3 |
| sanhedrin | 11,687 | 11,687 | 11,687 | 97 | 0 |

## Result Classes

| Agent | Status | Result class | Rows |
| --- | --- | --- | ---: |
| inference | pass | coarse_success | 994 |
| inference | pass | specific_success | 389 |
| inference | pass | other | 30 |
| inference | pass | success_with_skip | 1 |
| modernization | pass | coarse_success | 1,391 |
| modernization | pass | success_with_skip | 109 |
| modernization | pass | other | 4 |
| modernization | pass | specific_success | 1 |
| sanhedrin | blocked | missing | 3 |
| sanhedrin | fail | missing | 94 |
| sanhedrin | pass | missing | 8,850 |
| sanhedrin | skip | missing | 2,740 |

## Recommendations

- Populate Sanhedrin `validation_cmd`, `validation_result`, and `error_msg` on every iteration insert, even when the canonical artifact remains the markdown report.
- Add typed fields such as `result_class`, `validation_scope`, `failure_cause`, and `skip_cause`; keep prose as supplemental evidence.
- For Law 7, require non-empty `error_msg` whenever `status IN ('fail', 'blocked')`.
- Normalize timestamps at insert time to one ISO format before dashboards or backfills compute time windows.

Finding count: 5 total, 3 warnings and 2 info.
