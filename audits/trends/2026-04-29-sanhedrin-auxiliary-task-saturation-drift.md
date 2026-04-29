# Sanhedrin Auxiliary-Task Saturation Drift Audit

Audit timestamp: 2026-04-29T16:28:51+02:00

Audit angle: historical drift trends. This pass queried `temple-central.db` read-only for Sanhedrin auxiliary task volume, repeated email-check skips, and zero-effect cleanup rows.

## Scope

- Database: `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`
- Rows: `iterations` where `agent = 'sanhedrin'`
- Window: 2026-04-12T13:52:22 through 2026-04-23T11:54:59, with epoch-like timestamps normalized in the query pack
- Query pack: `audits/trends/2026-04-29-sanhedrin-auxiliary-task-saturation-drift.sql`
- LAWS.md focus: Law 5 no busywork and Law 7 blocker escalation evidence quality

No trinity source files were modified. No QEMU or VM command was executed.

## Summary

Sanhedrin's historical DB stream is heavily saturated by auxiliary tasks: `EMAIL-CHECK`, `EMAIL_CHECK`, and `CLEANUP` account for 4,007 of 11,687 Sanhedrin rows, or 34.3%. The email check repeatedly logged missing Google OAuth/MCP credentials for 250.1 hours, while cleanup almost always reported zero deleted files. This does not show a TempleOS or holyc-inference source violation, but it weakens historical trend quality because high-volume auxiliary rows obscure audit signal and repeat known blockers without a typed incident state.

Finding count: 5 total, 4 warnings and 1 info.

## Findings

1. **WARNING - Auxiliary tasks occupy 34.3% of Sanhedrin history.**
   Evidence: 4,007 of 11,687 Sanhedrin rows are `EMAIL-CHECK`, `EMAIL_CHECK`, or `CLEANUP`. By comparison, there are 2,823 `AUDIT` rows. On 2026-04-23, auxiliary rows were 61.6% of Sanhedrin rows.

2. **WARNING - Email credential blocker persisted for 250.1 hours.**
   Evidence: 2,044 email-check rows mention missing `MARTA_GOOGLE_CLIENT_ID` or `MARTA_GOOGLE_CLIENT_SECRET`, spanning 2026-04-13T01:47:06 through 2026-04-23T11:54:25. The blocker was still present on the last DB day in scope.

3. **WARNING - Email-check blocker is duplicated across task rows and audit notes.**
   Evidence: all 2,089 email-check rows are `status = skip`, and 83 `AUDIT` rows on 2026-04-23 also embed `email_check=blocked_missing_marta_google_oauth`. This makes one unresolved auxiliary dependency appear in multiple reporting channels without a normalized incident identifier.

4. **WARNING - Cleanup is mostly zero-effect recurring work.**
   Evidence: 1,914 of 1,918 cleanup rows use zero-delete wording such as `Deleted audit markdown files older than 7d count=0` or `cleanup_old_audit_md_deleted=0`. Only two rows report actual deletion counts, and one row is a `test insert`.

5. **INFO - Auxiliary-to-audit ratio is a useful historical health metric.**
   Evidence: daily auxiliary rows exceeded audit rows on most days after 2026-04-15, peaking at 1.91 auxiliary rows per audit on 2026-04-16 and 1.85 on 2026-04-21. This ratio is a compact way to detect Sanhedrin overhead drift without live liveness checks.

## Daily Shape

| Day | Sanhedrin rows | Audit rows | Auxiliary rows | Auxiliary % | Auxiliary per audit |
| --- | ---: | ---: | ---: | ---: | ---: |
| 2026-04-12 | 79 | 59 | 0 | 0.0 | 0.00 |
| 2026-04-13 | 249 | 73 | 59 | 23.7 | 0.81 |
| 2026-04-15 | 273 | 49 | 78 | 28.6 | 1.59 |
| 2026-04-16 | 646 | 110 | 210 | 32.5 | 1.91 |
| 2026-04-17 | 1,329 | 227 | 415 | 31.2 | 1.83 |
| 2026-04-18 | 1,278 | 299 | 448 | 35.1 | 1.50 |
| 2026-04-19 | 1,231 | 290 | 501 | 40.7 | 1.73 |
| 2026-04-20 | 2,341 | 497 | 911 | 38.9 | 1.83 |
| 2026-04-21 | 2,734 | 526 | 975 | 35.7 | 1.85 |
| 2026-04-22 | 1,222 | 579 | 222 | 18.2 | 0.38 |
| 2026-04-23 | 305 | 114 | 188 | 61.6 | 1.65 |

## Recommendations

- Replace repeated `EMAIL-CHECK` skip inserts with one structured blocker/incident row keyed by cause, first-seen, last-seen, count, and resolution state.
- Keep `AUDIT` notes to a compact reference such as `email_check_incident=<id>` instead of duplicating the full credential blocker.
- Run cleanup only when a preflight count is nonzero, or record it as a periodic maintenance metric outside the main Sanhedrin iteration stream.
- Add an `auxiliary_task` boolean or `task_class` column so long-window Law 5 trend queries can exclude overhead rows without task-name parsing.

## Reproduction

```bash
sqlite3 /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-29-sanhedrin-auxiliary-task-saturation-drift.sql
```
