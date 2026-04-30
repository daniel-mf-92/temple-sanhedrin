# Sanhedrin Artifact Accounting Drift Audit

Audit timestamp: 2026-04-30T05:28:00+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for Sanhedrin artifact-accounting coverage. It did not inspect live liveness, did not execute QEMU or VM commands, and did not modify TempleOS or holyc-inference source code.

SQL used: `audits/trends/2026-04-30-sanhedrin-artifact-accounting-drift.sql`

## Summary

Sanhedrin's historical `iterations` stream records 11,687 Sanhedrin rows, but every one has `lines_added = 0` and `lines_removed = 0`; 11,613 rows also have blank `files_changed`. Only 74 rows name an artifact at all, nearly all under `RESEARCH`. This makes artifact-producing audit work, pure polling, CI checks, cleanup, and skipped auxiliary checks indistinguishable by structured counters.

Finding count: 5 warnings.

## Findings

1. **WARNING - Sanhedrin rows have a 100% zero-delta accounting rate.**  
   Evidence: all 11,687 Sanhedrin rows have `lines_added = 0` and `lines_removed = 0`. Builder rows do not show the same pattern: modernization has 10 zero-delta rows out of 1,505, and inference has 6 out of 1,414. Impact: Law 5 trend analysis cannot tell audit artifact production from zero-effect busywork using DB counters.

2. **WARNING - `files_changed` is effectively absent for Sanhedrin audit rows.**  
   Evidence: 11,613 of 11,687 Sanhedrin rows have blank `files_changed`; only 74 rows have a nonblank value, and there are only 64 distinct artifact paths. Impact: audit reports committed under `audits/` are not represented as first-class historical outputs in the central DB.

3. **WARNING - High-volume audit tasks do not identify their report artifacts.**  
   Evidence: `AUDIT/pass` has 2,792 rows but only 1 nonblank `files_changed` value. `LAW-CHECK/pass` has 85 rows and 0 nonblank `files_changed` values. `DB-CHECK/pass`, `VM-CHECK/pass`, `VM-COMPILE/pass`, and CI task rows also record no files changed. Impact: historical consumers cannot join Sanhedrin conclusions to the exact committed audit file or evidence pack.

4. **WARNING - Artifact tracking is concentrated in repeat-task research only.**  
   Evidence: 73 of the 74 nonblank Sanhedrin `files_changed` rows occur on 2026-04-21, and the named paths are mostly `research/2026-04-21-repeat-task...` files. On every other valid DB day except 2026-04-22, Sanhedrin has 0 nonblank file paths. Impact: the DB has a narrow exception for one research wave rather than a general audit artifact ledger.

5. **WARNING - Long narrative notes are carrying structure that belongs in columns.**  
   Evidence: Sanhedrin rows average 191.5 note characters; 2,829 rows have notes of at least 200 characters, and the longest note is 2,162 characters. Meanwhile artifact path, validation class, source repo, and report identity are mostly absent from columns. Impact: trend audits must parse prose to reconstruct facts that should be queryable.

## Daily Shape

| Day | Sanhedrin rows | Nonblank `files_changed` | `AUDIT` rows | `RESEARCH` rows |
| --- | ---: | ---: | ---: | ---: |
| 2026-04-12 | 79 | 0 | 59 | 0 |
| 2026-04-13 | 249 | 0 | 73 | 0 |
| 2026-04-15 | 273 | 0 | 49 | 0 |
| 2026-04-16 | 646 | 0 | 110 | 0 |
| 2026-04-17 | 1,329 | 0 | 227 | 0 |
| 2026-04-18 | 1,275 | 0 | 298 | 0 |
| 2026-04-19 | 1,231 | 0 | 290 | 0 |
| 2026-04-20 | 2,341 | 0 | 497 | 0 |
| 2026-04-21 | 2,734 | 73 | 526 | 193 |
| 2026-04-22 | 1,222 | 1 | 579 | 32 |
| 2026-04-23 | 305 | 0 | 114 | 0 |

## Recommendations

- Add `artifact_path`, `artifact_kind`, `source_repo`, and `source_commit` columns, or an `iteration_artifacts` child table, for Sanhedrin rows that create audit reports.
- Populate `files_changed`, `lines_added`, and `lines_removed` from the actual Sanhedrin git commit when an audit artifact is written.
- Move repeated evidence tokens from prose notes into typed columns such as `validation_class`, `severity`, `checked_repo`, and `checked_commit`.
- Treat Sanhedrin DB rows before this fix as control-plane activity records, not reliable artifact-production records.

## Reproduction

```bash
sqlite3 /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-30-sanhedrin-artifact-accounting-drift.sql
```
