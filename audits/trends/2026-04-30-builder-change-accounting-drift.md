# temple-central.db Builder Change-Accounting Drift

Timestamp: 2026-04-30T00:49:39+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for builder iteration change-accounting quality. It did not inspect live loop liveness, run QEMU/VM commands, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code.

SQL: `audits/trends/2026-04-30-builder-change-accounting-drift.sql`

## Summary

The builder iteration ledger is complete enough to prove that both builders reported validation for every historical pass row, but its line-churn fields are not reliable enough for strict Law 5 scoring. Across 2,919 builder rows, 16 pass rows record non-empty `files_changed` and successful validation while reporting `lines_added = 0` and `lines_removed = 0`. Twelve of those zero-churn rows also claim substantive source or harness work in `notes`, so the defect is likely telemetry undercounting rather than harmless task closure.

Findings: 5 total.

## Findings

### WARNING-1: Sixteen successful builder iterations report zero line churn

Evidence:
- Builder rows: 1,505 modernization and 1,414 inference.
- Zero-churn pass rows: 10 modernization and 6 inference.
- Every builder row has non-empty `validation_cmd`, `validation_result`, and `files_changed`, so the zero-churn issue is specific to line accounting.

Impact: trend reports that use `lines_added + lines_removed` to distinguish meaningful work from Law 5 busywork will undercount real work or misclassify pass rows as no-op iterations.

### WARNING-2: Most zero-churn rows claim actual implementation work

Evidence:
- 7 of 10 modernization zero-churn rows contain notes such as `Added`, `Implemented`, `Hardened`, or `Fixed`.
- 5 of 6 inference zero-churn rows contain the same implementation verbs.
- Examples include `CQ-941` claiming TopN tie telemetry hardening and `IQ-978` claiming a parity no-write companion implementation, both with zero recorded churn.

Impact: the ledger cannot distinguish "validated stale task" from "implemented code but failed to record diff size" without re-reading git history or audit reports.

### WARNING-3: Superseded/no-persistent-delta rows are mixed with normal pass rows

Evidence:
- `CQ-1015` has `files_changed = (superseded)`, pass status, and zero churn.
- Its notes say it was superseded by `CQ-1018` within the same session with no persistent source delta.

Impact: a legitimate no-persistent-delta closure is stored with the same `status = pass` shape as implementation rows. Law 5 scoring needs a separate outcome such as `superseded`, `no_delta`, or `closed_stale` instead of overloading pass.

### INFO-4: Large-churn outliers exist but are sparse

Evidence:
- Eight builder rows exceed 1,000 changed lines: 3 modernization and 5 inference.
- The largest modernization row is `CQ-1221/CQ-1222` at 1,327 added lines.
- The largest inference row is `IQ-1252` at 1,137 added lines.

Impact: high-churn rows are rare enough to inspect manually when doing risk-weighted retro audits. They are not the main accounting defect; the main defect is zero-churn pass rows with substantive notes.

### INFO-5: Task-id shape is complete for builder rows

Evidence:
- All 1,505 modernization rows have `CQ-` shaped task ids.
- All 1,414 inference rows have `IQ-` shaped task ids.

Impact: task-id traceability is strong enough for joins by queue family. The weaker fields are churn amount and outcome subtype, not task id presence.

## Source Counts

| Metric | Modernization | Inference |
| --- | ---: | ---: |
| Builder rows | 1,505 | 1,414 |
| Blank validation commands | 0 | 0 |
| Blank validation results | 0 | 0 |
| Blank files_changed | 0 | 0 |
| Zero-churn pass rows | 10 | 6 |
| Zero-churn rows claiming implementation work | 7 | 5 |
| Superseded zero-churn rows | 1 | 0 |
| Rows over 1,000 changed lines | 3 | 5 |

## Recommendations

- Add `change_accounting_status` with values such as `measured`, `unmeasured`, `superseded`, and `closed_stale`.
- Treat zero-churn pass rows with implementation verbs as `unmeasured`, not as Law 5 no-ops.
- Store `git_sha` or diff-stat source alongside each builder iteration so historical audits can verify line counts without reconstructing from task notes.
- Add a Sanhedrin trend guard that warns when a pass row has non-empty changed files, implementation verbs, and zero recorded churn.

## Read-Only Verification Commands

```bash
sqlite3 /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db '.schema iterations'
sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-30-builder-change-accounting-drift.sql
```
