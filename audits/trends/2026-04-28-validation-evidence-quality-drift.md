# Temple Central Validation Evidence Quality Trend Audit

Timestamp: 2026-04-28T04:45:52Z

Scope: Historical drift trend audit from `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`, focused on stored validation command/result quality for the modernization and inference builder loops. This audit did not inspect live liveness, did not run VM/QEMU commands, did not modify TempleOS or holyc-inference source code, and preserved the guest air-gap.

SQL used: `audits/trends/2026-04-28-validation-evidence-quality-drift.sql`

## Source Coverage

| Source | Rows | First timestamp | Last timestamp | Lines added | Lines removed |
| --- | ---: | --- | --- | ---: | ---: |
| modernization iterations | 1,505 | 2026-04-12T13:51:32 | 2026-04-23T12:01:29 | 322,560 | 373 |
| inference iterations | 1,414 | 2026-04-12T13:53:13 | 2026-04-23T12:06:44 | 390,043 | 294 |

Both builder streams contain only `pass` rows in this historical window. There were no missing `validation_cmd` or `validation_result` fields in either builder stream.

## Findings

### 1. WARNING: Modernization validation results are mostly generic `exit 0`

Modernization has 1,391 generic `exit 0` validation results out of 1,505 rows, or 92.43% of its historical builder records. Only 1 modernization row, 0.07%, was classified as specific pass evidence containing a concrete passed/checks token and no skipped/unavailable marker.

Impact: historical dashboards can prove that a command exited successfully, but they usually cannot distinguish syntax-only validation, fixture replay, QEMU launch validation, compile validation, Book-of-Truth replay validation, or air-gap guard validation from the stored result field alone.

### 2. WARNING: QEMU-command rows include successful records where QEMU was skipped

Modernization has 1,153 rows whose validation command mentions QEMU. Of those, 109 rows were stored as successful pass iterations while the validation result says the QEMU stage, compile stage, ISO download, or boot stage was skipped or unavailable.

Impact: the skip is consistent with air-gap safety and no VM was run by this audit, but the database does not separate `pass_with_vm_execution` from `pass_without_vm_execution`. Historical trend consumers can overstate guest-executed validation coverage.

### 3. WARNING: Skip evidence is fragmented across many free-text variants

The 109 modernization QEMU skip rows use 85 distinct `validation_result` strings. The most common variants are `exit 0 (ISO download skipped on air-gapped host)` with 6 rows, `exit 0 (qemu compile skipped: ISO unavailable)` with 5 rows, and `exit 0 (ISO unavailable => compile harness skipped QEMU)` with 4 rows.

Impact: Law 2/Law 7 backfills must normalize many phrases for the same evidence class. That makes repeated blocker detection and coverage scoring fragile, especially when the same air-gap-safe ISO unavailability condition appears under different prose.

### 4. WARNING: QEMU skip density persisted over multiple days

Daily modernization QEMU-command rows with skipped/unavailable outcomes peaked at 16.81% on 2026-04-13, 15.58% on 2026-04-12, 15.00% on 2026-04-21, 13.27% on 2026-04-19, and 11.98% on 2026-04-20.

Impact: this was not a one-off artifact. It was a recurring validation-evidence shape that should be represented as a typed validation mode rather than inferred from result prose after the fact.

### 5. INFO: Inference validation evidence is more specific but still mostly generic

Inference has 994 generic `ok` rows out of 1,414 rows, or 70.30%. It also has 410 rows, 29.00%, with more specific pass evidence such as `N passed` or named reference checks.

Impact: inference historical records are easier to segment than modernization records, but a majority still lack typed validation class, test count, or artifact identity in first-class DB columns.

## Daily Modernization QEMU Skip Shape

| Day | Rows | QEMU-command rows | QEMU skipped/unavailable |
| --- | ---: | ---: | ---: |
| 2026-04-12 | 85 | 77 | 12 |
| 2026-04-13 | 137 | 113 | 19 |
| 2026-04-15 | 31 | 21 | 0 |
| 2026-04-16 | 68 | 53 | 0 |
| 2026-04-17 | 143 | 89 | 0 |
| 2026-04-18 | 146 | 85 | 1 |
| 2026-04-19 | 142 | 98 | 13 |
| 2026-04-20 | 225 | 167 | 20 |
| 2026-04-21 | 248 | 200 | 30 |
| 2026-04-22 | 246 | 222 | 14 |
| 2026-04-23 | 34 | 28 | 0 |

## Recommendations

- Add typed validation columns: `validation_class`, `execution_mode`, `guest_executed`, `qemu_executed`, `airgap_mode`, and `artifact_refs`.
- Treat ISO-unavailable QEMU skips as air-gap-safe `pass_without_vm_execution`, not as the same evidence class as a guest compile pass.
- Normalize blocker/result causes at insert time with canonical values such as `iso_unavailable_airgap_skip`, `syntax_only_pass`, `fixture_replay_pass`, `guest_compile_pass`, and `host_policy_pass`.
- Keep the free-text result field, but make dashboards and backfills consume typed fields first.

## Read-Only Verification Commands

- `sqlite3 /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db '.schema iterations'`
- `sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-28-validation-evidence-quality-drift.sql`
- `git -C /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55 status --short --branch`
- `git -C /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55 status --short --branch`
