# temple-central.db Sanhedrin Law-Check Coverage Drift

Timestamp: 2026-04-30T03:29:41+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for Sanhedrin `AUDIT` row coverage of LAWS.md checks. It did not inspect live loop liveness, restart anything, run QEMU/VM commands, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code.

SQL: `audits/trends/2026-04-30-sanhedrin-law-check-coverage-drift.sql`

## Summary

The historical Sanhedrin audit ledger contains 2,823 `AUDIT` rows from 2026-04-12 through 2026-04-23, but its explicit law-number coverage is uneven. Notes frequently include Law 1, Law 2, Law 4, Law 5, and Law 6 checks, while Law 3 and Laws 7-11 do not appear by law number at all. Some of those missing laws are present only as semantic fragments such as `loops_alive`, `heartbeat`, `Book`, `serial`, `remote`, or `azure`, which makes long-window compliance scoring depend on fragile free-text inference rather than a normalized law-outcome record.

Findings: 5 total.

## Findings

### WARNING-1: Explicit Sanhedrin law-number coverage stops at a subset of laws

Evidence:
- `AUDIT` rows: 2,823.
- Explicit law-number mentions: Law 1 = 1,596 rows, Law 2 = 1,594, Law 4 = 1,605, Law 5 = 1,968, Law 6 = 1,617.
- Explicit Law 3, Law 7, Law 8, Law 9, Law 10, and Law 11 mentions: 0 rows each.

Impact: a DB-only trend consumer can conclude that high-risk laws were never checked, even when some related concepts appeared under other words.

### WARNING-2: Liveness was checked semantically but not mapped to Law 7

Evidence:
- 2,671 `AUDIT` rows mention queue or liveness terms such as `queue`, `heartbeat`, `loops_alive`, or `liveness`.
- 0 `AUDIT` rows mention `law7` or `Law 7`.

Impact: Law 7 trend reports must know every historical synonym for liveness instead of joining to a stable Law 7 outcome. That weakens blocker and stuck-loop backfills.

### WARNING-3: Book-of-Truth laws are underrepresented in audit-row keys

Evidence:
- 103 `AUDIT` rows mention Book-of-Truth or serial terms.
- 0 rows explicitly mention Law 3, Law 8, Law 9, Law 10, or Law 11.
- 0 rows mention immutable/read-only terms in the semantic bucket query.

Impact: Sanhedrin notes can contain local observations about serial or Book-of-Truth surfaces, but the DB does not preserve which Book-of-Truth law was checked. Law 3, 8, 9, 10, and 11 scoring therefore requires external markdown audits or custom text classifiers.

### WARNING-4: Severity normalization began late and remains partial

Evidence:
- 1,199 of 2,823 `AUDIT` rows contain `Severity=` or `severity:` text.
- Daily severity-key coverage is 0 rows from 2026-04-12 through 2026-04-17, then 11 rows on 2026-04-18, 241 on 2026-04-19, 331 on 2026-04-20, 2 on 2026-04-21, 503 on 2026-04-22, and 111 on 2026-04-23.

Impact: severity trends are not comparable across the full window. A drop in severity-key rows can mean a logging format change, not a safer system.

### INFO-5: The row set is complete enough for a conservative backfill

Evidence:
- All 2,823 `AUDIT` rows have non-empty notes.
- Normalized timestamp range is 2026-04-12T13:52:22 through 2026-04-23T11:54:59.
- Status distribution is 2,792 pass rows and 31 fail rows.

Impact: a backfill can derive provisional law-outcome rows from existing notes, but it should tag them as inferred and keep them separate from future structured checks.

## Source Counts

| Metric | Count |
| --- | ---: |
| Sanhedrin `AUDIT` rows | 2,823 |
| Pass rows | 2,792 |
| Fail rows | 31 |
| Rows with severity key | 1,199 |
| Law 1 keyed rows | 1,596 |
| Law 2 keyed rows | 1,594 |
| Law 3 keyed rows | 0 |
| Law 4 keyed rows | 1,605 |
| Law 5 keyed rows | 1,968 |
| Law 6 keyed rows | 1,617 |
| Law 7 keyed rows | 0 |
| Law 8 keyed rows | 0 |
| Law 9 keyed rows | 0 |
| Law 10 keyed rows | 0 |
| Law 11 keyed rows | 0 |

Semantic buckets:

| Bucket | Rows |
| --- | ---: |
| Queue or liveness | 2,671 |
| Air-gap or network | 1,772 |
| Local access or remote | 701 |
| Book-of-Truth or serial | 103 |
| Immutable or read-only | 0 |

## Recommendations

- Add `audit_law_outcomes(iteration_id, law_key, status, severity, evidence_key, evidence_text)` and populate one row per law per Sanhedrin audit cycle.
- Keep free-text `notes`, but make dashboards consume structured `law_key` rows first.
- Backfill Law 7 from `loops_alive`, `heartbeat`, and stuck-loop terms with `source=inferred`.
- Backfill Book-of-Truth laws separately: Law 3 from immutability/disable/delete terms, Law 8 from proximity/UART/synchronous terms, Law 9 from fail-stop/resource terms, Law 10 from read-only/immutable image terms, and Law 11 from local/remote serial terms.
- Treat pre-structured severity rows before 2026-04-18 as unknown severity rather than clean pass evidence unless the note contains an explicit severity token.

## Read-Only Verification Commands

```bash
sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-30-sanhedrin-law-check-coverage-drift.sql
sqlite3 /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db '.schema iterations'
```
