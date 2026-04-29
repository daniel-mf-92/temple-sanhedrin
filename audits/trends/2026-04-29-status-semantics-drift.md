# temple-central.db Status-Semantics Drift Audit

Audit timestamp: 2026-04-29T10:33:02+02:00

Audit angle: historical drift trends. This pass queried `temple-central.db` read-only for builder iteration status semantics, then wrote this report and its query pack in the Sanhedrin repo only.

## Scope

- Database: `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`
- Rows: `iterations` rows for `modernization` and `inference`
- Window: 2026-04-12T13:51:32 through 2026-04-23T12:06:44
- Query pack: `audits/trends/2026-04-29-status-semantics-drift.sql`
- LAWS.md focus: Law 2 air-gap evidence, Law 5 meaningful validation evidence, and Law 7 blocker/skip visibility.

No trinity source files were modified. No QEMU or VM command was executed.

## Summary

The historical builder rows use `status = pass` for every modernization and inference iteration, even though the table schema supports `fail`, `skip`, and `blocked`. This makes the central DB status column unsuitable for long-window compliance analysis unless auditors re-parse free-text validation fields.

## Findings

1. **WARNING - Builder status collapsed to pass across 2,919 / 2,919 rows.**
   Evidence: modernization has 1,505 `pass` rows and 0 non-pass rows; inference has 1,414 `pass` rows and 0 non-pass rows. The schema permits `fail`, `skip`, and `blocked`, but the historical builder window does not use them.

2. **WARNING - Modernization pass rows include 140 QEMU-skip signals.**
   Evidence: 140 modernization rows have `status = pass` while `validation_result` or `notes` contains QEMU skip wording. This weakens Law 2 auditability because the pass bit cannot distinguish "guest compile/boot ran with `-nic none`" from "host-side smoke or wrapper ran while QEMU was skipped."

3. **WARNING - Modernization pass rows include 136 ISO unavailable/blocked signals.**
   Evidence: 136 modernization rows have `status = pass` while `validation_result` or `notes` says the ISO was unavailable, download-blocked, or fetch-unavailable. These are reasonable air-gap-preserving outcomes, but they should be statused or classified separately from full validation passes.

4. **WARNING - Queue-health uncertainty is hidden inside pass rows.**
   Evidence: 158 modernization pass rows and 72 inference pass rows contain `queue remains unchecked` or `queue depth unchecked` wording. Law 6 queue health and Law 5 progress analysis cannot rely on `status` alone to identify partial validation.

5. **INFO - Free-text keyword scans produce false positives without structured status fields.**
   Evidence: inference has 6 pass rows with `skip` terms, but current samples are GGUF metadata value-skip implementation work with normal passing tests, not skipped validation. This reinforces the need for first-class status detail rather than broader keyword scanners.

## Daily Shape

| Day | Agent | Rows | Non-pass rows | Pass rows with skip signal | Pass rows with ISO unavailable/blocked |
| --- | --- | ---: | ---: | ---: | ---: |
| 2026-04-12 | inference | 64 | 0 | 0 | 0 |
| 2026-04-12 | modernization | 85 | 0 | 24 | 17 |
| 2026-04-13 | inference | 68 | 0 | 0 | 0 |
| 2026-04-13 | modernization | 137 | 0 | 55 | 38 |
| 2026-04-15 | inference | 35 | 0 | 0 | 0 |
| 2026-04-15 | modernization | 31 | 0 | 0 | 0 |
| 2026-04-16 | inference | 68 | 0 | 0 | 0 |
| 2026-04-16 | modernization | 68 | 0 | 0 | 0 |
| 2026-04-17 | inference | 157 | 0 | 0 | 0 |
| 2026-04-17 | modernization | 143 | 0 | 0 | 0 |
| 2026-04-18 | inference | 152 | 0 | 0 | 0 |
| 2026-04-18 | modernization | 146 | 0 | 1 | 1 |
| 2026-04-19 | inference | 164 | 0 | 0 | 0 |
| 2026-04-19 | modernization | 142 | 0 | 19 | 13 |
| 2026-04-20 | inference | 202 | 0 | 0 | 0 |
| 2026-04-20 | modernization | 225 | 0 | 28 | 8 |
| 2026-04-21 | inference | 219 | 0 | 0 | 0 |
| 2026-04-21 | modernization | 248 | 0 | 47 | 41 |
| 2026-04-22 | inference | 224 | 0 | 2 | 0 |
| 2026-04-22 | modernization | 246 | 0 | 24 | 18 |
| 2026-04-23 | inference | 61 | 0 | 4 | 0 |
| 2026-04-23 | modernization | 34 | 0 | 0 | 0 |

## Representative Rows

| Agent | Timestamp | Task | Status | Evidence |
| --- | --- | --- | --- | --- |
| modernization | 2026-04-22T11:41:11 | CQ-1229 | pass | `exit 0 (QEMU compile skipped: ISO download unavailable on air-gapped host)` |
| modernization | 2026-04-22T10:16:34 | CQ-1214 | pass | `exit 0 (QEMU stage skipped: ISO download unavailable)` |
| modernization | 2026-04-22T07:19:34 | CQ-1186/CQ-1187 | pass | `exit 0 (smoke pass; qemu compile skipped due to ISO fetch unavailable)` |
| inference | 2026-04-23T08:14:13 | IQ-1250 | pass | `Added ParityCommitOnly metadata skip wrapper...` |
| inference | 2026-04-23T07:36:31 | IQ-1247 | pass | `Commit-only metadata value skip wrapper...` |

## Recommendations

- Populate `status = skip` when the guest/QEMU validation stage is skipped, even if smoke tests pass.
- Add a separate structured field such as `validation_scope` with values like `full-guest`, `host-smoke-only`, `qemu-skipped-airgap`, `fixture-replay`, and `not-run`.
- Add a structured `queue_checked` boolean so Law 6 evidence does not depend on prose parsing.
- Keep `status = pass` reserved for rows whose required validation scope actually ran and passed.

Finding count: 5 total, 4 warnings and 1 info.
