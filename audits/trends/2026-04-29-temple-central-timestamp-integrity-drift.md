# temple-central.db Timestamp Integrity Drift

Audit timestamp: 2026-04-29T06:23:07+02:00

Audit angle: historical drift trends. This pass queried `temple-central.db` read-only for timestamp shape, ordering, and measurement-field integrity. It did not inspect live processes, restart anything, run QEMU, or modify TempleOS / holyc-inference source code.

## Scope

- Database: `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`
- TempleOS head observed read-only: `abbc679bc7c429c0d89cdef04432b2e7a9d51fc7`
- holyc-inference head observed read-only: `ce09228422dae06e86feb84925d51df88d67821b`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at `7ac0e069669379b7c7251e15beac3d710ac31aca`
- Query pack: `audits/trends/2026-04-29-temple-central-timestamp-integrity-drift.sql`
- LAWS.md focus: Law 7 evidence reliability and Sanhedrin historical auditability. This is not a current liveness audit.

## Findings

1. WARNING - `iterations.ts` has 14 non-canonical Sanhedrin timestamps.
   - Evidence: 10 `pass` rows and 4 `skip` rows fail the canonical `YYYY-MM-DDTHH:MM:SS` shape. The affected id range is `2920..5699`.
   - Impact: lexicographic time filtering can silently drop or misorder Sanhedrin evidence even though builder rows remain canonical.

2. WARNING - Three Sanhedrin rows use a raw epoch-like timestamp.
   - Evidence: ids `4627..4629` use `1776539926` for `EMAIL-CHECK`, `VM-COMPILE`, and `AUDIT`.
   - Impact: these rows sort before all ISO timestamps and can corrupt `min(ts)`, freshness windows, and any trend that treats `ts` as an ISO string.

3. WARNING - Eleven Sanhedrin rows use a space separator instead of `T`.
   - Evidence: ids `2920..2925` use `2026-04-17 17:19:07`; ids `5695..5699` use `2026-04-19 13:21:21`.
   - Impact: SQLite date functions can often parse these, but the rest of the audit corpus consistently uses `T`; string-based reports and shell filters will disagree with SQL date parsing.

4. WARNING - `duration_sec` is empty for every historical iteration row.
   - Evidence: all 14,606 `iterations` rows have `duration_sec IS NULL`.
   - Impact: Law 7 has a stuck-process threshold, but the database cannot support historical duration trend analysis without reconstructing durations from adjacent timestamps or external logs.

5. INFO - Builder rows and research rows keep canonical timestamp shape.
   - Evidence: modernization has 1,505 canonical rows, inference has 1,414 canonical rows, and `research` has 444 canonical rows with 0 non-ISO rows.
   - Impact: the timestamp-shape defect is localized to Sanhedrin bookkeeping rows, not builder pass records.

6. INFO - Canonical ISO iteration rows are monotonic by insertion id.
   - Evidence: after filtering to `YYYY-MM-DDTHH:MM:SS*` timestamps, there are 0 backward timestamp transitions by `id`.
   - Impact: reports can recover reliable ordering by filtering canonical rows first, but mixed-shape rows need normalization before long-window trend queries.

## Supporting Extracts

| Shape | Agent | Status | Rows | First id | Last id | Min ts | Max ts |
| --- | --- | --- | ---: | ---: | ---: | --- | --- |
| `space_separator` | sanhedrin | pass | 8 | 2920 | 5699 | `2026-04-17 17:19:07` | `2026-04-19 13:21:21` |
| `space_separator` | sanhedrin | skip | 3 | 2921 | 5696 | `2026-04-17 17:19:07` | `2026-04-19 13:21:21` |
| `unix_epoch_like` | sanhedrin | pass | 2 | 4628 | 4629 | `1776539926` | `1776539926` |
| `unix_epoch_like` | sanhedrin | skip | 1 | 4627 | 4627 | `1776539926` | `1776539926` |

Affected task ids:

| Task id | Rows | Space rows | Epoch rows |
| --- | ---: | ---: | ---: |
| `AUDIT` | 2,823 | 2 | 1 |
| `EMAIL-CHECK` | 2,088 | 2 | 1 |
| `CLEANUP` | 1,918 | 2 | 0 |
| `VM-COMPILE` | 1,269 | 2 | 1 |
| `CI-CHECK` | 1,261 | 1 | 0 |
| `CI-INFERENCE` | 494 | 1 | 0 |
| `CI-TEMPLEOS` | 417 | 1 | 0 |

## Commands

```bash
sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-29-temple-central-timestamp-integrity-drift.sql
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
git rev-parse HEAD
```

## Recommendations

- Normalize future Sanhedrin writes to strict `strftime('%Y-%m-%dT%H:%M:%S','now')` or an explicit UTC offset form.
- Add a read-only trend-query guard: reject or separately bucket rows where `ts NOT GLOB '????-??-??T??:??:??*'`.
- Backfill a derived normalized timestamp column in reports before computing Law 7 freshness, `min(ts)`, or long-window buckets.
- Start populating `duration_sec` for future rows, or add a derived-duration report that calculates elapsed time from adjacent canonical rows per agent.
