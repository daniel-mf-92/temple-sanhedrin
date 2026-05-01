# temple-central.db Duration Telemetry Null Drift

Audit timestamp: 2026-05-01T19:11:49+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for whether historical iteration rows preserve `duration_sec` telemetry needed to replay Law 7 hung-process checks and Law 5 progress-rate evidence. It did not inspect live liveness, restart processes, run QEMU or VM commands, run SSH, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

Evidence snapshots:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `9f3abbf26398`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554`
- Sanhedrin audit repo: `/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55` at `f54d56f67040`
- SQL: `audits/trends/2026-05-01-duration-telemetry-null-drift.sql`

## Summary

The central ledger has a `duration_sec` column, but every historical row has NULL duration. That makes the database unusable for retroactively proving the Law 7 "running > 25 minutes = likely hung" threshold, and it weakens Law 5 analysis because repeated successful task rows cannot be distinguished from long-running stalled work by duration.

Findings: 5 total.

## Findings

### WARNING-1: Duration telemetry is absent for every recorded builder iteration

Evidence:
- Inference rows: 1,414 total, 1,414 with NULL `duration_sec`, 0 populated.
- Modernization rows: 1,505 total, 1,505 with NULL `duration_sec`, 0 populated.
- Both builders still record changed files in every row, with 390,043 inference added-line units and 322,560 modernization added-line units.

Impact: historical audits can see that work was recorded, but cannot measure how long each builder iteration took. The ledger cannot separate fast meaningful work from slow or hung work after the fact.

### WARNING-2: Sanhedrin liveness and audit rows also lack duration

Evidence:
- Sanhedrin rows: 11,687 total, 11,687 with NULL `duration_sec`, 0 populated.
- `AUDIT`: 2,823 repeats, all NULL duration, including 31 fail rows.
- `LIVENESS`: 125 repeats, all NULL duration.
- `LAW-CHECK`: 88 repeats, all NULL duration, including 3 fail rows.

Impact: this directly limits retroactive Law 7 enforcement. The database records liveness decisions and heartbeat ages in prose, but does not preserve the measurement interval needed to prove whether the Sanhedrin itself exceeded the 25-minute hung-process boundary.

### WARNING-3: Repeated task streak analysis cannot use elapsed time

Evidence:
- High-repeat Sanhedrin tasks such as `EMAIL-CHECK` (2,088), `CLEANUP` (1,918), `VM-COMPILE` (1,269), and `CI-CHECK` (1,261) all have NULL duration for every row.
- Builder repeat clusters also lack elapsed-time context: `CQ-914` repeats 6 times; `IQ-878`, `CQ-1118`, `CQ-1191`, and `CQ-1223` repeat 5 times each.

Impact: repeated-task drift can be counted, but not weighted by wall time. A five-row retry cluster could represent minutes or hours, and the ledger cannot distinguish those cases.

### WARNING-4: Daily duration coverage is NULL across the full retained window

Evidence:
- The retained ISO timestamp window spans 2026-04-12 through 2026-04-23.
- Every day with builder rows has all builder durations NULL.
- Sanhedrin also has all daily durations NULL, including days with fail or blocked rows: 42 fail/blocked rows on 2026-04-16, 15 on 2026-04-21, and 9 on 2026-04-22.

Impact: the issue is not isolated to a recent schema transition or a single agent. It is a ledger-wide instrumentation gap across the full historical window present in this DB snapshot.

### INFO-5: The drift is locally backfillable only as coarse wall-clock gaps

Evidence:
- Adjacent row timestamp deltas could approximate cadence for some runs, but they would conflate concurrent agents and scheduler gaps with actual command duration.
- The latest rows for `IQ-1266`, `CQ-1351/CQ-1352`, and Sanhedrin `AUDIT` all include useful command or note text but no duration value.

Impact: a future migration can backfill an explicit `duration_unknown` marker or coarse inter-row interval, but exact duration must be captured at insert time. New rows should write measured elapsed seconds for every builder and Sanhedrin task.

## Key Aggregates

| Agent | Rows | NULL Duration Rows | Populated Duration Rows | >25 Minute Rows Detectable |
| --- | ---: | ---: | ---: | ---: |
| inference | 1,414 | 1,414 | 0 | 0 |
| modernization | 1,505 | 1,505 | 0 | 0 |
| sanhedrin | 11,687 | 11,687 | 0 | 0 |

| Task ID | Agent | Repeats | NULL Duration Rows | Fail/Blocked Rows |
| --- | --- | ---: | ---: | ---: |
| AUDIT | sanhedrin | 2,823 | 2,823 | 31 |
| EMAIL-CHECK | sanhedrin | 2,088 | 2,088 | 0 |
| CLEANUP | sanhedrin | 1,918 | 1,918 | 0 |
| VM-COMPILE | sanhedrin | 1,269 | 1,269 | 13 |
| CI-CHECK | sanhedrin | 1,261 | 1,261 | 0 |
| LIVENESS | sanhedrin | 125 | 125 | 0 |
| LAW-CHECK | sanhedrin | 88 | 88 | 3 |

## Recommendations

- Populate `duration_sec` at insertion time for builder, Sanhedrin audit, liveness, CI, cleanup, and law-check rows.
- Treat missing `duration_sec` on future rows as a Sanhedrin instrumentation warning, not as a pass.
- Add separate `started_ts` and `finished_ts` fields if command duration and ledger insertion time can diverge.
- Preserve exact Law 7 process age observations in structured numeric columns instead of notes-only prose.

## Read-Only Verification Command

```bash
sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-duration-telemetry-null-drift.sql
```

Finding count: 5 total, 4 warnings and 1 info.
