# temple-central.db Queue Materialization Gap Drift

Audit timestamp: 2026-04-29T19:32:20+02:00

Audit angle: historical drift trends. This pass queried `temple-central.db` read-only for Law 6 queue-health traceability, specifically whether the normalized `queue` table is populated consistently with builder iteration task ids. It did not inspect live liveness, run QEMU or VM commands, restart processes, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

## Scope

- Database: `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`
- Query pack: `audits/trends/2026-04-29-queue-materialization-gap-drift.sql`
- Builder iteration window in DB: 2026-04-12 through 2026-04-23
- TempleOS head observed read-only: `d9c3b620dbe9cf8bde884ed11c8ec1df99a68e89`
- holyc-inference head observed read-only: `485af0ea41a239c8393542d6e0e2fc5944f30f53`
- LAWS.md focus: Law 6 Queue Health, Law 5 traceability of meaningful work, and Law 7 historical evidence reliability. This is not a current-iteration queue or liveness check.

## Findings

1. WARNING - The normalized `queue` table is empty despite thousands of builder task executions.
   - Evidence: `iterations` has 14,606 rows, including 1,505 modernization rows and 1,414 inference rows, but `queue` has 0 rows.
   - Impact: DB consumers cannot ask whether CQ/IQ entries are pending, in-progress, done, blocked, skipped, attempted, or erroring through the table that was designed to hold that state.

2. WARNING - Law 6 lineage is present only as repeated free-form `iterations.task_id` strings.
   - Evidence: modernization has 1,505 rows across 1,087 raw task ids; inference has 1,414 rows across 1,109 raw task ids.
   - Impact: queue depth, duplicate detection, and completion state must be reconstructed from task strings and current Markdown snapshots rather than joined to a durable queue ledger.

3. WARNING - Multi-task modernization rows cannot be normalized without a split/backfill rule.
   - Evidence: 101 modernization rows use slash-delimited task ids such as `CQ-1351/CQ-1352`; these represent 94 distinct slash-shaped task-id strings.
   - Impact: a row can represent multiple queue items, but the database has no child table or normalized association table to preserve per-CQ completion evidence.

4. WARNING - Repeated task execution is measurable but not distinguishable from legitimate retry, follow-up, or duplicate work.
   - Evidence: after splitting slash-delimited ids, 395 of 1,108 modernization task tokens and 256 of 1,109 inference task tokens appear more than once. The highest repeated examples are `CQ-1191` at 7 rows and `IQ-878` at 5 rows.
   - Impact: Law 5 and Law 6 historical reports cannot decide whether repeats are useful multi-commit implementation, blocked retries, or queue reuse because `queue.attempt_count` and `queue.last_error` are unavailable.

5. INFO - The schema is already capable of preserving the missing state.
   - Evidence: `queue` has fields for `id`, `agent`, `workstream`, `description`, `status`, `created_ts`, `completed_ts`, `attempt_count`, and `last_error`, and `sqlite_sequence` has no sequence entry for `queue`, confirming it has never received rows in this DB.
   - Impact: this is an ingestion/materialization gap rather than a schema-design gap; a conservative backfill can start with task ids that have exact CQ/IQ shapes and later handle slash-composite rows.

## Supporting Extracts

Table population:

| Table | Rows |
| --- | ---: |
| `iterations` | 14,606 |
| `queue` | 0 |
| `violations` | 0 |
| `research` | 444 |

Builder task-id coverage:

| Agent | Rows | Raw distinct task ids | First ts | Last ts | Min task id | Max task id |
| --- | ---: | ---: | --- | --- | --- | --- |
| `inference` | 1,414 | 1,109 | 2026-04-12T13:53:13 | 2026-04-23T12:06:44 | `IQ-016` | `IQ-999` |
| `modernization` | 1,505 | 1,087 | 2026-04-12T13:51:32 | 2026-04-23T12:01:29 | `CQ-088` | `CQ-999` |

Task tokens after splitting slash-composite ids:

| Agent | Task token rows | Distinct task tokens | Min token | Max token |
| --- | ---: | ---: | --- | --- |
| `inference` | 1,414 | 1,109 | `IQ-016` | `IQ-999` |
| `modernization` | 1,616 | 1,108 | `CQ-088` | `CQ-999` |

Repeat pressure:

| Agent | Task ids | Repeated task ids | Max rows per task | Average rows per task |
| --- | ---: | ---: | ---: | ---: |
| `inference` | 1,109 | 256 | 5 | 1.28 |
| `modernization` | 1,108 | 395 | 7 | 1.46 |

Composite task-id rows:

| Agent | Rows | Slash task rows | Slash task ids | Non-queue-shape rows |
| --- | ---: | ---: | ---: | ---: |
| `inference` | 1,414 | 0 | 0 | 0 |
| `modernization` | 1,505 | 101 | 94 | 0 |

High-repeat examples:

| Agent | Task | Rows | First id | Last id |
| --- | --- | ---: | ---: | ---: |
| `modernization` | `CQ-1191` | 7 | 13722 | 13785 |
| `modernization` | `CQ-914` | 6 | 9859 | 10001 |
| `inference` | `IQ-878` | 5 | 10170 | 10248 |
| `modernization` | `CQ-1118` | 5 | 13186 | 13191 |
| `modernization` | `CQ-1152` | 5 | 13521 | 13532 |
| `modernization` | `CQ-1223` | 5 | 13964 | 14070 |

## Commands

```bash
sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-29-queue-materialization-gap-drift.sql
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
```

## Recommendations

- Populate `queue` on ingestion from `MASTER_TASKS.md` with one row per CQ/IQ item and preserve raw task text separately.
- Add a join table such as `iteration_tasks(iteration_id, queue_id)` so slash-composite iteration rows can be audited per task without losing the original row.
- Treat `iterations.task_id` as evidence, not canonical queue state, until the `queue` table is materialized.
- Backfill exact `CQ-[0-9]+` and `IQ-[0-9]+` ids first; handle slash-composite rows in a second pass so counts stay explainable.

Finding count: 5 total, 4 warnings and 1 info.
