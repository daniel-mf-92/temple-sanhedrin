# temple-central.db Builder Line-Delta Accounting Drift

Timestamp: 2026-04-30T12:00:46+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for builder rows whose structured line counters disagree with the changed-file and notes evidence. It did not inspect live liveness, run QEMU/VM commands, execute WS8 networking work, or modify TempleOS / holyc-inference source code.

SQL: `audits/trends/2026-04-30-builder-line-delta-accounting-drift.sql`

## Summary

The builder `iterations` ledger has complete nonblank `files_changed`, `validation_cmd`, and `validation_result` fields, but its line-delta counters are not always reliable evidence of work size. Sixteen builder rows record `lines_added = 0` and `lines_removed = 0` while naming changed files; fourteen of those rows also use notes that claim concrete implementation, hardening, fixing, removal, or deduplication. The issue is small as a percentage of 2,919 builder rows, but it directly affects Law 5 trend scoring because zero-delta rows can still represent core HolyC or test work.

Findings: 5 total.

## Findings

### WARNING-1: Sixteen builder rows have zero structured line delta despite changed-file evidence

Evidence:
- Modernization: 10 of 1,505 rows have `lines_added + lines_removed = 0`.
- Inference: 6 of 1,414 rows have `lines_added + lines_removed = 0`.
- Every affected row still has nonblank `files_changed`, `validation_cmd`, and `validation_result`.

Impact: a historical Law 5 report that treats zero line delta as no substantive change will misclassify some builder iterations.

### WARNING-2: Zero-delta rows include core HolyC paths

Evidence:
- Modernization zero-delta rows that mention `.HC`: 4.
- Inference zero-delta rows that mention `.HC`: 5.
- Examples include `Kernel/BookOfTruth.HC`, `Kernel/KExts.HC`, `src/model/attention.HC`, `src/math/fixedpoint.HC`, and `src/tokenizer/bpe.HC`.

Impact: line counters cannot be used alone to determine whether the builder touched core law-sensitive surfaces such as Book of Truth code or integer-runtime code.

### WARNING-3: Most zero-delta rows claim concrete implementation work in notes

Evidence:
- Modernization zero-delta rows with change verbs in notes: 9 of 10.
- Inference zero-delta rows with change verbs in notes: 5 of 6.
- The only explicit modernization no-source-delta case is `CQ-1015`, where `files_changed` is `(superseded)`.

Impact: the drift is not just stale queue closure. The DB stores prose that says work happened while the structured counters say no lines changed.

### WARNING-4: Small-delta and huge-delta buckets need explicit classification

Evidence:
- Rows with 1-3 changed lines: 46 modernization and 46 inference.
- Rows with delta >= 1,000 lines: 3 modernization and 5 inference.
- Maximum line deltas are 1,327 for modernization and 1,137 for inference.

Impact: long-window reports need typed work classes such as queue-only, source-change, generated artifact, harness-only, and superseded. Raw line totals alone cannot distinguish meaningful small edits from bookkeeping, nor large generated additions from hand-authored implementation.

### INFO-5: The drift is concentrated in the later historical window and is backfillable

Evidence:
- Inference zero-delta rows occur on 2026-04-19 through 2026-04-21.
- Modernization zero-delta rows occur on 2026-04-13 and 2026-04-20 through 2026-04-22.
- Only 16 rows require direct counter reconciliation.

Impact: a conservative backfill can recompute line deltas from the referenced git commits or mark these rows with `line_delta_unknown` without rewriting the whole historical ledger.

## Source Counts

| Metric | Modernization | Inference |
| --- | ---: | ---: |
| Builder rows | 1,505 | 1,414 |
| Zero-delta rows | 10 | 6 |
| Zero-delta multi-file rows | 5 | 5 |
| Zero-delta `.HC` rows | 4 | 5 |
| Zero-delta `MASTER_TASKS.md` rows | 3 | 6 |
| Zero-delta rows with change-claim notes | 9 | 5 |
| Rows with 1-3 changed lines | 46 | 46 |
| Rows with delta >= 1,000 | 3 | 5 |
| Max line delta | 1,327 | 1,137 |

## Recommendations

- Add a `line_delta_source` field with values such as `git_diff`, `manual`, `unknown`, and `superseded`.
- Add a report guard for rows where `line_delta = 0` and `files_changed` names source/test files.
- Backfill the 16 affected rows from commit diffs where commit identity is available; otherwise mark them as `line_delta_unknown`.
- Treat line counters as advisory until reconciled with commit SHAs or an `iteration_artifacts` table.

## Read-Only Verification Commands

```bash
sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-30-builder-line-delta-accounting-drift.sql
sqlite3 -readonly /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db '.schema iterations'
```
