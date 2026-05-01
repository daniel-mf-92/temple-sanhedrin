# temple-central.db North-Star Justification Evidence Drift

Audit timestamp: 2026-05-01T05:23:00+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for whether stored builder iteration rows carry explicit Law 5 North Star justification or `north-star-e2e` execution evidence. It did not inspect live liveness, restart processes, run QEMU or VM commands, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

SQL: `audits/trends/2026-05-01-north-star-justification-evidence-drift.sql`

## Summary

The historical builder ledger has no row-level North Star justification evidence. Across 2,919 modernization and inference rows, zero rows mention `north star` / `north_star`, and zero validation commands record a `north-star-e2e` invocation. This is not proof that every iteration was off-path, because many notes describe domain work. It is evidence that `temple-central.db` cannot retroactively verify the appended Law 5 requirement that each iteration justify how its commit advances `NORTH_STAR.md`.

Findings: 5 total.

## Findings

### WARNING-1: No builder row records explicit North Star justification

Evidence:
- Modernization rows: 1,505; North Star mention rows: 0.
- Inference rows: 1,414; North Star mention rows: 0.
- Daily coverage remained 0 rows for every recorded builder day from 2026-04-12 through 2026-04-23.

Impact: historical audits cannot distinguish a commit that intentionally advanced `NORTH_STAR.md` from a commit that only advanced a nearby queue item. For appended Law 5, the DB stores useful prose but not the required justification target.

### WARNING-2: No validation command records the North Star gate

Evidence:
- Modernization `north-star-e2e` validation command rows: 0.
- Inference `north-star-e2e` validation command rows: 0.
- All builder statuses in this DB window are `pass`, so there are no structured RED/PASS North Star outcomes to compare.

Impact: a validation row can be green without proving whether the north-star gate ran, failed red with an accepted explanation, or was intentionally skipped. That weakens long-window Law 5 scoring.

### WARNING-3: Notes contain domain and queue prose, but not the governing objective

Evidence:
- Inference rows mentioning queue in notes: 740; rows mentioning domain terms such as `secure`, `gpu`, `integer`, `token`, or `book`: 128.
- Modernization rows mentioning queue in notes: 278; rows mentioning those domain terms: 306.
- Blank-note rows: 0 for both agents.

Impact: the issue is not absent note-taking. The ledger records summaries, but the summaries do not bind work to `NORTH_STAR.md` or explain why work that did not change `automation/north-star-e2e.sh` output remained on-path.

### WARNING-4: Row schema lacks a normalized North Star evidence field

Evidence:
- The `iterations` table has `task_id`, `status`, `files_changed`, line counts, `validation_cmd`, `validation_result`, `error_msg`, `duration_sec`, and `notes`.
- There is no `north_star_result`, `north_star_justification`, `north_star_changed`, or equivalent structured field.

Impact: future backfills must scrape prose and command strings. That approach cannot reliably enforce the appended Law 5 rule because a row can be well-described but still omit the north-star relationship.

### INFO-5: This trend is repairable with a narrow evidence contract

Evidence:
- Every builder row already has nonblank `notes`, and most rows have validation fields.
- The missing signal can be added without mutating historical TempleOS or holyc-inference source: future insertions can include a dedicated North Star result and a short justification string.

Impact: the durable fix is schema-level evidence, not longer prose. Suggested fields: `north_star_gate_cmd`, `north_star_gate_result`, `north_star_changed BOOLEAN`, and `north_star_justification`.

## Key Aggregates

| Agent | Rows | North Star mentions | North Star gate cmd rows | Queue note rows | Domain note rows | Blank note rows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| inference | 1,414 | 0 | 0 | 740 | 128 | 0 |
| modernization | 1,505 | 0 | 0 | 278 | 306 | 0 |

## Recommendations

- Add normalized North Star fields to future iteration logging instead of relying on `notes`.
- Treat historical rows as `north_star_unknown`, not compliant or noncompliant, unless commit-level audit artifacts provide independent justification.
- Require future builder rows to state whether `automation/north-star-e2e.sh` output changed, and if not, why the iteration was still on-path.
- Keep this as a historical evidence-quality warning; it is not a direct HolyC purity, air-gap, or immutable-image violation.

## Read-Only Verification Command

```bash
sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-north-star-justification-evidence-drift.sql
```

Finding count: 5 total, 4 warnings and 1 info.
