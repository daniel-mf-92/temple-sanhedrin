# temple-central.db Iteration Duration and Repeat-Accounting Drift Audit

Audit timestamp: 2026-04-30T05:28:31+02:00

Audit angle: historical drift trends. This pass queried `temple-central.db` read-only for long-window evidence quality around `duration_sec`, repeated builder task IDs, and zero-churn pass rows.

## Scope

- Database: `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`
- Table: `iterations`
- Rows: 14,606
- ISO timestamp window: `2026-04-12T13:51:32` through `2026-04-23T12:06:44`
- Query pack: `audits/trends/2026-04-30-iteration-duration-repeat-drift.sql`
- LAWS.md focus: Law 5 no busywork, Law 6 queue health, and Law 7 process liveness.

No TempleOS or holyc-inference source files were modified. No QEMU or VM command was executed.

## Summary

The central database cannot support historical runtime analysis because every row has `duration_sec = NULL`. That directly weakens retrospective Law 7 checks for stuck iterations and also makes repeated task IDs hard to distinguish from legitimate multi-part completions. Builder rows still have validation commands and file lists, but 1,313 builder rows belong to duplicated task IDs and 16 builder pass rows report zero added and zero removed lines.

## Findings

1. **WARNING - All 14,606 iteration rows lack runtime duration.**
   Evidence: `duration_sec IS NULL` for 1,414 inference rows, 1,505 modernization rows, and 11,687 Sanhedrin rows. Law 7 defines a stuck Codex process as running over 25 minutes, but the long-window DB cannot reconstruct historical iteration duration without external logs.

2. **WARNING - Builder duplicate task IDs are common enough to blur Law 5 and Law 6 accounting.**
   Evidence: inference has 256 duplicated task IDs covering 561 rows; modernization has 334 duplicated task IDs covering 752 rows. The maximum repeat count is 5 inference rows for one IQ and 6 modernization rows for one CQ. Some repeats may be legitimate staged work, but the DB has no typed `iteration_kind` or `supersedes_id` to separate continuation, retry, stale closure, and duplicate completion.

3. **WARNING - Several duplicated task IDs span days, not a single implementation session.**
   Evidence: modernization CQ-242, CQ-271 through CQ-277, and neighboring CQ IDs reappear roughly 5,600 to 5,755 minutes after first entry. These long spans are not automatically violations, but they are a historical drift signal: task reuse is visible only by grouping rows after the fact, not by an explicit reopen/retry/continuation field.

4. **WARNING - Sixteen builder pass rows report zero code or artifact churn.**
   Evidence: inference has 6 zero-churn pass rows and modernization has 10. Three modernization rows and one inference row explicitly mention stale, superseded, duplicate, or deduplicated work. Under Law 5 these need a structured non-code justification, because a plain `pass` row with no churn is indistinguishable from queue bookkeeping in aggregate dashboards.

5. **INFO - File-change accounting is present but too prose-shaped for policy queries.**
   Evidence: builder rows populate `files_changed`, yet delimiters vary between commas and semicolons, and task-file changes are mixed with runtime and host-tool changes in one field. This makes trend queries on core-vs-host-vs-queue work brittle; a normalized child table such as `iteration_files(iteration_id, path, role)` would make Law 1, Law 5, and Law 6 backfills more reliable.

## Key Aggregates

| Agent | Rows | Duration null | Duration > 0 |
| --- | ---: | ---: | ---: |
| inference | 1,414 | 1,414 | 0 |
| modernization | 1,505 | 1,505 | 0 |
| sanhedrin | 11,687 | 11,687 | 0 |

| Agent | Duplicated task IDs | Rows in duplicated tasks | Max rows for one task |
| --- | ---: | ---: | ---: |
| inference | 256 | 561 | 5 |
| modernization | 334 | 752 | 6 |

| Agent | Zero-churn pass rows | Zero-churn rows touching task file | Zero-churn stale/dedupe notes |
| --- | ---: | ---: | ---: |
| inference | 6 | 6 | 1 |
| modernization | 10 | 3 | 3 |

## Recommendations

- Populate `duration_sec` for every loop insert, including Sanhedrin rows, and preserve the start timestamp if the duration is estimated from wrapper timing.
- Add a typed repeat field such as `iteration_kind IN ('new', 'continue', 'retry', 'reopen', 'supersede', 'audit')` plus `supersedes_iteration_id`.
- Require `non_code_justification` when a builder row is marked `pass` with zero added and removed lines.
- Normalize `files_changed` into a child table with path roles (`core`, `host_tool`, `test`, `queue`, `doc`) instead of querying prose delimiters.

Finding count: 5 total, 4 warnings and 1 info.
