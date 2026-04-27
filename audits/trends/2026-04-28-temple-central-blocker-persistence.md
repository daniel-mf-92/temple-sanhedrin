# Temple Central Blocker Persistence Trend Audit

Timestamp: 2026-04-28T01:32:54+02:00

Scope: Historical drift trends from `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`, focused on repeated Sanhedrin blocker motifs and failure normalization. This audit did not inspect or modify live loops, did not run VM/QEMU commands, and did not touch TempleOS or holyc-inference source code.

SQL used: `audits/trends/2026-04-28-temple-central-blocker-persistence.sql`

## Source Coverage

| Source | Value |
| --- | ---: |
| Sanhedrin iteration rows | 11,687 |
| Sanhedrin pass rows | 8,850 |
| Sanhedrin fail rows | 94 |
| Sanhedrin blocked rows | 3 |
| Sanhedrin skip rows | 2,740 |
| Sanhedrin ISO timestamp window | 2026-04-12T19:07:45 through 2026-04-23T11:54:59 |
| `violations` rows | 0 |
| Non-ISO iteration timestamps | 14 |

## Findings

### 1. CRITICAL: Repeated Sanhedrin failures are not normalized into `violations`

The `iterations` stream records 94 Sanhedrin `fail` rows and 3 `blocked` rows, but the `violations` table has 0 rows. The largest failed/blocked groups are `CI-TEMPLEOS` with 43 failures, `AUDIT` with 31 failures, `VM-COMPILE` with 10 failures plus 3 blocked rows, `VM-CHECK` with 5 failures, and `LAW-CHECK` with 3 failures.

Impact: any historical compliance dashboard keyed to `violations` reports a clean record while the audit stream itself records repeated failure states.

### 2. CRITICAL: Missing Google/MCP credentials became a long-running blocker motif

The Sanhedrin stream contains 2,054 rows classified as missing `MARTA_GOOGLE_CLIENT_ID` or `MARTA_GOOGLE_CLIENT_SECRET`. The longest contiguous streak found by timestamp/id order is 122 rows from 2026-04-19T17:26:41 through 2026-04-20T01:09:11.

Impact: this satisfies the spirit of the blocker-escalation law for repeated error strings, but the DB has no structured blocker/escalation table tying the repeated auth failure to resolution state.

### 3. WARNING: Historical CI failures were re-reported far beyond their first observation

The TempleOS CI run `24308638070` appears in 203 Sanhedrin fail/skip rows between 2026-04-12 and 2026-04-17. The direct `CI-TEMPLEOS` failure group alone contributes 43 fail rows between 2026-04-16T18:00:14 and 2026-04-17T00:07:36.

Impact: repeated reporting of the same historical CI run can inflate apparent active failure counts unless trend consumers collapse known historical run IDs into a single incident with first-seen/last-seen timestamps.

### 4. WARNING: VM compile/check blockers use sentinel values instead of typed causes

`VM-COMPILE` has 10 failures and 3 blocked rows from 2026-04-18T15:46:45 through 2026-04-20T20:56:49. Related notes include `fail_count=-1`, `non-pass=-1`, `fail_count=unknown`, `ssh/auth timeout`, and a sqlite schema error, but the DB stores these only as free text.

Impact: Law 7 backfills have to parse prose to distinguish infrastructure/auth failures from actual guest compile failures. This weakens historical evidence quality while keeping the TempleOS guest air-gapped.

### 5. WARNING: Timestamp quality can distort long-window blocker streaks

There are 14 non-ISO timestamps in `iterations`, including space-separated values and epoch-like values. This is small relative to 11,687 Sanhedrin rows, but it affects lexical ordering, day buckets, and consecutive-streak calculations.

Impact: historical drift trend scripts need timestamp normalization before reporting blocker duration or same-error streak length.

## Daily Failure/Blocker Shape

| Day | Fail | Blocked | Skip |
| --- | ---: | ---: | ---: |
| 2026-04-13 | 3 | 0 | 149 |
| 2026-04-16 | 42 | 0 | 236 |
| 2026-04-17 | 9 | 0 | 415 |
| 2026-04-18 | 5 | 0 | 325 |
| 2026-04-19 | 1 | 0 | 258 |
| 2026-04-20 | 10 | 3 | 470 |
| 2026-04-21 | 15 | 0 | 506 |
| 2026-04-22 | 9 | 0 | 120 |
| 2026-04-23 | 0 | 0 | 96 |

The peak skip volume appears on 2026-04-21, while the peak fail volume appears on 2026-04-16 and is dominated by historical TempleOS CI reporting.

## Recommendations

- Add a structured `blockers` or `incidents` table with blocker key, first seen, last seen, count, resolution state, and linked law.
- Normalize Sanhedrin `fail`/`blocked` rows into `violations` or explicitly mark them non-law infrastructure incidents.
- Collapse repeated external run IDs such as `24308638070` before computing active failure trend counts.
- Replace VM sentinel values like `-1`, `999`, and `unknown` with typed causes such as `ssh_auth_timeout`, `schema_mismatch`, `no_rows`, or `guest_compile_failure`.
- Normalize timestamps at insert time and reject non-ISO rows.
