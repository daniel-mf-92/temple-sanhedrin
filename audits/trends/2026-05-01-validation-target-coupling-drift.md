# temple-central.db Validation Target Coupling Drift

Audit timestamp: 2026-05-01T10:30:45+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for whether changed files in builder rows can be joined back to the exact validation targets recorded in `validation_cmd`. It did not inspect live liveness, restart processes, run QEMU or VM commands, run SSH, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

Evidence snapshots:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `68bcfa8b3a8d`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554`
- Sanhedrin audit repo: `/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55` at `3b24a264cb7b`
- SQL: `audits/trends/2026-05-01-validation-target-coupling-drift.sql`

## Summary

The central ledger is mostly usable for coarse validation evidence, but it is not consistently strong enough for file-level replay. Inference changed test files in 1,278 rows; 15 of those rows do not preserve the exact changed test path in `validation_cmd`. Modernization has a different shape: all 750 rows that touch core HolyC paths have no `tests/` path by design, and 506 of those rows also have no automation path in `files_changed`, so their proof depends on free-text command strings and wrapper semantics rather than a normalized changed-file to validation-target join.

Findings: 5 total.

## Findings

### WARNING-1: Inference has changed test files whose exact targets are not recorded in validation commands

Evidence:
- Inference builder rows: 1,414.
- Rows with changed test paths: 1,278.
- Rows where at least one changed test path is absent from `validation_cmd`: 15.
- Recent examples include `IQ-983`, `IQ-963`, `IQ-878`, and `IQ-857`.

Impact: these are not automatic Law 1 or Law 4 violations, and many rows still ran adjacent tests or pytest. The drift is evidentiary: a future audit cannot prove from the DB alone that the exact changed test artifact was executed.

### WARNING-2: Generated and non-source test artifacts contaminate test-target joins

Evidence:
- Inference has 3 rows whose `files_changed` includes `__pycache__` or `.pyc`.
- Examples include `IQ-878`, `IQ-857`, and `IQ-555`.
- One inference row and one modernization row also store absolute `/Users/...` paths in `files_changed`.

Impact: generated cache files and machine-local absolute paths are poor historical join keys. They can make a validation target look missing even when the intended source test was run, and they weaken repeatability across machines.

### WARNING-3: Modernization core HolyC rows rely on command text rather than test-path linkage

Evidence:
- Modernization rows touching core HolyC paths: 750.
- Modernization core rows with no test path in `files_changed`: 750.
- Modernization core rows with neither test path nor automation path in `files_changed`: 506.
- Recent examples are Book-of-Truth and scheduler rows such as `CQ-1351/CQ-1352`, `CQ-1350`, `CQ-1348`, `CQ-1344`, and `CQ-1340/CQ-1341/CQ-1342/CQ-1343`.

Impact: this is expected for TempleOS because validation is usually through HolyC compile, replay-smoke, and QEMU wrappers rather than Python tests. The audit risk is that file-level proof must be reconstructed from command prose such as `qemu-compile-test.sh Kernel/BookOfTruth.HC Kernel/KExts.HC`, not from a structured validation-target table.

### WARNING-4: Command redaction intersects with target-coupling evidence

Evidence:
- Inference has 8 rows with literal `...` in `validation_cmd`.
- Modernization has 5 rows with literal `...` in `validation_cmd`.
- The latest modernization example in this query is `CQ-1340/CQ-1341/CQ-1342/CQ-1343`, whose command begins with abbreviated automation script names.

Impact: even sparse redaction matters because target-coupling is a string-level proof. Once the command is abbreviated, a historical auditor cannot distinguish exact target coverage from summarized intent.

### INFO-5: The drift is backfillable without touching builder repos

Evidence:
- The SQL normalizes comma and semicolon delimiters in `files_changed`.
- It classifies changed test paths, core HolyC paths, automation paths, QEMU mentions, pytest mentions, shell syntax checks, and command ellipses from existing DB text.
- No TempleOS or holyc-inference source writes are required to derive the affected row sets.

Impact: a derived read-only table such as `iteration_validation_targets(iteration_id, changed_path, target_path, target_kind, target_match_status)` would preserve historical ambiguity explicitly and make future Law 5 / Law 6 scoring less dependent on prose parsing.

## Key Aggregates

| Agent | Rows | Rows With Tests | Test-Target Elision Rows | Rows With Core HolyC | Core Rows Without Test Paths | Core Rows Without Test Or Automation Paths | Command Ellipsis Rows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| inference | 1,414 | 1,278 | 15 | 1,225 | 86 | 85 | 8 |
| modernization | 1,505 | 0 | 0 | 750 | 750 | 506 | 5 |

| Agent | Rows With `__pycache__` / `.pyc` | Rows With Absolute `/Users/...` Paths |
| --- | ---: | ---: |
| inference | 3 | 1 |
| modernization | 0 | 1 |

## Recommendations

- Store normalized validation targets separately from free-text `validation_cmd`.
- Reject generated cache files such as `__pycache__` and `.pyc` from future `files_changed` ingestion.
- Store repo-relative paths only; absolute workstation paths should be normalized before DB insert.
- Preserve exact command argv for QEMU, pytest, shell syntax, and replay-smoke phases; do not abbreviate with `...`.

## Read-Only Verification Command

```bash
sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-validation-target-coupling-drift.sql
```

Finding count: 5 total, 4 warnings and 1 info.
