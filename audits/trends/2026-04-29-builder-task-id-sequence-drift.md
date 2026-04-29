# Historical Builder Task-ID Sequence Drift Audit

Timestamp: 2026-04-29T23:30:30+02:00

Audit angle: historical drift trends.

Scope:
- `temple-central.db` historical `iterations` rows for `modernization` and `inference`.
- Current repo heads observed read-only: TempleOS `d84df3da3e8c241f43882f76493e1ae5a2f03b9e`, holyc-inference `485af0ea41a239c8393542d6e0e2fc5944f30f53`, sanhedrin `3814966278d983d521456ddd5d7e009bb17ed21b`.
- SQL: `audits/trends/2026-04-29-builder-task-id-sequence-drift.sql`

No TempleOS or holyc-inference source files were modified. No QEMU/VM command, SSH command, WS8 networking task, socket, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, or package-network action was executed.

## Summary

The builder iteration stream does not provide a strictly monotonic one-row-per-queue-item history. All builder rows use the expected `CQ-` or `IQ-` prefix shape, but the modernization stream multiplexes multiple CQ IDs into a single row, both builder streams reuse task IDs, and numeric queue IDs move backward hundreds of times when ordered by timestamp. This weakens Law 6 historical queue-health analysis because monotonicity and duplicate detection cannot be answered from `iterations.task_id` without reparsing prose or consulting external logs.

Finding count: 5 total, 4 warnings and 1 info.

## Findings

1. **WARNING - Modernization rows multiplex multiple queue items into one `task_id` field.**
   Evidence: 103 modernization rows contain `/` or `,` separators, representing 216 apparent CQ mentions. The largest single row references 4 CQ IDs, such as `CQ-671/CQ-672/CQ-673/CQ-674`; repeated examples include `CQ-1182/CQ-1183` with 3 rows.

2. **WARNING - Duplicate task IDs are common in both builder streams.**
   Evidence: modernization has 334 duplicate task IDs covering 752 rows, with one ID reused 6 times. Inference has 256 duplicate task IDs covering 561 rows, with one ID reused 5 times. Representative high-reuse rows include `CQ-914` across 6 rows, `CQ-1118`, `CQ-1191`, and `CQ-1223` across 5 rows each, and `IQ-878` across 5 rows.

3. **WARNING - Numeric task IDs move backward in timestamp order.**
   Evidence: after excluding multiplexed modernization rows, modernization has 109 backward transitions across 1,402 numeric rows; inference has 193 backward transitions across 1,414 rows. Early examples include `CQ-111 -> CQ-110`, `CQ-194 -> CQ-189`, `IQ-034 -> IQ-026`, and `IQ-127 -> IQ-020`.

4. **WARNING - Forward gaps and adjacent repeats make queue-depth inference unreliable.**
   Evidence: modernization has 243 forward gaps and 212 adjacent repeats in numeric order; inference has 317 forward gaps and 164 adjacent repeats. These may reflect legitimate parallel work or backfills, but the central DB lacks a structured distinction between retry, continuation, batch completion, and newly assigned work.

5. **INFO - Prefix shape is consistent even though sequence semantics drift.**
   Evidence: 1,505 modernization rows and 1,414 inference rows all match the expected `CQ-[0-9]*` or `IQ-[0-9]*` prefix pattern. The problem is not missing prefixes; it is that the single `task_id` text column carries overloaded semantics.

## Daily Shape

| Day | Agent | Numeric rows | Backward transitions | Adjacent repeats | Forward gaps |
| --- | --- | ---: | ---: | ---: | ---: |
| 2026-04-12 | inference | 64 | 1 | 1 | 4 |
| 2026-04-12 | modernization | 85 | 3 | 3 | 7 |
| 2026-04-13 | inference | 68 | 9 | 2 | 12 |
| 2026-04-13 | modernization | 135 | 7 | 27 | 16 |
| 2026-04-15 | inference | 35 | 3 | 0 | 5 |
| 2026-04-15 | modernization | 31 | 1 | 0 | 0 |
| 2026-04-16 | inference | 68 | 10 | 0 | 15 |
| 2026-04-16 | modernization | 62 | 1 | 0 | 6 |
| 2026-04-17 | inference | 157 | 18 | 0 | 33 |
| 2026-04-17 | modernization | 136 | 4 | 0 | 17 |
| 2026-04-18 | inference | 152 | 7 | 1 | 15 |
| 2026-04-18 | modernization | 146 | 4 | 2 | 8 |
| 2026-04-19 | inference | 164 | 26 | 22 | 41 |
| 2026-04-19 | modernization | 128 | 1 | 20 | 18 |
| 2026-04-20 | inference | 202 | 40 | 26 | 58 |
| 2026-04-20 | modernization | 202 | 15 | 40 | 49 |
| 2026-04-21 | inference | 219 | 38 | 62 | 67 |
| 2026-04-21 | modernization | 238 | 29 | 64 | 52 |
| 2026-04-22 | inference | 224 | 39 | 49 | 63 |
| 2026-04-22 | modernization | 215 | 40 | 56 | 60 |
| 2026-04-23 | inference | 61 | 2 | 1 | 4 |
| 2026-04-23 | modernization | 24 | 4 | 0 | 10 |

## Representative Rows

| Agent | Previous | Current | Drift |
| --- | --- | --- | --- |
| inference | 2026-04-12T14:21:55 `IQ-034` | 2026-04-12T14:29:53 `IQ-026` | backward |
| modernization | 2026-04-12T16:56:54 `CQ-111` | 2026-04-12T17:02:36 `CQ-110` | backward |
| modernization | 2026-04-13T01:34:30 `CQ-194` | 2026-04-13T01:36:49 `CQ-189` | backward |
| inference | 2026-04-13T05:55:39 `IQ-127` | 2026-04-13T06:02:30 `IQ-020` | backward |
| modernization | 2026-04-20T02:12:36 `CQ-671/CQ-672/CQ-673/CQ-674` | single row | multiplexed |

## Recommendations

- Add a normalized `iteration_tasks(iteration_id, task_id, task_num, task_prefix, role)` table so one iteration can explicitly reference multiple queue items without overloading `iterations.task_id`.
- Add a `task_event_type` field with values such as `start`, `continue`, `retry`, `complete`, `batch-complete`, and `backfill` before using task-id order as a queue-health proxy.
- Keep Law 6 monotonicity checks against the authoritative queue source, not against the historical iteration row alone.
- For future reports, treat `/` and `,` separated task IDs as batch rows and exclude them from numeric monotonicity calculations unless normalized first.
