# temple-central.db Compound Task-ID Traceability Drift

Audit timestamp: 2026-05-01T04:10:44+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for builder iteration rows whose `task_id` field contains multiple queue identifiers in one cell. It did not inspect live liveness, restart processes, run QEMU or VM commands, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

SQL: `audits/trends/2026-05-01-compound-task-id-traceability-drift.sql`

## Summary

Modernization history contains 103 builder rows where one `iterations.task_id` stores multiple CQ identifiers such as `CQ-1351/CQ-1352`, representing 6.8% of all modernization rows and 216 queue-component references. Inference has zero compound IQ rows. Because the `queue` table in this DB snapshot contains zero rows, the historical record cannot join those component CQ IDs back to per-item queue status, so Law 6 traceability is weaker for those iterations.

Findings: 5 total.

## Findings

### WARNING-1: Modernization stores multiple queue IDs in one iteration field

Evidence:
- Modernization rows: 1,505.
- Compound modernization rows: 103 (`6.8%`).
- Component references represented inside those 103 rows: 216.
- Largest compound row: 4 CQ IDs in one `task_id`.
- Inference rows: 1,414; compound IQ rows: 0.

Impact: a single pass row can retire or claim multiple CQ items without one normalized row per queue item. That weakens Law 6 queue-health analysis because the auditor must parse delimiters before it can reason about monotonic IDs, duplicates, and completion provenance.

### WARNING-2: Compound task IDs intensified late in the captured window

Evidence:
- 2026-04-13: 2 compound rows out of 137 modernization rows (`1.5%`).
- 2026-04-20: 23 compound rows out of 225 (`10.2%`).
- 2026-04-22: 31 compound rows out of 246 (`12.6%`).
- 2026-04-23: 10 compound rows out of 34 (`29.4%`).

Impact: this is not just an early import artifact. The practice became more concentrated near the end of the DB window, when Law 6 evidence should have been getting more structured rather than less normalized.

### WARNING-3: Queue component status cannot be verified from this DB snapshot

Evidence:
- `select count(*) from queue` returns 0.
- Splitting slash-delimited modernization task IDs yields 212 component references.
- All 212 slash component references miss the queue table join.

Impact: historical auditors can see that `CQ-1351/CQ-1352` was marked `pass`, but cannot verify whether `CQ-1351` and `CQ-1352` existed, were pending, were both legitimately completed, or were already closed elsewhere. That is a Law 6 evidence gap rather than proof that the builder violated the underlying queue.

### WARNING-4: Repeated compound rows blur retry versus duplicate-completion semantics

Evidence:
- `CQ-1182/CQ-1183` appears 3 times.
- `CQ-1136/CQ-1137`, `CQ-1147/CQ-1148`, `CQ-630/CQ-631`, `CQ-703/CQ-704`, and `CQ-713/CQ-714` each appear 2 times.

Impact: repeated single-task IDs are explainable as retries, but repeated compound IDs make it ambiguous whether each component item was retried, only one component was retried, or both were counted again. This complicates retrospective duplicate and near-duplicate queue analysis.

### INFO-5: The drift is detectable without source writes

Evidence:
- The compound pattern is visible from `iterations.task_id` using delimiter checks for `/`, `,`, and `+`.
- Daily rates, repeated compound IDs, and missing queue joins can be reproduced with the companion SQL file.
- No TempleOS or holyc-inference source changes are needed to classify the historical rows.

Impact: future backfill can normalize historical task references into a derived read-only view with one row per `(iteration_id, queue_id)` pair. The durable fix would be a structured `iteration_tasks(iteration_id, task_id)` table or a hard insert rule that `iterations.task_id` must contain exactly one queue ID.

## Key Aggregates

| Agent | Rows | Compound Rows | Compound Rate | Max Task-ID Length |
| --- | ---: | ---: | ---: | ---: |
| inference | 1,414 | 0 | 0.0% | 7 |
| modernization | 1,505 | 103 | 6.8% | 31 |

| Compound Rows | Component Refs | Max Components | Avg Components |
| ---: | ---: | ---: | ---: |
| 103 | 216 | 4 | 2.10 |

| Day | Modernization Rows | Compound Rows | Compound Rate |
| --- | ---: | ---: | ---: |
| 2026-04-13 | 137 | 2 | 1.5% |
| 2026-04-16 | 68 | 6 | 8.8% |
| 2026-04-17 | 143 | 7 | 4.9% |
| 2026-04-19 | 142 | 14 | 9.9% |
| 2026-04-20 | 225 | 23 | 10.2% |
| 2026-04-21 | 248 | 10 | 4.0% |
| 2026-04-22 | 246 | 31 | 12.6% |
| 2026-04-23 | 34 | 10 | 29.4% |

## Recommendations

- Normalize queue references into one row per iteration/task pair before scoring Law 6 history.
- Treat compound `task_id` rows as `traceability warning`, not automatic builder failure, unless the underlying queue source proves an invalid or duplicated completion.
- Add a DB insert guard that rejects delimiters in `iterations.task_id` once a separate join table exists.
- Keep `queue` table population in the same archival snapshot as `iterations`; otherwise Law 6 retroactive checks become evidence-limited.

## Read-Only Verification Command

```bash
sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-compound-task-id-traceability-drift.sql
```

Finding count: 5 total, 4 warnings and 1 info.
