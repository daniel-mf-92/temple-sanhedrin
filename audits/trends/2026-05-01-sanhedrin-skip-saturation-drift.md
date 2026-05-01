# temple-central.db Sanhedrin Skip Saturation Drift

Audit timestamp: 2026-05-01T19:21:51+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for long-window skip-row saturation and whether skipped Sanhedrin checks preserve structured failure evidence. It did not inspect live liveness, restart processes, run QEMU or VM commands, run SSH, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

Evidence snapshots:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `9f3abbf26398`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554`
- Sanhedrin audit repo: `/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55` at `b117eb5d2da6`
- SQL: `audits/trends/2026-05-01-sanhedrin-skip-saturation-drift.sql`

## Summary

The central ledger records 2,740 skipped Sanhedrin rows, 18.8% of all retained iteration rows and 23.4% of Sanhedrin rows. The skips are mostly repeated external-notification and CI-observation gaps rather than builder work outcomes, and every skip row lacks structured `error_msg`, `validation_result`, and `validation_cmd` fields. This weakens historical Law 7 and Law 5 audits because high-volume skipped checks become note-only noise with no machine-readable blocker class.

Findings: 5 total.

## Findings

### WARNING-1: Skips are a large Sanhedrin-only ledger class

Evidence:
- Overall status mix: 11,769 pass rows, 2,740 skip rows, 94 fail rows, and 3 blocked rows.
- All 2,740 skip rows are `agent='sanhedrin'`; builder rows for modernization and inference are 100% pass in this DB snapshot.
- Skips account for 18.8% of all retained rows and 23.4% of Sanhedrin rows.

Impact: historical trend queries can easily overcount Sanhedrin activity as audit coverage even when nearly one quarter of its rows represent checks that did not execute.

### WARNING-2: Missing Gmail credentials dominate skipped checks for the whole retained window

Evidence:
- `missing_marta_google_credentials`: 2,048 skip rows across 2 task IDs.
- First retained timestamp for this class is the malformed `1776539926`; the latest is `2026-04-23T11:54:25`.
- `EMAIL-CHECK` has 2,088 rows and all 2,088 are skips.

Impact: repeated notification checks with the same missing-credential condition are not escalated into a durable blocker class. This is historical drift toward Law 7 blocker-retry opacity: the system keeps recording skipped monitoring attempts without structured proof that the underlying dependency changed.

### WARNING-3: Skip rows have no structured error or validation evidence

Evidence:
- Skip rows: 2,740 total, 2,740 missing `error_msg`, 2,740 missing `validation_result`, and 2,740 missing `validation_cmd`.
- Fail rows have the same structured gap: 94 total, 94 missing `error_msg`, 94 missing `validation_result`, and 94 missing `validation_cmd`.
- Blocked rows also have all three fields empty.

Impact: consumers must parse prose in `notes` to understand why skipped or failed checks happened. That makes trend aggregation brittle and prevents reliable enforcement of repeated-error escalation rules.

### WARNING-4: Daily skip rates were high before the retained window ended

Evidence:
- 2026-04-13: 149 skips out of 249 Sanhedrin rows, 59.8%.
- 2026-04-15: 144 skips out of 273 Sanhedrin rows, 52.7%.
- 2026-04-16: 236 skips out of 646 Sanhedrin rows, 36.5%, alongside 42 fail rows.
- 2026-04-23 still has 96 skips out of 305 Sanhedrin rows, 31.5%.

Impact: skip saturation was not a one-day initialization artifact. It persisted across the retained period and was still present on the latest recorded day.

### INFO-5: CI skip drift is smaller but similarly unstructured

Evidence:
- `CI-INFERENCE`: 494 total rows, 444 skips.
- `CI-24308638070`: 158 total rows, 156 skips.
- `CI-24308309656`: 15 total rows, all 15 skips.
- The `ci_no_runs` class accounts for 192 skipped rows across 2 task IDs; additional CI skips fall into other note text classes.

Impact: CI observation gaps are less dominant than email-check skips, but they share the same structured-field problem and can blur whether Sanhedrin had usable external signal for a given historical interval.

## Key Aggregates

| Status | Rows | Percent of All Rows |
| --- | ---: | ---: |
| pass | 11,769 | 80.6% |
| skip | 2,740 | 18.8% |
| fail | 94 | 0.6% |
| blocked | 3 | 0.0% |

| Skip Class | Rows | First Timestamp | Last Timestamp | Task IDs |
| --- | ---: | --- | --- | ---: |
| missing_marta_google_credentials | 2,048 | 1776539926 | 2026-04-23T11:54:25 | 2 |
| other | 464 | 2026-04-12T19:07:45 | 2026-04-22T01:59:16 | 10 |
| ci_no_runs | 192 | 2026-04-13T03:35:13 | 2026-04-18T09:09:16 | 2 |
| other_unavailable | 36 | 2026-04-13T11:42:53 | 2026-04-23T06:15:38 | 3 |

| Task ID | Total Rows | Skip Rows | First Timestamp | Last Timestamp |
| --- | ---: | ---: | --- | --- |
| EMAIL-CHECK | 2,088 | 2,088 | 1776539926 | 2026-04-23T11:54:25 |
| CI-INFERENCE | 494 | 444 | 2026-04-13T10:38:11 | 2026-04-18T15:55:32 |
| CI-24308638070 | 158 | 156 | 2026-04-12T19:07:45 | 2026-04-17T02:48:22 |
| CI-24308309656 | 15 | 15 | 2026-04-12T21:14:34 | 2026-04-15T16:28:51 |

## Recommendations

- Store a normalized `skip_reason` or `blocker_code` column for skipped, failed, and blocked rows.
- Populate `error_msg` for all non-pass rows instead of relying only on prose notes.
- Escalate repeated skipped checks with the same blocker class after a fixed threshold, especially missing credentials and CI no-run observations.
- Separate optional notification checks from core Sanhedrin Law 7 / Law 5 evidence so skipped external integrations do not inflate audit-coverage counts.

## Read-Only Verification Command

```bash
sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-sanhedrin-skip-saturation-drift.sql
```

Finding count: 5 total, 4 warnings and 1 info.
