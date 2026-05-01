# temple-central.db Timestamp Format Drift

Audit timestamp: 2026-05-01T03:41:04+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for timestamp encoding drift in historical iteration rows. It did not inspect live liveness, restart processes, run QEMU or VM commands, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

SQL: `audits/trends/2026-05-01-temple-central-timestamp-format-drift.sql`

## Summary

`iterations.ts` is not a single timestamp contract. Builder rows are consistently `YYYY-MM-DDTHH:MM:SS`, but Sanhedrin rows include three encodings: `T` ISO-like timestamps, space-separated timestamps, and raw Unix epoch seconds. The drift is small in row count, but it lands on high-signal Sanhedrin tasks (`AUDIT`, `VM-COMPILE`, `EMAIL-CHECK`, `CI-*`) and is enough to distort naive daily buckets, lexical minima, and replay queries that filter only `T` timestamps.

Findings: 5 total.

## Findings

### WARNING-1: `iterations.ts` has three timestamp encodings

Evidence:
- Total rows: 14,606.
- `YYYY-MM-DDTHH:MM:SS` rows: 14,592.
- `YYYY-MM-DD HH:MM:SS` rows: 11.
- Raw epoch-second rows: 3.
- All 14 non-`T` rows belong to `agent='sanhedrin'`; modernization and inference rows are consistently `T` formatted.

Impact: historical SQL that assumes one timestamp shape can silently exclude Sanhedrin audit evidence while keeping all builder evidence. That weakens Law 5, Law 7, CI, VM, and Sanhedrin enforcement trend replay.

### WARNING-2: Raw epoch rows create a false day bucket and lexical minimum

Evidence:
- Rows `4627`, `4628`, and `4629` have `ts='1776539926'`.
- Interpreted as Unix epoch, all three normalize to `2026-04-18 19:18:46` UTC.
- Naive `substr(ts,1,10)` daily bucketing creates a bogus bucket named `1776539926`.
- `min(ts)` for Sanhedrin `AUDIT`, `EMAIL-CHECK`, and `VM-COMPILE` is the raw epoch string instead of an ISO date.

Impact: daily trend reports and task-family first-seen reports can show impossible-looking dates or sort these rows ahead of all ISO dates.

### WARNING-3: Space-separated timestamp rows are easy to drop with ISO `T` filters

Evidence:
- Eleven Sanhedrin rows use space-separated timestamps.
- Six rows share `2026-04-17 17:19:07` across `CI-TEMPLEOS`, `CI-INFERENCE`, `EMAIL-CHECK`, `VM-COMPILE`, `CLEANUP`, and `AUDIT`.
- Five rows share `2026-04-19 13:21:21` across `CI-CHECK`, `EMAIL-CHECK`, `VM-COMPILE`, `CLEANUP`, and `AUDIT`.

Impact: queries such as `where ts glob '2026-04-*T*'` or parsers that expect a literal `T` undercount Sanhedrin CI, VM, cleanup, and audit rows.

### WARNING-4: Batch timestamps collapse multiple checks onto one instant

Evidence:
- The three epoch rows all have the exact same second.
- The two space-separated clusters assign one timestamp to six checks and five checks respectively.
- A normalized ID-order check found zero rows moving backward in time, so this is not chronological corruption; it is precision/provenance collapse during batch insertion.

Impact: cadence analysis cannot distinguish whether high-risk checks were executed serially, copied from a shared timestamp variable, or inserted as a batch. That matters for Law 7 recurrence timelines and for reconstructing CI/VM evidence order.

### INFO-5: The drift is localized and normalizable

Evidence:
- Only 14 of 14,606 rows are non-`T` format.
- All 14 are Sanhedrin rows between normalized dates `2026-04-17` and `2026-04-19`.
- Normalizing epoch seconds and accepting both `T` and space separators preserves ID-order chronology.

Impact: future historical audits can handle this safely by normalizing through a view rather than rewriting the database. A view such as `iterations_normalized_ts` should expose `ts_epoch`, `ts_iso_utc`, and `ts_format` while leaving the original `ts` untouched.

## Source Counts

| Agent | Rows | `T` ISO | Space ISO | Epoch | Lexical min | Lexical max |
| --- | ---: | ---: | ---: | ---: | --- | --- |
| inference | 1,414 | 1,414 | 0 | 0 | 2026-04-12T13:53:13 | 2026-04-23T12:06:44 |
| modernization | 1,505 | 1,505 | 0 | 0 | 2026-04-12T13:51:32 | 2026-04-23T12:01:29 |
| sanhedrin | 11,687 | 11,673 | 11 | 3 | 1776539926 | 2026-04-23T11:54:59 |

## Non-Standard Rows

| Row IDs | Timestamp | Normalized meaning | Tasks |
| --- | --- | --- | --- |
| 4627-4629 | 1776539926 | 2026-04-18 19:18:46 UTC | `EMAIL-CHECK`, `VM-COMPILE`, `AUDIT` |
| 2920-2925 | 2026-04-17 17:19:07 | Same local-style text, no `T` | `CI-TEMPLEOS`, `CI-INFERENCE`, `EMAIL-CHECK`, `VM-COMPILE`, `CLEANUP`, `AUDIT` |
| 5695-5699 | 2026-04-19 13:21:21 | Same local-style text, no `T` | `CI-CHECK`, `EMAIL-CHECK`, `VM-COMPILE`, `CLEANUP`, `AUDIT` |

## Recommendations

- For trend SQL, read timestamps through a normalization CTE or view before bucketing.
- Track timestamp provenance with a derived `ts_format` value (`iso_t`, `iso_space`, `unix_epoch`) so future audits can report data-quality exceptions explicitly.
- Avoid `min(ts)`, `max(ts)`, and `substr(ts,1,10)` directly on mixed-format `TEXT` timestamps.
- Keep the database read-only for this audit; no backfill mutation was performed.

## Read-Only Verification Command

```bash
sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-temple-central-timestamp-format-drift.sql
```

Finding count: 5 total, 4 warnings and 1 info.
