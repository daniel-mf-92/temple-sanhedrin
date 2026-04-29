# Historical Law-Register / Violation-Sink Drift Audit

Timestamp: 2026-04-29T22:43:17+02:00

Audit angle: historical drift trends.

Scope:
- `temple-central.db` law registry, violation sink, and Sanhedrin audit rows.
- Current `LAWS.md` law headings in the sanhedrin repo.
- Existing sanhedrin audit artifacts under `audits/`.

No TempleOS or holyc-inference source files were modified. No QEMU/VM command, SSH command, WS8 networking task, socket, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, or package-network action was executed.

Evidence snapshots:
- Sanhedrin repo: `5f7dba9ccfc7d4dc7f5200a6644df53e0f67763c`
- TempleOS repo: `00d1bdcd92c1af0b5c10b5ccc25cc1503f98937e`
- holyc-inference repo: `485af0ea41a239c8393542d6e0e2fc5944f30f53`
- SQL: `audits/trends/2026-04-29-law-register-violation-sink-drift.sql`

## Summary

`temple-central.db` is not a reliable long-window violation ledger for the current law set. The database has 14,606 iteration rows and 2,823 Sanhedrin `AUDIT` rows, but the `violations` table is empty. Separately, `LAWS.md` reuses Law 4, Law 5, Law 6, and Law 7 for appended rules, while the database `laws` table still stores only the original meanings. That makes central historical scoring undercount real findings and misclassify reused law numbers.

## Findings

1. **WARNING - Central violation sink is empty despite substantial audit findings.**
   Evidence: `SELECT COUNT(*) FROM violations` returns 0. Existing markdown audits under `audits/retro` include 504 reports, 188 files with critical wording, and 178 files with warning wording; all `audits/` files include 320 critical-bearing files and 310 warning-bearing files. The central DB therefore cannot be used as the sole source for retroactive compliance counts.

2. **WARNING - `laws` table does not represent the current LAWS.md rule set.**
   Evidence: DB law id 4 is only `Integer Purity`, id 5 only `No Busywork`, id 6 only `Queue Health`, and id 7 only `Process Liveness`. Current `LAWS.md` also defines Law 4 as `Identifier Compounding Ban`, Law 5 as `North Star Discipline`, Law 6 as `No Self-Generated Queue Items`, and Law 7 as `Blocker Escalation`. Findings recorded by number alone cannot be joined safely to the database law table.

3. **WARNING - Sanhedrin audit rows encode severity in free text instead of normalized violations.**
   Evidence: DB has 2,823 Sanhedrin `AUDIT` rows; 1,198 contain `Severity=` or `severity=` text, but none materialize into `violations`. Many rows also pack law checks into `notes` strings such as `law4_float_hits`, `law6_open_cq`, and `no_critical_violations`, which are not queryable as normalized rule outcomes.

4. **WARNING - Historical dashboards can falsely report zero violations.**
   Evidence: all 11 DB law rows have `violation_rows = 0`, while retro markdown reports already document concrete Law 4 identifier-compounding violations, Law 6 self-generated queue item violations, and warnings. Any dashboard based only on `laws LEFT JOIN violations` would show every law clean.

5. **INFO - Builder iteration rows are present and complete enough to backfill normalized outcomes.**
   Evidence: builder rows exist for 1,505 modernization iterations and 1,414 inference iterations, all with non-empty validation commands and notes. The gap is not missing iteration telemetry; it is the absence of a canonical law/outcome schema and violation insertion path.

## Source Counts

| Metric | Count |
| --- | ---: |
| Total DB iteration rows | 14,606 |
| Builder iteration rows | 2,919 |
| Sanhedrin iteration rows | 11,687 |
| Sanhedrin `AUDIT` rows | 2,823 |
| Sanhedrin `AUDIT` rows with severity text | 1,198 |
| DB violation rows | 0 |
| `audits/retro` markdown reports | 504 |
| `audits/retro` files with critical wording | 188 |
| `audits/retro` files with warning wording | 178 |

## Recommendations

- Split reused law numbers into canonical IDs, for example `LAW-4A-integer-purity` and `LAW-4B-identifier-compounding`, or renumber appended laws without reuse.
- Add a normalized audit outcome table keyed by `iteration_id`, `repo`, `commit_sha`, `law_key`, `severity`, `evidence_path`, and `resolved`.
- Backfill `violations` or the replacement outcome table from existing `audits/retro/*.md` reports before using `temple-central.db` for compliance scores.
- Require future Sanhedrin rows to write structured rule outcomes, with free-text `notes` kept only as supplemental context.
