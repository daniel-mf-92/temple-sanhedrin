# temple-central.db Validation Command Redaction Drift

Timestamp: 2026-04-30T09:21:43+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for builder validation commands that were stored with literal `...` redaction or abbreviation. It did not inspect live loop liveness, restart anything, run QEMU/VM commands, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code.

SQL: `audits/trends/2026-04-30-validation-command-redaction-drift.sql`

## Summary

The historical builder ledger has complete validation command/result fields for 2,919 pass rows, but 13 validation commands contain literal `...` placeholders. The affected rows are sparse, yet they land in exactly the places later audits need precision: three modernization rows mention QEMU with abbreviated command paths, one also includes SSH remote validation, and all eight inference rows are abbreviated Python heredoc checks. That makes strict replay, Law 2 air-gap proof review, and Law 7 blocker recurrence analysis depend on partial command prose instead of exact historical commands.

Findings: 5 total.

## Findings

### WARNING-1: Thirteen builder pass rows store abbreviated validation commands

Evidence:
- Modernization: 5 of 1,505 builder rows contain `...` in `validation_cmd`.
- Inference: 8 of 1,414 builder rows contain `...` in `validation_cmd`.
- Both builder streams have only pass rows in this DB window, so every abbreviated command is recorded as a successful iteration.

Impact: a later auditor cannot reconstruct the exact validation invocation from `temple-central.db` alone for those rows. The problem is small in count but high in evidentiary cost because the ledger is supposed to preserve the validation trail.

### WARNING-2: Three abbreviated modernization rows involve QEMU validation surfaces

Evidence:
- Modernization redacted QEMU rows: 3.
- Redacted QEMU rows appear on 2026-04-22 and 2026-04-23.
- Example shape: `bash -n automation/...band-smoke.sh automation/...digest-matrix-smoke.sh ... && TIMEOUT_SEC=240 bash automation/qemu-compile-test.sh ...`

Impact: Law 2 and immutable-image backfills need exact QEMU command surfaces to confirm `-nic none`, `-net none`, and read-only image handling. Abbreviated pre-command and wrapper segments force the audit to re-read git history or shell scripts instead of trusting the DB record.

### WARNING-3: One abbreviated modernization row includes remote SSH validation

Evidence:
- `CQ-1340/CQ-1341/CQ-1342/CQ-1343` at `2026-04-23T08:56:35` contains both `...` and `ssh azureuser@52.157.85.234`.
- Its stored command abbreviates local script names and an intermediate fixture invocation before the remote compile step.

Impact: this does not prove a Law 2 violation by itself, but it weakens auditability of a high-risk validation shape. Remote host validation and QEMU validation should preserve the exact local and remote commands, especially where air-gap and `-nic none` evidence are required.

### WARNING-4: All inference abbreviations are Python heredoc checks

Evidence:
- Inference redacted heredoc rows: 8.
- Affected days: 2026-04-13, 2026-04-15, 2026-04-16, and 2026-04-17.
- Example shapes include `python3 - <<'PY' ... PY` and inline reference-check markers.

Impact: these are host-side tests, so they do not violate HolyC runtime purity by themselves. They do, however, hide the exact assertions used to validate integer math and GGUF fixture contracts, which weakens Law 4 retroactive proof.

### INFO-5: The issue is redaction, not general field absence

Evidence:
- Builder row counts: 1,505 modernization and 1,414 inference.
- Non-pass builder rows in this DB window: 0 for both agents.
- Long commands are common: 993 modernization rows and 657 inference rows have `validation_cmd` length at least 250 characters, while only 13 total rows use `...`.

Impact: the schema can store long commands, so the fix is not merely increasing a column size. The insertion path should avoid manual abbreviation and store exact commands plus optional display summaries separately.

## Source Counts

| Metric | Modernization | Inference |
| --- | ---: | ---: |
| Builder rows | 1,505 | 1,414 |
| Redacted command rows | 5 | 8 |
| Redacted QEMU rows | 3 | 0 |
| Redacted SSH rows | 1 | 0 |
| Redacted Python heredoc rows | 0 | 8 |
| Commands >= 250 chars | 993 | 657 |
| Max command length | 1,353 | 1,010 |

## Redaction Timeline

| Day | Agent | Rows | QEMU | SSH | Heredoc |
| --- | --- | ---: | ---: | ---: | ---: |
| 2026-04-13 | inference | 1 | 0 | 0 | 1 |
| 2026-04-15 | inference | 1 | 0 | 0 | 1 |
| 2026-04-16 | inference | 2 | 0 | 0 | 2 |
| 2026-04-17 | inference | 4 | 0 | 0 | 4 |
| 2026-04-17 | modernization | 1 | 0 | 0 | 0 |
| 2026-04-21 | modernization | 1 | 0 | 0 | 0 |
| 2026-04-22 | modernization | 2 | 2 | 0 | 0 |
| 2026-04-23 | modernization | 1 | 1 | 1 | 0 |

## Recommendations

- Store exact `validation_cmd` text without `...`; add a separate `validation_cmd_summary` for dashboard display.
- Add a Sanhedrin DB guard that rejects or warns on literal `...` in `validation_cmd`, `files_changed`, or `validation_result`.
- For QEMU rows, store parsed booleans such as `qemu_command_seen`, `nic_none_seen`, `net_none_seen`, `readonly_drive_seen`, and `remote_validation_seen`.
- For heredoc validation, store either the exact heredoc body or a hash plus artifact path so integer-math and parser-contract checks remain replayable.

## Read-Only Verification Commands

```bash
sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-30-validation-command-redaction-drift.sql
sqlite3 /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db '.schema iterations'
```
