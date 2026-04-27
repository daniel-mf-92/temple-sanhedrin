# Temple Central Long-Window Agent Behaviour Trend Audit

Timestamp: 2026-04-27T13:33:44Z

Scope: Historical drift trends from `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`. This audit did not inspect or modify live loops, did not run VM/QEMU commands, and did not touch TempleOS or holyc-inference source code.

SQL used: `audits/trends/2026-04-27-temple-central-long-window-agent-behaviour.sql`

## Source Coverage

| Source | Value |
| --- | ---: |
| `iterations` rows, inference | 1,414 |
| `iterations` rows, modernization | 1,505 |
| `iterations` rows, sanhedrin | 11,687 |
| Builder window | 2026-04-12T13:51:32 through 2026-04-23T12:06:44 |
| Latest Sanhedrin DB row | 2026-04-23T11:54:59 |
| `violations` rows | 0 |
| `queue` rows | 0 |
| `research` rows | 444 |
| Pending central DB insert SQL files in this repo | 393 |

## Findings

### 1. CRITICAL: Central DB trend window is stale after April 23

`temple-central.db` has no rows after 2026-04-23T12:06:44 for the builder agents and no Sanhedrin rows after 2026-04-23T11:54:59, while this repo contains 393 pending central DB insert SQL files through 2026-04-27. Long-window trend dashboards built directly from the DB are blind to at least four days of audit activity unless those pending inserts are replayed or intentionally archived as rejected.

Impact: historical compliance analysis undercounts April 24-27 failures, liveness incidents, Law 5 findings, and any later remediation.

### 2. CRITICAL: `violations` table is empty despite failed Sanhedrin audit rows

The `violations` table has 0 rows, but `iterations` contains 94 Sanhedrin `fail` rows and 3 Sanhedrin `blocked` rows. Examples include repeated `CI-TEMPLEOS` failures from 2026-04-16 through 2026-04-17, `VM-COMPILE` failures and blocks through 2026-04-20, and `LAW-CHECK` failures through 2026-04-22.

Impact: consumers using `violations` as the source of truth will report a clean historical record while the audit iteration stream records failures.

### 3. WARNING: Queue-health evidence is not persisted in the `queue` table

Law 6 requires queue depth and monotonic queue ID checks, but `queue` has 0 rows. Sanhedrin notes contain queue-depth snippets such as `L6_open_CQ=57`, `L6_open_CQ=40`, and `LAW6=52`, meaning the checks existed only in free-text notes rather than structured queue state.

Impact: retroactive Law 6 backfills cannot be reproduced from central structured data; they depend on brittle note parsing.

### 4. WARNING: Builder task IDs repeat frequently

Modernization has 1,505 iteration rows but only 1,087 distinct task IDs, leaving 418 duplicate task rows. Inference has 1,414 rows but only 1,109 distinct task IDs, leaving 305 duplicate task rows. Repeated task IDs are not automatically violations because an iteration row may represent a retry or continuation, but the scale is large enough to require explicit classification.

Highest repeats:

| Agent | Task | Repeats | First | Last |
| --- | --- | ---: | --- | --- |
| modernization | CQ-914 | 6 | 2026-04-21T04:03:30 | 2026-04-21T05:07:43 |
| inference | IQ-878 | 5 | 2026-04-21T06:15:19 | 2026-04-21T06:55:00 |
| modernization | CQ-1118 | 5 | 2026-04-22T02:37:12 | 2026-04-22T02:38:46 |
| modernization | CQ-1191 | 5 | 2026-04-22T07:25:08 | 2026-04-22T08:20:52 |
| modernization | CQ-1223 | 5 | 2026-04-22T10:59:18 | 2026-04-22T14:59:01 |

Impact: this is Law 5/Law 6 drift risk. The trend matches `research` table concentration on repeat-task remediation topics, with `repeat-task-streak-remediation` appearing 13 times and related repeat-task topics dominating the top research topics.

### 5. WARNING: Sanhedrin rows lack structured validation and duration fields

All 11,687 Sanhedrin iteration rows have empty `validation_cmd`, empty `validation_result`, and missing `duration_sec`. Most also have empty `files_changed` (11,613 rows). Builder rows do fill validation and files fields, but also have missing duration across all rows.

Impact: long-window analysis cannot distinguish quick checks from long or hung checks, cannot group Sanhedrin validation by command, and cannot reliably compare audit cost against audit value.

### 6. INFO: Timestamp quality has isolated malformed rows

There are 14 non-ISO timestamp rows. Six use a space separator (`2026-04-17 17:19:07`), five use a space separator (`2026-04-19 13:21:21`), and three use the epoch-like value `1776539926`. The malformed rows do not dominate the dataset, but they do distort lexical ordering and day bucketing.

Impact: trend scripts must normalize timestamps before grouping or sorting. The current day aggregation produces a synthetic `1776539926` day.

## Daily Builder Throughput Summary

The builders record only `pass` statuses in this DB window: 1,505 modernization passes and 1,414 inference passes. Modernization added 322,560 lines and removed 373 lines, averaging 214.3 added lines per iteration. Inference added 390,043 lines and removed 294 lines, averaging 275.8 added lines per iteration.

This high-pass, high-addition pattern should be interpreted cautiously because the empty `violations` table and stale DB window show that compliance failures were not fully normalized into structured tables.

## Recommendations

- Backfill or explicitly close the 393 pending central DB insert files before using `temple-central.db` for April 24-27 trend conclusions.
- Add a structured failure-to-violation normalization step so Sanhedrin `fail`/`blocked` rows create or link to `violations` rows.
- Persist queue snapshots into `queue` or a queue-history table so Law 6 audits do not depend on free-text notes.
- Add a retry/continuation field for repeated builder task IDs, or mark repeated task IDs as Law 5/Law 6 review candidates.
- Require ISO-8601 timestamps and validation/duration fields for every Sanhedrin insert.
