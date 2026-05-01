# Sanhedrin Severity/Status Normalization Drift

Audit timestamp: 2026-05-01T10:55:00+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for how Sanhedrin free-text severity labels map to the structured `iterations.status` column. It did not inspect live liveness, restart processes, run QEMU or VM commands, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

SQL: `audits/trends/2026-05-01-sanhedrin-severity-status-drift.sql`

## Summary

Sanhedrin history mixes two outcome systems: free-text `Severity=...` labels in `notes` and the structured `status` column. Across 11,687 Sanhedrin rows, 144 warning-labeled rows are stored as `status = pass`, while 87 non-pass rows are unlabeled by severity. This is not proof that the live auditor made the wrong operational choice; it is evidence that long-window trend queries cannot use `status` alone as a compliance severity proxy.

Findings: 5 total.

## Findings

### WARNING-1: Warning severity is often recorded as structured pass

Evidence:
- Warning-labeled Sanhedrin rows: 146.
- Warning rows with `status = pass`: 144.
- Warning rows with `status = fail`: 2.
- The warning-pass rows span 2026-04-18T07:43:28 through 2026-04-22T22:24:31.

Impact: historical dashboards that count only non-pass rows will miss most warning findings. This undercuts LAWS.md trend analysis for Law 5 and Law 7 because warning conditions can be operationally non-blocking yet still audit-significant.

### WARNING-2: Non-pass rows frequently omit severity labels

Evidence:
- Unlabeled `fail` rows: 84.
- Unlabeled `blocked` rows: 3.
- Unlabeled non-pass rows total: 87.
- Top unlabeled fail classes include `CI-TEMPLEOS` with 43 rows, `AUDIT` with 22 rows, `VM-COMPILE` with 10 rows, `VM-CHECK` with 5 rows, and `LAW-CHECK` with 3 rows.

Impact: fail/blocked status is visible, but the severity tier is absent from a stable field and often absent from notes. A retroactive severity score must reclassify these rows from task family and prose, which is weaker than a normalized `severity` column.

### WARNING-3: Severity drift clusters on 2026-04-22

Evidence:
- 135 warning-pass rows occur on 2026-04-22.
- 6 of the 8 critical-labeled rows also occur on 2026-04-22.
- Earlier unlabeled fail clusters include 42 rows on 2026-04-16 and 9 rows on 2026-04-17.

Impact: this looks like a convention change during the historical window, not a stable schema contract. Long-window trend reports need to split "pre-severity-label" and "post-severity-label" eras instead of treating the whole table as one uniform series.

### WARNING-4: Warning-pass rows mix healthy liveness with warning content

Evidence:
- Of 144 warning-pass rows, 54 include liveness-OK wording such as `loops_alive=OK`, `loops_alive(mod=1`, or `heartbeat_lt10m=OK`.
- 124 mention `Law5`.
- 54 mention `pattern`.

Impact: `status = pass` appears to mean "the audit loop ran and did not require immediate corrective action" for many rows, while `Severity=WARNING` describes the compliance finding. Both are useful, but they are different dimensions and should not share one overloaded status field.

### INFO-5: Critical labels are consistently non-pass in this window

Evidence:
- Critical-labeled rows: 8.
- All 8 critical-labeled rows have `status = fail`.
- No critical-labeled rows have `status = pass`, `skip`, or `blocked`.

Impact: the critical path is the best-normalized part of the dataset. The drift is concentrated in warning and unlabeled non-pass rows, so remediation can preserve the critical mapping while adding explicit fields for `check_outcome` and `finding_severity`.

## Key Counts

| Note severity | Status | Rows |
| --- | --- | ---: |
| critical | fail | 8 |
| warning | pass | 144 |
| warning | fail | 2 |
| pass | pass | 1,005 |
| unlabeled | blocked | 3 |
| unlabeled | fail | 84 |
| unlabeled | pass | 7,701 |
| unlabeled | skip | 2,740 |

## Recommendations

- Add separate normalized fields: `check_outcome` for execution result and `finding_severity` for LAWS.md impact.
- Treat `status = pass` plus `Severity=WARNING` as audit-significant in all historical trend queries.
- Backfill unlabeled non-pass rows with a derived severity only when task family and notes support it; otherwise mark them `severity_unknown`.
- Keep free-text notes as supplemental evidence, not the primary severity carrier.

## Read-Only Verification Command

```bash
sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-sanhedrin-severity-status-drift.sql
```

Finding count: 5 total, 4 warnings and 1 info.
