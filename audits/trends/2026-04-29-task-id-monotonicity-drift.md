# temple-central.db Task-ID Monotonicity Drift Audit

Audit timestamp: 2026-04-29T14:58:57+02:00

Audit angle: historical drift trends. This pass queried `temple-central.db` read-only for builder `task_id` shape, repeated queue IDs, composite queue IDs, and numeric monotonicity. No TempleOS or holyc-inference source files were modified. No QEMU or VM command was executed.

## Scope

- Database: `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`
- Rows: `iterations` rows for `modernization` and `inference`
- Window: 2026-04-12T13:51:32 through 2026-04-23T12:06:44
- Query pack: `audits/trends/2026-04-29-task-id-monotonicity-drift.sql`
- LAWS.md focus: Law 6 queue health, especially queue lineage and monotonically increasing queue IDs.

## Findings

1. **WARNING - Repeated task IDs affect 1,313 builder rows.**
   Evidence: 334 modernization task IDs repeat across 752 rows, and 256 inference task IDs repeat across 561 rows. Those repeated-ID rows carry 134,215 modernization added lines and 142,618 inference added lines, so this is not only duplicate bookkeeping.
   Impact: a historical scanner cannot treat one `task_id` as one iteration, one validation event, or one commit-scale unit of work.

2. **WARNING - Single-task numeric order is frequently non-increasing.**
   Evidence: modernization has 321 non-increasing single-task steps, including 109 backwards jumps. Inference has 357 non-increasing single-task steps, including 193 backwards jumps.
   Impact: Law 6 says queue IDs must be monotonically increasing, but the central DB time series cannot prove that property without normalization or a separate queue-event ledger.

3. **WARNING - Modernization collapses multiple CQ items into one row.**
   Evidence: modernization has 103 composite `task_id` rows such as `CQ-240/CQ-241`, `CQ-315/CQ-316/CQ-317`, and `CQ-604/CQ-605`. Inference has 0 composite task rows.
   Impact: composite CQ rows hide per-queue-item validation, line counts, and files changed. They also make completion scoring fragile because one row may close several queue items with one validation result.

4. **WARNING - The drift was concentrated late in the historical window, not isolated.**
   Evidence: on 2026-04-21, modernization recorded 93 non-increasing steps and inference recorded 100. On 2026-04-22, modernization recorded 96 and inference recorded 88; modernization also recorded 31 composite CQ rows that day.
   Impact: this became a sustained telemetry shape during the highest-volume period of the database, so long-window Law 6 reporting should not rely on raw `task_id` ordering.

5. **INFO - A conservative backfill is practical because prefixes are present.**
   Evidence: all 2,919 builder rows use the expected `CQ-` or `IQ-` numeric prefix, and there are 0 blank task IDs.
   Impact: a backfill can split composite CQ rows, preserve repeated task IDs as multi-event work, and compute queue monotonicity from a normalized `task_events` table rather than from the raw `iterations.task_id` string.

## Supporting Extracts

| Agent | Rows | First timestamp | Last timestamp | Distinct task IDs | Composite rows | Repeated task IDs | Rows using repeated IDs | Non-increasing steps | Backwards steps |
| --- | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| inference | 1,414 | 2026-04-12T13:53:13 | 2026-04-23T12:06:44 | 1,109 | 0 | 256 | 561 | 357 | 193 |
| modernization | 1,505 | 2026-04-12T13:51:32 | 2026-04-23T12:01:29 | 1,087 | 103 | 334 | 752 | 321 | 109 |

Most repeated task IDs by row count:

| Agent | Task ID | Rows | First timestamp | Last timestamp |
| --- | --- | ---: | --- | --- |
| modernization | CQ-914 | 6 | 2026-04-21T04:03:30 | 2026-04-21T05:07:43 |
| inference | IQ-878 | 5 | 2026-04-21T06:15:19 | 2026-04-21T06:55:00 |
| modernization | CQ-1118 | 5 | 2026-04-22T02:37:12 | 2026-04-22T02:38:46 |
| modernization | CQ-1191 | 5 | 2026-04-22T07:25:08 | 2026-04-22T08:20:52 |
| modernization | CQ-1223 | 5 | 2026-04-22T10:59:18 | 2026-04-22T14:59:01 |

Largest backwards jumps:

| Agent | Timestamp | Task ID | Previous task ID | Drop by |
| --- | --- | --- | --- | ---: |
| inference | 2026-04-22T03:53:31 | IQ-821 | IQ-1061 | 240 |
| inference | 2026-04-22T03:38:24 | IQ-817 | IQ-1055 | 238 |
| inference | 2026-04-20T22:02:23 | IQ-570 | IQ-805 | 235 |
| inference | 2026-04-20T22:41:42 | IQ-574 | IQ-808 | 234 |
| modernization | 2026-04-15T15:47:37 | CQ-114 | CQ-289 | 175 |

Daily late-window shape:

| Day | Agent | Rows | Composite rows | Non-increasing steps | Backwards steps |
| --- | --- | ---: | ---: | ---: | ---: |
| 2026-04-21 | inference | 219 | 0 | 100 | 38 |
| 2026-04-21 | modernization | 248 | 10 | 93 | 29 |
| 2026-04-22 | inference | 224 | 0 | 88 | 39 |
| 2026-04-22 | modernization | 246 | 31 | 96 | 40 |

## Recommendations

- Add a normalized `task_events` table with one row per queue ID, even when one iteration closes multiple CQ/IQ items.
- Keep `iterations.task_id` as display text, but compute Law 6 monotonicity from parsed task-event rows with `task_prefix`, `task_num`, `source_iteration_id`, and `event_order`.
- Distinguish "continued work on same queue item" from "queue ID reused accidentally" with a structured `work_event_type`.
- Reject or separately classify composite IDs at insert time so `CQ-315/CQ-316/CQ-317` does not erase per-task evidence.
- Add a monotonicity query to historical Sanhedrin reports that flags backwards queue-number jumps larger than a small intentional-retry threshold.

## Reproduction

```text
sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-29-task-id-monotonicity-drift.sql
```

Finding count: 5 total, 4 warnings and 1 info.
