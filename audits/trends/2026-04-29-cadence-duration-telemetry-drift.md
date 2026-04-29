# temple-central.db Cadence and Duration Telemetry Drift

Audit timestamp: 2026-04-29T11:29:13+02:00

Audit angle: historical drift trends. This pass queried `temple-central.db` read-only for long-window builder row cadence and duration telemetry, then wrote this report and its query pack in the Sanhedrin repo only.

## Scope

- Database: `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`
- Rows: `iterations` rows for `modernization` and `inference`
- Window: 2026-04-12T13:51:32 through 2026-04-23T12:06:44
- Query pack: `audits/trends/2026-04-29-cadence-duration-telemetry-drift.sql`
- LAWS.md focus: Law 5 meaningful progress evidence, Law 6 queue traceability, and Law 7 historical stuck/blocker reconstruction.

No trinity source files were modified. No QEMU or VM command was executed.

## Summary

The historical builder rows cannot support reliable duration-based audit conclusions: every builder `duration_sec` value is null, while hundreds of rows are timestamped less than two minutes after the previous same-agent row. These may be legitimate rapid commits, batch ingestion artifacts, or timestamp granularity limits, but the database does not preserve enough telemetry to distinguish those cases.

## Findings

1. **WARNING - Builder duration telemetry is absent for 2,919 / 2,919 rows.**
   Evidence: `duration_sec IS NULL` for all 1,505 modernization rows and all 1,414 inference rows. This blocks historical Law 7 analysis of slow, stuck, or suspiciously short iterations without external process logs.

2. **WARNING - 289 builder rows are recorded less than 60 seconds after the prior same-agent row.**
   Evidence: modernization has 160 `<60s` inter-arrival rows and inference has 129. The same query found 271 modernization rows and 203 inference rows under two minutes.

3. **WARNING - Burst rows include substantive churn, not only tiny metadata edits.**
   Evidence: `<60s` rows account for 36,133 modernization changed lines and 34,279 inference changed lines. Among those burst rows, 110 modernization rows and 89 inference rows changed at least 100 lines; 70 modernization rows and 62 inference rows changed at least 250 lines.

4. **WARNING - Same-second timestamp collisions hide row ordering and effort boundaries.**
   Evidence: modernization has 4 duplicate-timestamp groups containing 9 rows, including `2026-04-20T17:25:38` with `CQ-805, CQ-806, CQ-807` and 662 changed lines. Inference has 3 duplicate-timestamp groups containing 6 rows, including repeated `IQ-1006` and `IQ-1137` rows.

5. **WARNING - Repeated-task bursts blur blocker and retry reconstruction.**
   Evidence: 75 modernization burst rows and 72 inference burst rows reuse the immediately previous task ID within 60 seconds. Without duration, attempt ordinal, or commit SHA, auditors cannot tell whether this represents a quick retry, a partial split of one implementation, or duplicate ingestion.

## Daily Shape

| Day | Agent | Rows | Gaps <60s | Gaps <120s | Min gap |
| --- | --- | ---: | ---: | ---: | ---: |
| 2026-04-12 | inference | 64 | 1 | 1 | 8s |
| 2026-04-12 | modernization | 85 | 2 | 3 | 30s |
| 2026-04-13 | inference | 68 | 1 | 1 | 12s |
| 2026-04-13 | modernization | 137 | 14 | 25 | 0s |
| 2026-04-15 | inference | 35 | 0 | 0 | 345s |
| 2026-04-15 | modernization | 31 | 0 | 0 | 372s |
| 2026-04-16 | inference | 68 | 0 | 0 | 378s |
| 2026-04-16 | modernization | 68 | 0 | 0 | 327s |
| 2026-04-17 | inference | 157 | 0 | 1 | 93s |
| 2026-04-17 | modernization | 143 | 0 | 0 | 155s |
| 2026-04-18 | inference | 152 | 1 | 1 | 43s |
| 2026-04-18 | modernization | 146 | 1 | 2 | 5s |
| 2026-04-19 | inference | 164 | 12 | 26 | 1s |
| 2026-04-19 | modernization | 142 | 16 | 22 | 12s |
| 2026-04-20 | inference | 202 | 18 | 35 | 2s |
| 2026-04-20 | modernization | 225 | 25 | 51 | 0s |
| 2026-04-21 | inference | 219 | 49 | 73 | 0s |
| 2026-04-21 | modernization | 248 | 47 | 79 | 0s |
| 2026-04-22 | inference | 224 | 47 | 65 | 0s |
| 2026-04-22 | modernization | 246 | 55 | 89 | 1s |
| 2026-04-23 | inference | 61 | 0 | 0 | 327s |
| 2026-04-23 | modernization | 34 | 0 | 0 | 244s |

## Representative Rows

| Agent | Timestamp | Task | Gap | Churn | Evidence |
| --- | --- | --- | ---: | ---: | --- |
| modernization | 2026-04-20T17:25:38 | CQ-805/CQ-806/CQ-807 | 0s | 662 | Three modernization rows share the same timestamp. |
| modernization | 2026-04-21T00:44:39 | CQ-888/CQ-889 | 0s | 766 | Two modernization rows share the same timestamp. |
| inference | 2026-04-22T00:08:37 | IQ-1006/IQ-1006 | 0s | 481 | Repeated same-task rows share the same timestamp. |
| inference | 2026-04-22T11:44:01 | IQ-1137/IQ-1137 | 0s | 624 | Repeated same-task rows share the same timestamp. |
| inference | 2026-04-22T00:08:37 | IQ-1006 | 0s | 460 | Validation result: `10 passed in 2.11s`. |

## Recommendations

- Populate `duration_sec` at ingestion time for every builder and Sanhedrin row.
- Add `started_ts`, `finished_ts`, `commit_sha`, and `attempt_ordinal` so repeated task IDs can be separated from duplicate ingestion.
- Record whether a row was produced directly by one iteration or by a batch/backfill import.
- Treat sub-minute historical rows as "needs external corroboration" before using them as Law 5 progress, Law 6 queue, or Law 7 stuck-process evidence.

Finding count: 5 warnings.
