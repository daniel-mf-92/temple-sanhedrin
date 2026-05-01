# temple-central.db Email-Check Credential Skip Saturation

Audit timestamp: 2026-05-02T01:51:40+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for Sanhedrin email-notification rows that repeatedly skipped on the same missing Google credential condition. It did not inspect live liveness, restart processes, run QEMU or VM commands, run SSH, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

SQL: `audits/trends/2026-05-02-email-check-credential-skip-saturation.sql`

## Summary

Sanhedrin historical rows show a high-volume skipped email-notification path that repeatedly queried for GitHub failure emails through Gmail/MCP despite missing `MARTA_GOOGLE_CLIENT_ID` / `MARTA_GOOGLE_CLIENT_SECRET`. The check produced 2,089 skipped rows, 17.9% of all Sanhedrin rows in the DB snapshot, and 2,048 rows normalize to the same missing-credential blocker. This is not a TempleOS guest network breach; it is host-side audit telemetry drift that crowds the history with a known unavailable remote-service dependency.

Findings: 5 total.

## Findings

### WARNING-1: Email notification checks consumed 17.9% of Sanhedrin history while always skipped

Evidence:
- Sanhedrin rows: 11,687.
- `EMAIL%` rows: 2,089.
- `EMAIL%` rows with `status = skip`: 2,089.
- Email-check share of Sanhedrin rows: 17.9%.

Impact: skipped remote-notification checks became a major part of the historical audit stream without producing compliance evidence. This weakens long-window Law 7 and CI trend analysis because row volume reflects a known credential gap rather than fresh audit work.

### WARNING-2: One missing-credential blocker accounts for 2,048 rows

Evidence:
- Normalized key `missing_marta_google_credentials`: 2,048 rows.
- First observed: `1776539926` legacy epoch-style timestamp row.
- Last observed: `2026-04-23T11:54:25`.
- All 2,048 rows were skipped.

Impact: Law 7 expects repeated blocker strings to escalate after 3+ consecutive appearances. The same missing credential condition stayed in the ledger for days as repeated skips instead of being collapsed into one escalated/suppressed blocker record.

### WARNING-3: Same-error streaks were far above the Law 7 recurrence threshold

Evidence:
- Longest consecutive normalized same-error email streak: 470 rows from `2026-04-18T08:38:08` through `2026-04-20T02:57:20`.
- Other same-error streaks reached 352, 246, 154, 151, 88, 86, 74, 64, and 63 rows.
- Law 7 threshold is 3+ consecutive appearances of the same error string.

Impact: repeated known-unavailable Gmail credential checks should have been represented as a deduped blocker with an explicit retry policy. Re-emitting hundreds of skipped rows makes the audit ledger noisier and hides whether CI failure detection was available through other local or GitHub-native channels.

### WARNING-4: Daily note variant churn prevents stable blocker grouping

Evidence:
- The 2,089 email rows contain 273 distinct `notes` strings.
- Daily note variants reached 71 on 2026-04-21 and 68 on 2026-04-17.
- The same underlying credential problem appears as `Gmail query failed`, `GitHub failure email query unavailable`, `Daniel-Google MCP unavailable`, and `GitHub notifications Gmail check blocked`.

Impact: the repeated blocker is semantically identical, but the note wording changes too often for exact-string dedupe. Historical queries need a normalized `error_key`, such as `missing_marta_google_credentials`, rather than grouping by prose.

### INFO-5: Structured evidence columns are empty for all email-check rows

Evidence:
- `EMAIL%` rows with empty `error_msg`: 2,089.
- `EMAIL%` rows with empty `validation_cmd`: 2,089.
- `EMAIL%` rows with empty `validation_result`: 2,089.
- `EMAIL%` rows with null `duration_sec`: 2,089.

Impact: the data needed for automated suppression, retry cadence, and credential-blocker trend reporting exists only in prose. Filling `error_msg` and a normalized blocker key would make this drift queryable without text scraping.

## Key Aggregates

| Metric | Count |
| --- | ---: |
| Sanhedrin rows | 11,687 |
| Email-check rows | 2,089 |
| Email-check skipped rows | 2,089 |
| Missing-credential rows | 2,048 |
| Distinct email-check note variants | 273 |

| Day | Email Rows | Missing-Cred Rows | Note Variants |
| --- | ---: | ---: | ---: |
| 2026-04-13 | 59 | 58 | 20 |
| 2026-04-15 | 49 | 49 | 18 |
| 2026-04-16 | 106 | 103 | 24 |
| 2026-04-17 | 208 | 206 | 68 |
| 2026-04-18 | 244 | 237 | 35 |
| 2026-04-19 | 255 | 255 | 12 |
| 2026-04-20 | 463 | 455 | 34 |
| 2026-04-21 | 497 | 478 | 71 |
| 2026-04-22 | 111 | 111 | 17 |
| 2026-04-23 | 96 | 95 | 5 |

## Recommendations

- Add `error_key = missing_marta_google_credentials` for these checks and suppress repeats after the Law 7 threshold.
- Treat Gmail/MCP notification checks as optional host-side telemetry; do not let them dominate the compliance ledger when credentials are absent.
- Prefer local DB, local audit artifacts, and GitHub run metadata already available in CI monitoring over Gmail polling for core Law evidence.
- Populate `error_msg`, `validation_cmd`, `validation_result`, and retry/suppression state for skipped remote-service checks.

## Read-Only Verification Command

```bash
sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-02-email-check-credential-skip-saturation.sql
```

Finding count: 5 total, 4 warnings and 1 info.
