# Validation Shell-Control Drift Audit

Audit timestamp: 2026-04-29T18:24:25+02:00

Audit angle: historical drift trends. This pass queried `temple-central.db` read-only and scanned builder `validation_cmd` text for unquoted shell control operators that can make stored validation evidence ambiguous. No TempleOS or holyc-inference source files were modified. No QEMU, VM, SSH, package-manager, network, or WS8 command was executed.

## Scope

- Database: `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`
- Rows: 2,919 builder rows, limited to `agent IN ('modernization', 'inference')`
- Window: 2026-04-12T13:51:32 through 2026-04-23T12:06:44
- Analyzer: `audits/trends/2026-04-29-validation-shell-control-drift.py`
- LAWS.md focus: Law 5 meaningful validation evidence, Law 7 blocker/escalation evidence quality, and Law 2 air-gap auditability for validation commands

## Summary

The historical DB stores complete builder validation commands, but a small set uses shell operators in a way that weakens proof quality. The exact scanner found 6 rows with unquoted `|` and 11 rows with unquoted `;`. All 6 pipeline rows lack `pipefail`, so a left-side validation failure can be hidden by a successful right-side command. Several semicolon rows combine validation phases without short-circuit semantics, which means later checks can run after earlier checks fail unless the invoked script exits are inspected separately.

Finding count: 5 total, 4 warnings and 1 info.

## Findings

1. **WARNING - Six builder validation rows contain unquoted shell pipelines with no `pipefail`.**
   Evidence: 5 modernization rows and 1 inference row contain an unquoted `|`; all 6 lack `pipefail`. Examples include `CQ-088` with `rg -n BookOfTruth|BookTruth ...`, `IQ-016` with `rg ... | wc -l`, and `CQ-1217` with `rg -n ReplayWindowDelta\\(|DigestReplayWindowDelta\\(...`.

2. **WARNING - Some pipeline rows are malformed enough to make the recorded pass evidence suspect.**
   Evidence: `CQ-088` treats `BookTruth` as a command name, not a regex branch, because the alternation is unquoted. `CQ-119` contains two unquoted pipes around a `bash -n ...` fragment, so the stored command is not a simple "grep for token and run scripts" validation chain.

3. **WARNING - Eleven builder validation rows use unquoted semicolon separators.**
   Evidence: 8 modernization rows and 3 inference rows contain unquoted `;`. Examples include `CQ-089`, `CQ-094`, `CQ-108`, `IQ-528`, `IQ-1030`, and `IQ-1166`. Semicolon separation records multiple checks as one pass row without proving every earlier command controlled the final exit status.

4. **WARNING - The drift intersects Law 2 / Law 11 evidence surfaces.**
   Evidence: modernization rows with semicolons include Book-of-Truth and QEMU validation commands, including `CQ-769`, which combines a local compile command and an SSH compile fallback separated by `;`. This does not prove guest networking was enabled, but it makes historical air-gap and local-access scoring depend on free-text command parsing.

5. **INFO - The issue is small and backfillable.**
   Evidence: only 17 distinct builder rows are affected by unquoted pipe or semicolon operators out of 2,919 builder rows. Most validation commands use `&&`, and quoted or escaped regex alternation was excluded by the analyzer.

## Supporting Extracts

| Metric | Count |
| --- | ---: |
| Builder rows scanned | 2,919 |
| Rows with unquoted `|` | 6 |
| Pipeline rows without `pipefail` | 6 |
| Rows with unquoted `;` | 11 |
| Modernization pipeline rows | 5 |
| Inference pipeline rows | 1 |
| Modernization semicolon rows | 8 |
| Inference semicolon rows | 3 |

Pipeline rows:

| ID | Timestamp | Agent | Task | Notes |
| ---: | --- | --- | --- | --- |
| 1 | 2026-04-12T13:51:32 | modernization | CQ-088 | Unquoted regex alternation becomes a shell pipeline. |
| 74 | 2026-04-12T17:20:03 | modernization | CQ-113 | Multiple unquoted pipes in a long Book-of-Truth validation command. |
| 402 | 2026-04-13T04:45:40 | modernization | CQ-228 | Unquoted Book-of-Truth counter alternation. |
| 453 | 2026-04-13T06:11:36 | inference | IQ-016 | `rg ... | wc -l` count pipeline without `pipefail`. |
| 740 | 2026-04-15T16:45:23 | modernization | CQ-119 | Unquoted pipe crosses `rg`, `bash -n`, and `automation/* --help`. |
| 13927 | 2026-04-22T10:24:53 | modernization | CQ-1217 | Escaped paren regex still leaves an unquoted shell pipe between alternatives. |

Semicolon rows:

| ID | Timestamp | Agent | Task |
| ---: | --- | --- | --- |
| 5 | 2026-04-12T13:59:16 | modernization | CQ-089 |
| 21 | 2026-04-12T14:40:15 | modernization | CQ-094 |
| 63 | 2026-04-12T16:45:18 | modernization | CQ-108 |
| 111 | 2026-04-12T18:56:29 | modernization | CQ-126 |
| 3158 | 2026-04-17T20:38:25 | modernization | CQ-345 |
| 5727 | 2026-04-19T13:43:10 | inference | IQ-528 |
| 6159 | 2026-04-19T20:16:27 | modernization | CQ-620/CQ-621 |
| 8062 | 2026-04-20T13:16:50 | modernization | CQ-769 |
| 13228 | 2026-04-22T02:43:35 | inference | IQ-1030 |
| 13871 | 2026-04-22T09:35:08 | modernization | CQ-1301/CQ-1302 |
| 14082 | 2026-04-22T15:50:44 | inference | IQ-1166 |

## Recommendations

- Store future validation as structured command arrays with per-step exit codes, rather than one shell string.
- Reject unquoted `|` in validation text unless the command also records `set -o pipefail` or an equivalent per-stage status.
- Prefer `&&` between validation phases when a later check depends on an earlier one succeeding.
- Add a derived `validation_control_ops` field to historical backfills so trend reports can discount ambiguous pass rows.

## Reproduction

```bash
python3 audits/trends/2026-04-29-validation-shell-control-drift.py
```
