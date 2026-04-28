# Compound Name and Task Reuse Drift Trend Audit

Timestamp: 2026-04-28T02:00:23+02:00

Scope: Historical drift trends from `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`, focused on builder iteration evidence quality, Law 4 compound-name drift, and Law 6 task/queue traceability. This audit did not inspect live processes, did not run VM/QEMU commands, and did not modify TempleOS or holyc-inference source code.

SQL used: `audits/trends/2026-04-28-compound-name-task-reuse-drift.sql`

## Source Coverage

| Source | Value |
| --- | ---: |
| Modernization builder rows | 1,505 |
| Inference builder rows | 1,414 |
| Modernization pass rows | 1,505 |
| Inference pass rows | 1,414 |
| Modernization timestamp window | 2026-04-12T13:51:32 through 2026-04-23T12:01:29 |
| Inference timestamp window | 2026-04-12T13:53:13 through 2026-04-23T12:06:44 |
| `queue` table rows | 0 |

## Findings

### 1. WARNING: Law 4 compound-name drift is visible across historical changed-file evidence

The builder iteration stream records 1,907 changed-file events whose basename exceeds 40 characters, plus 1,915 changed-file events with more than 5 hyphen/underscore token segments. Modernization accounts for 852 long-name events and 789 many-token events; inference accounts for 1,055 long-name events and 1,126 many-token events.

Impact: the historical trend shows Law 4 was not merely an occasional edge case. It became a recurring naming style in committed automation/test artifacts, so retroactive Law 4 audits should treat compound naming as a systemic drift class.

### 2. WARNING: Compound-name evidence became the dominant shape for inference rows after 2026-04-17

Inference rows with compound-name evidence increased from 12 of 64 rows on 2026-04-12 and 5 of 68 on 2026-04-13 to 131 of 157 on 2026-04-17, 144 of 152 on 2026-04-18, 178 of 202 on 2026-04-20, 194 of 224 on 2026-04-22, and 48 of 61 on 2026-04-23.

Impact: this is a sustained post-2026-04-17 naming-regime shift, not isolated cleanup debt. Historical compliance scoring should bucket this period separately when measuring Law 4 enforcement effectiveness.

### 3. WARNING: Modernization compound-name evidence also rose into a majority pattern

Modernization rows with compound-name evidence rose from 4 of 85 rows on 2026-04-12 to 135 of 225 on 2026-04-20, 157 of 248 on 2026-04-21, 183 of 246 on 2026-04-22, and 24 of 34 on 2026-04-23.

Impact: both builder loops converged on long descriptive artifact names. This creates cross-agent pressure against the identifier-compounding ban and suggests enforcement needs to catch host-side automation/test names as well as core source identifiers.

### 4. WARNING: CQ/IQ task IDs are reused for multiple successful iterations

The DB records 334 reused modernization task IDs out of 1,087 unique CQ IDs, including 67 CQ IDs with at least 3 successful rows and a maximum of 6 rows for `CQ-914`. It also records 256 reused inference task IDs out of 1,109 unique IQ IDs, including 41 IQ IDs with at least 3 successful rows and a maximum of 5 rows for `IQ-878`.

Impact: a single queue ID can represent multiple commits or artifact changes. Historical queue health and north-star scoring should count iteration rows and task IDs separately, otherwise repeated passes against one CQ/IQ item can inflate apparent queue progress.

### 5. WARNING: `queue` table is empty despite extensive CQ/IQ iteration history

The `queue` table has 0 rows while `iterations` contains 2,919 builder rows with CQ/IQ task IDs. The iteration rows have `files_changed`, validation commands, and line counts, but the queue table does not preserve queue depth, source workstream, status transitions, or attempt counts.

Impact: Law 6 backfills cannot reconstruct queue depth, duplicate queue items, or monotonic queue health from the DB alone. They must combine `iterations`, repository `MASTER_TASKS.md` history, and Sanhedrin audit artifacts to avoid false confidence from an empty structured queue table.

## Daily Compound-Name Shape

| Day | Modernization rows | Modernization rows with compound evidence | Inference rows | Inference rows with compound evidence |
| --- | ---: | ---: | ---: | ---: |
| 2026-04-12 | 85 | 4 | 64 | 12 |
| 2026-04-13 | 137 | 66 | 68 | 5 |
| 2026-04-15 | 31 | 6 | 35 | 2 |
| 2026-04-16 | 68 | 14 | 68 | 49 |
| 2026-04-17 | 143 | 48 | 157 | 131 |
| 2026-04-18 | 146 | 79 | 152 | 144 |
| 2026-04-19 | 142 | 98 | 164 | 143 |
| 2026-04-20 | 225 | 135 | 202 | 178 |
| 2026-04-21 | 248 | 157 | 219 | 181 |
| 2026-04-22 | 246 | 183 | 224 | 194 |
| 2026-04-23 | 34 | 24 | 61 | 48 |

## Recommendations

- Treat compound naming as a historical trend class in Law 4 reports, not just a per-commit lint failure.
- Store normalized changed-file basenames and Law 4 lint output in future iteration rows.
- Rehydrate queue depth and duplicate-task metrics from repository task files before scoring Law 6 historically.
- Distinguish unique CQ/IQ completion from repeated successful rows against the same CQ/IQ ID.
- Add a structured queue snapshot table if temple-central.db remains the long-window trend source.
