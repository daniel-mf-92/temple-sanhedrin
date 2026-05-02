# temple-central.db QEMU Wrapper Evidence Opacity Drift

Audit timestamp: 2026-05-02T08:26:34Z

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for long-window QEMU validation evidence shape in the modernization loop. It did not inspect live liveness, restart processes, run QEMU or VM commands, run SSH/SCP, execute WS8 networking tasks, modify TempleOS or holyc-inference source code, or write to the central database. The TempleOS guest air-gap was not touched.

SQL: `audits/trends/2026-05-02-qemu-wrapper-evidence-opacity-drift.sql`

Evidence snapshots:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `9f3abbf26398`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554`
- Sanhedrin audit repo before this artifact: `/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55` at `f39a55d`

## Summary

`temple-central.db` records 1,154 modernization rows whose command/result/notes mention QEMU, equal to 76.7% of all modernization rows in the snapshot. Those rows almost never preserve the final QEMU argv: there are zero direct `qemu-system` command rows, 1,152 wrapper-script rows, only 1 validation command with explicit `-nic none` / `-net none`, and zero validation commands with `readonly=on`. This is not evidence that QEMU was launched with networking or mutable OS images; it is evidence that the central historical ledger cannot independently score Law 2 or Law 10 from its own row data when validation is routed through wrappers.

Findings: 5 warning findings.

## Findings

### WARNING-1: QEMU validation is mostly wrapper evidence, not final argv evidence

Evidence:
- Modernization rows with QEMU evidence: 1,154.
- Direct `qemu-system` command rows: 0.
- `qemu-*` wrapper command rows: 1,152.
- Command rows with explicit `-nic none` or `-net none`: 1.
- Command rows with explicit `readonly=on`: 0.

Impact: database-only retro audits cannot prove the actual guest launch shape for most historical QEMU validations. The row proves a wrapper was invoked, but not which image drives, NIC arguments, readonly flags, serial settings, timeout, or teardown controls reached QEMU.

### WARNING-2: The opacity affects the dominant modernization validation path

Evidence:
- Total modernization rows: 1,505.
- QEMU-related modernization rows: 1,154, or 76.7%.
- Daily QEMU row volume peaked at 222 rows on 2026-04-22, 200 rows on 2026-04-21, and 167 rows on 2026-04-20.

Impact: this is not a fringe evidence gap. Most modernization validation rows in the central history rely on QEMU wrappers, so Law 2 air-gap and Law 10 immutable-image trend scoring must join to external manifests, captured argv artifacts, or source history instead of trusting the DB row alone.

### WARNING-3: Validation results usually collapse QEMU outcomes to `exit 0`

Evidence:
- QEMU-related modernization rows: 1,154.
- Rows whose `validation_result` is exactly `exit 0`: 1,040.
- Rows with validation result length of 6 characters or fewer: 1,040.
- Average QEMU validation result length: 11.6 characters.

Impact: the result field usually records process success, not launch-policy evidence. A successful wrapper exit does not preserve whether a boot stage was skipped, whether the wrapper performed a dry run, whether `-nic none` was present, or whether `readonly=on` applied to the OS image.

### WARNING-4: Result-side air-gap tokens are too sparse for historical scoring

Evidence:
- QEMU rows whose `validation_result` mentions `-nic none` or `-net none`: 4.
- QEMU rows whose `validation_result` mentions `readonly=on`: 0.
- Sample non-terse results include skip phrasing such as ISO unavailable or local QEMU skipped while remote compile passed.

Impact: even when the command field is wrapper-only, the result field rarely backfills the missing launch contract. Historical scoring therefore needs a normalized per-launch artifact such as `argv_sha256`, `argv_text`, `os_image_readonly`, `disabled_nic_count`, and `guest_network_forbidden_count`.

### WARNING-5: Repeated QEMU task rows amplify opaque evidence

Evidence:
- Repeated QEMU task examples include `CQ-1118` with 5 rows, `CQ-1223` with 4 rows, `CQ-1181` with 4 rows, `CQ-1152` with 4 rows, and `CQ-1109` with 4 rows.
- The repeated row excerpts still show wrapper or shell validation surfaces, not final QEMU argv captures.
- The same database snapshot also has 14 timestamp-format outliers, including 3 rows with `1776539926` and 11 rows with a space separator instead of `T`.

Impact: repetition makes the historical trend look stronger than the evidence actually is. Without durable final-argv artifacts and strict timestamp normalization, repeated wrapper successes can mask whether the underlying Law 2/Law 10 proof shape improved, regressed, or stayed unmeasured.

## Key Aggregates

| Metric | Count |
| --- | ---: |
| Total modernization rows | 1,505 |
| Modernization rows with QEMU evidence | 1,154 |
| Direct `qemu-system` command rows | 0 |
| `qemu-*` wrapper command rows | 1,152 |
| Command rows with `-nic none` / `-net none` | 1 |
| Command rows with `readonly=on` | 0 |
| Result rows with `-nic none` / `-net none` | 4 |
| Result rows with `readonly=on` | 0 |
| QEMU rows with exact `exit 0` result | 1,040 |

| Day | QEMU Rows |
| --- | ---: |
| 2026-04-12 | 77 |
| 2026-04-13 | 113 |
| 2026-04-15 | 21 |
| 2026-04-16 | 53 |
| 2026-04-17 | 89 |
| 2026-04-18 | 86 |
| 2026-04-19 | 98 |
| 2026-04-20 | 167 |
| 2026-04-21 | 200 |
| 2026-04-22 | 222 |
| 2026-04-23 | 28 |

## Recommendations

- Add a structured QEMU launch-evidence table keyed by iteration row, with final argv text/hash and parsed fields for NIC disablement, forbidden networking, OS image readonly state, serial capture, timeout, and launch mode.
- Require wrapper validations to emit a local manifest path and digest into `validation_result` or a child table before the iteration is marked `pass`.
- Treat wrapper-only QEMU rows as low-provenance for Law 2 and Law 10 historical scoring unless joined to a same-iteration manifest artifact.
- Normalize timestamp writes to one ISO-8601 form so day/window trend queries do not need ad hoc cleanup.

## Read-Only Verification Command

```bash
sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-02-qemu-wrapper-evidence-opacity-drift.sql
```

Finding count: 5 warnings.
