# temple-central.db Builder Status Taxonomy Collapse Drift

Audit timestamp: 2026-05-01T06:05:24Z

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for whether builder rows preserve meaningful `pass` / `fail` / `blocked` / `skip` status distinctions. It did not inspect live liveness, restart processes, run QEMU or VM commands, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

SQL: `audits/trends/2026-05-01-builder-status-taxonomy-collapse-drift.sql`

## Summary

The builder status field has collapsed to `pass` across the full recorded modernization and inference windows. Modernization has 1,505 rows, all `pass`; inference has 1,414 rows, all `pass`. Sanhedrin rows use the status taxonomy more broadly, so the schema can represent failures, blockers, and skips; the builder insert path is not using that signal.

Findings: 5 total.

## Findings

### WARNING-1: Modernization builder rows never use `fail`, `blocked`, or `skip`

Evidence:
- Modernization rows: 1,505.
- Modernization status distribution: 1,505 `pass`, 0 `fail`, 0 `blocked`, 0 `skip`.
- Window: 2026-04-12T13:51:32 through 2026-04-23T12:01:29.

Impact: historical Law 5 and Law 7 review cannot distinguish clean passes from iterations that made progress but had failed validation, unresolved blockers, or partial execution unless every auditor reparses prose.

### WARNING-2: Inference builder rows also never use `fail`, `blocked`, or `skip`

Evidence:
- Inference rows: 1,414.
- Inference status distribution: 1,414 `pass`, 0 `fail`, 0 `blocked`, 0 `skip`.
- Window: 2026-04-12T13:53:13 through 2026-04-23T12:06:44.

Impact: inference runtime compliance history cannot be scored from the normalized status column. This is especially weak for Law 4 integer-purity and validation regressions, where failed tests should survive as structured data.

### WARNING-3: Modernization `pass` rows contain blocked/skipped/timed-out caveats

Evidence:
- Modernization builder text contains 1 `timed out` row, 5 `blocked` rows, and 172 `skipped` rows.
- All of these rows still have `status='pass'`.
- Inference has 0 rows for those exact caveat terms in this DB window.

Impact: downstream trend audits that trust `status='pass'` will miss historical validation caveats that should be structured as `blocked`, `skip`, or at least a separate validation outcome.

### WARNING-4: Sanhedrin rows prove the status taxonomy is available but inconsistently applied

Evidence:
- Sanhedrin rows include 94 `fail`, 3 `blocked`, 2,740 `skip`, and 8,850 `pass`.
- Builder rows use only `pass`.

Impact: this is not a database schema limitation. It is a producer-contract drift between builder insertion code and Sanhedrin insertion code.

### INFO-5: Auxiliary fields are not enough to recover a structured outcome

Evidence:
- Builder `error_msg` is empty on all modernization and inference rows.
- Builder `duration_sec` is NULL on all modernization and inference rows.
- Builder `validation_result` is populated, but it is free text and mixes green and red outcomes.

Impact: a backfill can approximate historical outcomes by parsing `validation_result` and `notes`, but future rows need normalized fields such as `validation_status`, `north_star_status`, `blocked_reason`, and `duration_sec`.

## Key Aggregates

| Agent | pass | fail | blocked | skip |
| --- | ---: | ---: | ---: | ---: |
| inference | 1,414 | 0 | 0 | 0 |
| modernization | 1,505 | 0 | 0 | 0 |
| sanhedrin | 8,850 | 94 | 3 | 2,740 |

| Agent | Rows | `red` word rows | `timed out` rows | `blocked` rows | `skipped` rows |
| --- | ---: | ---: | ---: | ---: | ---: |
| inference | 1,414 | 0 | 0 | 0 | 0 |
| modernization | 1,505 | 0 | 1 | 5 | 172 |

## Recommendations

- Treat builder `status='pass'` as "iteration committed" rather than "validation passed" for historical analysis.
- Add normalized `validation_status` and `north_star_status` fields to future builder inserts.
- Backfill prior builder rows with a derived status using conservative text rules for `RED`, `fail`, `blocked`, and `timeout`.
- Require future inserts to populate `error_msg` and `duration_sec` when validation fails or times out.

## Read-Only Verification Command

```bash
sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-builder-status-taxonomy-collapse-drift.sql
```

Finding count: 5 total, 4 warnings and 1 info.
