# temple-central.db North Star Evidence Blindspot Trend

Audit timestamp: 2026-05-02T10:42:14+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for long-window builder evidence relevant to the newer North Star Discipline law. It did not inspect live liveness, restart processes, run QEMU or VM commands, run SSH/SCP, execute WS8 networking tasks, modify TempleOS or holyc-inference source code, or write to the central database. The TempleOS guest air-gap was not touched.

SQL: `audits/trends/2026-05-02-north-star-evidence-blindspot.sql`

Evidence snapshots:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `9f3abbf26398`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554`
- Sanhedrin audit repo before this artifact: `/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55` at `ac9ac11298fd`

## Summary

`temple-central.db` contains 2,919 builder pass rows in the inspected snapshot: 1,505 modernization rows and 1,414 inference rows. None of those rows mention `north-star-e2e`, `north_star`, or the phrase `north star` in the command/result/notes fields, and no builder pass row records `NORTH_STAR.md` as changed. This does not prove historical builder work was off-path, because the North Star Discipline law was added after project inception and older rows may predate it. It does mean central-DB-only backfill cannot distinguish "north-star validated," "north-star impact explained," and "not evaluated" for the historical builder stream.

Findings: 5 warning findings.

## Findings

### WARNING-1: Central builder history has no North Star evidence terms

Evidence:
- Modernization rows: 1,505 pass rows, 0 `north-star-e2e` mentions, 0 `north_star` mentions, 0 `north star` phrase mentions.
- Inference rows: 1,414 pass rows, 0 `north-star-e2e` mentions, 0 `north_star` mentions, 0 `north star` phrase mentions.

Impact: Law 5 North Star Discipline cannot be retroactively scored from the central ledger alone. A pass row may be valid, but the DB does not preserve whether `automation/north-star-e2e.sh` changed output or whether the builder explained why the iteration stayed on-path without changing that output.

### WARNING-2: `NORTH_STAR.md` is absent from builder file-change history

Evidence:
- Modernization pass rows with `NORTH_STAR.md` in `files_changed`: 0.
- Inference pass rows with `NORTH_STAR.md` in `files_changed`: 0.
- Builder rows frequently include `MASTER_TASKS.md`: 1,040 modernization rows and 1,317 inference rows.

Impact: queue and task metadata are heavily represented, but the north-star contract itself is not represented as a first-class evidence surface. This makes it harder to detect whether recurring task work remained tied to the north-star outcome or only to queue churn.

### WARNING-3: Historical pass rows contain zero-line changes

Evidence:
- Modernization zero-line pass rows: 10, from `CQ-186` through `CQ-1152`.
- Inference zero-line pass rows: 6, from `IQ-470` through `IQ-978`.
- Sample rows include file lists with core paths and tests but `lines_added = 0` and `lines_removed = 0`.

Impact: zero-line pass rows can be legitimate when central inserts are approximate or a task supersedes another task, but they are weak evidence for Law 5 progress. A backfill scorer should mark them "needs source/diff join" rather than compliant or noncompliant from DB data alone.

### WARNING-4: Repeated task IDs need a North Star delta/explanation join

Evidence:
- Repeated builder task IDs include `CQ-914` with 6 rows, `IQ-878` with 5 rows, `CQ-1118` with 5 rows, `CQ-1191` with 5 rows, and `CQ-1223` with 5 rows.
- Many additional CQ/IQ task IDs have 3 or 4 rows.

Impact: repeated work can be legitimate iteration, but without north-star delta or explanation fields, the DB cannot separate meaningful incremental validation from retry loops, fragmentation, or task-padding behavior.

### WARNING-5: The current schema lacks fields for the new Law 5 proof

Evidence:
- The `iterations` table has `validation_cmd`, `validation_result`, `notes`, `files_changed`, and line counts, but no normalized fields for `north_star_cmd`, `north_star_result_before`, `north_star_result_after`, `north_star_changed`, or `north_star_no_delta_reason`.
- All builder rows have nonblank validation command/result fields, so this is not a generic missing-validation problem; it is a missing North Star proof-shape problem.

Impact: after the Law 5 addition, historical and future trend scoring should not rely on free-text searches. The central ledger needs normalized North Star fields or a child evidence table so Sanhedrin can backfill and detect five consecutive no-delta iterations with explicit reasons.

## Key Aggregates

| Metric | Modernization | Inference |
| --- | ---: | ---: |
| Builder pass rows | 1,505 | 1,414 |
| `north-star-e2e` mentions | 0 | 0 |
| `north_star` mentions | 0 | 0 |
| `north star` phrase mentions | 0 | 0 |
| `NORTH_STAR.md` file rows | 0 | 0 |
| `MASTER_TASKS.md` file rows | 1,040 | 1,317 |
| Zero-line pass rows | 10 | 6 |

## Recommendations

- Add normalized North Star evidence fields to iteration inserts, or add a child table keyed to `iterations.id`.
- Record the exact `automation/north-star-e2e.sh` command, result digest before/after, whether output changed, and the no-delta explanation when output does not change.
- Treat historical rows without North Star fields as "unknown" rather than compliant/noncompliant during backfill scoring.
- Add a Sanhedrin backfill report that joins these DB rows to git diffs for the repeated task IDs and zero-line rows before assigning Law 5 compliance.

## Read-Only Verification Command

```bash
sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-02-north-star-evidence-blindspot.sql
```

Finding count: 5 warnings.
