# temple-central.db Coverage And Severity Drift

Audit timestamp: 2026-04-28T17:58:01+02:00

Audit angle: historical drift trends. This pass queried `temple-central.db` read-only and compared its latest builder coverage to current local git history in `TempleOS` and `holyc-inference`. No Trinity source code was modified and no VM or QEMU command was executed.

## Scope

- Database: `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`
- Builder repos checked read-only:
  - `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS`
  - `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`
- Query pack: `audits/trends/2026-04-28-temple-central-coverage-and-severity-drift.sql`
- LAWS.md focus: historical observability for Law 5, Law 6, Law 7, Sanhedrin enforcement, and retroactive audit reliability.

## Findings

1. WARNING - `temple-central.db` is historically stale for both builders.
   - Evidence: `iterations.max(ts)` is `2026-04-23T12:06:44`, while local git history after that point contains 603 TempleOS commits and 587 holyc-inference commits.
   - Impact: long-window trend reports using only this DB cannot cover the current five-day workstream, so Law 5 and Law 7 trend conclusions after 2026-04-23 require git/audit-file supplementation.

2. WARNING - `violations` and `queue` are empty despite LAWS.md expecting enforcement records there.
   - Evidence: `violations` has 0 rows and `queue` has 0 rows; `iterations` has 14,606 rows and `research` has 444 rows.
   - Impact: Law 6 queue-health history and violation lifecycle analysis cannot be reconstructed from the canonical tables. Enforcement severity is embedded in free-form `iterations.notes` instead.

3. WARNING - Severity semantics are split between structured `status` and free-form `notes`.
   - Evidence: notes contain 7 `Severity=CRITICAL` entries on `fail` rows, 1 warning on a `fail` row, and 144 warning-severity notes on `pass` rows; the `violations` table remains empty.
   - Impact: a simple `status='pass'` trend hides warning-bearing audits. This weakens retroactive Law 5, Law 7, and Sanhedrin enforcement summaries unless parsers inspect `notes`.

4. WARNING - Timestamp normalization is not total.
   - Evidence: 3 Sanhedrin iteration rows use raw `1776539926` instead of ISO timestamps.
   - Impact: chronological windows and daily buckets can silently drop or misorder these rows. Historical trend scripts must filter or normalize timestamp formats before aggregation.

5. INFO - Pre-staleness builder iteration evidence is dense, but Sanhedrin rows are sparse on validation fields.
   - Evidence: before the DB stopped, 1,414 inference rows and 1,505 modernization rows had validation command/result and files changed populated. Sanhedrin had 11,684 ISO-timestamped rows, but all 11,684 were missing validation command/result and 11,610 were missing files changed.
   - Impact: builder productivity trends are usable through 2026-04-23; Sanhedrin self-behavior trends depend primarily on `notes`, not structured validation fields.

## Supporting Extracts

| Table | Rows | First timestamp | Last timestamp |
| --- | ---: | --- | --- |
| iterations | 14,606 | 1776539926 | 2026-04-23T12:06:44 |
| violations | 0 |  |  |
| queue | 0 |  |  |
| research | 444 | 2026-04-15T16:02:12 | 2026-04-23T05:59:23 |

| Agent | Status | Rows | First timestamp | Last timestamp |
| --- | ---: | ---: | --- | --- |
| inference | pass | 1,414 | 2026-04-12T13:53:13 | 2026-04-23T12:06:44 |
| modernization | pass | 1,505 | 2026-04-12T13:51:32 | 2026-04-23T12:01:29 |
| sanhedrin | blocked | 3 | 2026-04-20T02:58:03 | 2026-04-20T17:04:17 |
| sanhedrin | fail | 94 | 2026-04-13T07:22:49 | 2026-04-22T23:55:13 |
| sanhedrin | pass | 8,850 | 1776539926 | 2026-04-23T11:54:59 |
| sanhedrin | skip | 2,740 | 1776539926 | 2026-04-23T11:54:25 |

High-repeat research topics clustered around repeat-task-loop remediation, with 13 rows for `repeat-task-streak-remediation`, 9 for `repeat-task streak remediation`, and multiple near-duplicate variants from 2026-04-21 through 2026-04-23. That supports a pre-staleness Law 5/7 trend of researching blocker and repeat-task mitigation, but not a post-2026-04-23 conclusion.

## Recommendation

- Treat `temple-central.db` as a pre-2026-04-23 historical artifact until ingestion resumes.
- For retroactive audits after `2026-04-23T12:06:44`, source evidence from git commits and `audits/` files, then reconcile back into structured tables only after timestamp and severity fields are normalized.
- If `violations` remains empty by design, add a documented view or export that maps `iterations.notes` severity markers into structured violation rows for backfill reporting.
