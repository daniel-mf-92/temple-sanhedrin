# Research Ledger Filesystem Backfill Drift

Audit timestamp: 2026-05-02T05:21:50+02:00

Audit angle: historical drift trends. This pass compared the read-only `research` table in `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` against filesystem research artifacts in this Sanhedrin repo. It did not inspect live liveness, restart processes, run QEMU or VM commands, execute WS8 networking tasks, modify TempleOS or holyc-inference source code, or write to the central database. The TempleOS guest air-gap was not touched.

Verifier: `audits/trends/2026-05-02-research-ledger-filesystem-backfill-drift.py`

## Summary

The central DB research ledger is not a complete historical source for research-backed audit work. The `research` table stops at `2026-04-23T05:59:23`, while the repo contains five later `research/*.md` artifacts through `2026-04-27`. Those missing filesystem artifacts include the central-DB readonly-streak research that explains why database ingestion itself went stale, so a DB-only historical analysis omits the very evidence needed to diagnose the DB gap.

Findings: 5 warnings.

## Findings

### WARNING-1: The DB research ledger stops before the filesystem corpus

Evidence:

| Metric | Value |
| --- | ---: |
| DB research rows | 444 |
| DB first research timestamp | `2026-04-15T16:02:12` |
| DB last research timestamp | `2026-04-23T05:59:23` |
| Filesystem `research/*.md` files | 391 |
| Filesystem research files after DB last date | 5 |

Impact: DB-only research trend reports undercount research after April 23 and cannot prove whether later audit recommendations had research support unless they also scan the filesystem.

### WARNING-2: Five post-ledger research artifacts need backfill

Evidence:

| File | Date |
| --- | --- |
| `research/2026-04-25-repeat-task-streak-circuit-breakers.md` | 2026-04-25 |
| `research/2026-04-25-stuck-task-streak-retry-heartbeat-guards.md` | 2026-04-25 |
| `research/2026-04-26-modernization-cq-1214-repeat-streak-guardrails.md` | 2026-04-26 |
| `research/2026-04-26-stuck-loop-failure-patterns.md` | 2026-04-26 |
| `research/2026-04-27-central-db-readonly-streak.md` | 2026-04-27 |

Impact: these files are not noise. They cover repeat-task loop controls and the readonly central DB failure mode, both of which directly affect Law 5, Law 7, and Sanhedrin evidence integrity.

### WARNING-3: The missing research coincides with ongoing audit activity

Evidence:

| Metric after DB last research timestamp | Count |
| --- | ---: |
| Iteration rows after `2026-04-23T05:59:23` | 183 |
| Sanhedrin rows after that timestamp | 143 |
| Sanhedrin `AUDIT` rows mentioning law evidence after that timestamp | 47 |

Impact: the ledger stopped while audit work continued. Historical research coverage metrics that join `iterations` to `research` by time will falsely show no research support for late-April audit work.

### WARNING-4: The only filesystem research on or after the April 27 reform is absent from the DB

Evidence:

- Filesystem files on or after `2026-04-27`: 1.
- File: `research/2026-04-27-central-db-readonly-streak.md`.
- DB research rows on or after `2026-04-27`: 0.

Impact: the April 27 value-not-noise law reform and DB-write failure period are not represented in the structured research table. That makes post-reform research audits depend on markdown scanning unless the DB is backfilled.

### WARNING-5: Existing DB research rows still have reference gaps

Evidence:

- DB research rows with empty `references_urls`: 76 of 444.
- The filesystem-only post-ledger files include explicit reference sections for repeat-task and SQLite readonly analysis.

Impact: a backfill should preserve references from filesystem artifacts instead of inserting only topic names. Otherwise the central ledger remains weak for source-quality and research-provenance audits.

## Daily Counts

| Day | DB research rows | Filesystem research files |
| --- | ---: | ---: |
| 2026-04-15 | 1 | 0 |
| 2026-04-16 | 1 | 0 |
| 2026-04-17 | 1 | 0 |
| 2026-04-19 | 4 | 0 |
| 2026-04-20 | 3 | 3 |
| 2026-04-21 | 273 | 209 |
| 2026-04-22 | 160 | 171 |
| 2026-04-23 | 1 | 3 |
| 2026-04-25 | 0 | 2 |
| 2026-04-26 | 0 | 2 |
| 2026-04-27 | 0 | 1 |

## Recommendation

Backfill filesystem-only research artifacts into a normalized research ledger with source path, artifact hash, trigger, topic, references, and whether the row came from the DB or filesystem. Treat the current `research` table as partial for any historical analysis after `2026-04-23T05:59:23` until that backfill is complete.

## Read-Only Verification Command

```bash
python3 audits/trends/2026-05-02-research-ledger-filesystem-backfill-drift.py
```

Finding count: 5 warnings.
