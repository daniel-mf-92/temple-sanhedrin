# Temple Central Freshness and Instrumentation Drift Trend Audit

Timestamp: 2026-04-28T07:49:37+02:00

Scope: Historical drift trend audit from `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`, with read-only comparisons against `/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55` and `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55` git history after the DB's last builder timestamps. This audit did not inspect live liveness, did not run VM/QEMU commands, did not modify TempleOS or holyc-inference source code, and preserved the guest air-gap.

SQL used: `audits/trends/2026-04-28-temple-central-freshness-instrumentation-drift.sql`

## Source Coverage

| Source | Rows | First timestamp | Last timestamp |
| --- | ---: | --- | --- |
| `iterations` | 14,606 | `1776539926` | 2026-04-23T12:06:44 |
| `violations` | 0 |  |  |
| `research` | 444 | 2026-04-15T16:02:12 | 2026-04-23T05:59:23 |
| `queue` | 0 |  |  |
| Modernization iterations | 1,505 | 2026-04-12T13:51:32 | 2026-04-23T12:01:29 |
| Inference iterations | 1,414 | 2026-04-12T13:53:13 | 2026-04-23T12:06:44 |
| Sanhedrin iterations | 11,687 | `1776539926` | 2026-04-23T11:54:59 |

Read-only git comparison from the DB cutoff forward:

| Repo | Since timestamp | Commits after DB cutoff | Commits touching latest/report artifacts | Matching file events |
| --- | --- | ---: | ---: | ---: |
| TempleOS worktree | 2026-04-23T12:01:29 | 641 | 60 | 585 |
| holyc-inference worktree | 2026-04-23T12:06:44 | 666 | 96 | 530 |

## Findings

### 1. WARNING: `temple-central.db` is stale for builder trend analysis

The last modernization row is 2026-04-23T12:01:29 and the last inference row is 2026-04-23T12:06:44, making both streams about 4.8 days stale at audit time. Read-only git history shows 641 TempleOS commits and 666 holyc-inference commits after those cutoffs.

Impact: long-window dashboards based only on `temple-central.db` cannot see the current April 23-28 builder era. Retroactive audits after 2026-04-23 must use git history and committed audit artifacts as primary evidence, not the DB alone.

### 2. WARNING: Post-cutoff generated-report churn is completely absent from the DB

After the DB cutoff, TempleOS has 60 commits and 585 file events touching `MODERNIZATION/lint-reports/` or `latest` report artifacts. holyc-inference has 96 commits and 530 file events touching `bench/results/`, dashboard, or `latest` artifacts.

Impact: recent drift toward generated report surfaces is invisible to the historical DB. This creates a blind spot for Law 5 scoring, because report regeneration and progress-ledger updates can look like no activity at all from the database.

### 3. WARNING: Structured queue and violation tables do not preserve enforcement history

The `queue` table has 0 rows and the `violations` table has 0 rows, while `iterations` contains 2,919 builder rows and Sanhedrin has many committed audit files outside the DB.

Impact: Law 6 queue depth, duplicate queue items, monotonic queue IDs, and resolved violation trends cannot be reconstructed from structured DB tables. Backfills must combine repository `MASTER_TASKS.md` history, Sanhedrin audit files, and git diffs.

### 4. WARNING: Duration telemetry is missing for every builder iteration

Both builder streams have `duration_sec` missing or zero for every row: 1,505 modernization rows and 1,414 inference rows. The daily aggregates therefore cannot measure slowdown, retry loops, or high-cost validation periods from DB data.

Impact: Law 7 blocker/liveness trend analysis loses a key signal. It can count rows and status, but it cannot distinguish a fast validation pass from a long near-hung iteration.

### 5. WARNING: Historical rows show task-file mutation dominating the recorded window

Within the DB window, `MODERNIZATION/MASTER_TASKS.md` appears in 1,038 modernization file events and `MASTER_TASKS.md` appears in 1,316 inference file events. The current LAWS.md later forbids builder agents from adding CQ/IQ queue items, so this old evidence shape should be treated as a high-risk historical queue-mutability period.

Impact: even when individual commits are legitimate, the trend shows queue files were central work surfaces. Law 6 and "No Self-Generated Queue Items" backfills should inspect the actual diffs for queue-line additions rather than accepting the presence of CQ/IQ task IDs as proof of human-origin queue health.

### 6. INFO: The stale DB window still contains useful source-progress shape

The recorded modernization window includes 751 rows touching core/source paths and 993 rows touching automation/test surfaces. The recorded inference window includes 1,226 rows touching core/runtime source and 1,278 rows touching tests or executable benchmark surfaces.

Impact: the pre-April-23 DB remains useful for broad historical source-vs-test trend shape, but it must be labeled as an older evidence window and not blended with current post-cutoff work without a freshness guard.

## Notable Daily Shape From DB

| Day | Modernization rows | Modernization core/source rows | Modernization executable-surface rows | Inference rows | Inference core/source rows | Inference executable-surface rows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 2026-04-12 | 85 | 62 | 34 | 64 | 61 | 61 |
| 2026-04-17 | 143 | 74 | 88 | 157 | 141 | 146 |
| 2026-04-20 | 225 | 110 | 150 | 202 | 171 | 182 |
| 2026-04-22 | 246 | 104 | 194 | 224 | 194 | 198 |
| 2026-04-23 | 34 | 20 | 24 | 61 | 57 | 61 |

## Recommendations

- Add a freshness gate to any trend report sourced from `temple-central.db`: fail or mark partial if builder rows are older than 24 hours.
- Store commit SHA, branch, duration, typed validation class, and artifact class in `iterations` so DB rows can be joined to git history.
- Populate `violations` and `queue` snapshots, or explicitly deprecate those tables so auditors do not infer false coverage.
- Treat post-2026-04-23 git history as the canonical trend source until DB ingestion resumes.
- Add a normalized `files_changed` child table to avoid recursive string parsing for every historical trend audit.

## Read-Only Verification Commands

- `sqlite3 /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db '.schema iterations'`
- `sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-28-temple-central-freshness-instrumentation-drift.sql`
- `git -C /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55 log --since='2026-04-23T12:01:29' --pretty=format:'%H%x09%cI%x09%s'`
- `git -C /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55 log --since='2026-04-23T12:06:44' --pretty=format:'%H%x09%cI%x09%s'`
