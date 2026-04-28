# Historical QEMU Safety Evidence Recording Drift Audit

Timestamp: 2026-04-28T12:18:44+02:00

Scope: historical trend audit from `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`, focused on recorded QEMU/VM validation evidence for Law 2 air-gap and Law 10 immutable-image safety. This audit did not inspect live liveness, did not run QEMU/VM commands, did not execute WS8 networking tasks, and did not modify TempleOS or holyc-inference source code.

SQL used: `audits/trends/2026-04-28-qemu-safety-evidence-recording-drift.sql`

Repos referenced read-only:
- TempleOS worktree: `/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55` at `aa2041e6c48258dbbdcb782dab59f5773d0371e6`
- holyc-inference worktree: `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55` at `e260e3e047064d0be65d266af09cb0cc35d6cc70`
- temple-sanhedrin audit branch baseline: `5e80c429ba9fedbd720828b794d58e4c7dac9f2f`

## Source Coverage

| Agent | Rows | QEMU evidence rows | Direct `qemu-system` command rows | QEMU rows with `-nic none`/`-net none` evidence | QEMU rows with `readonly=on` evidence | QEMU rows with `bash -n` validation | QEMU rows skipped/unavailable | QEMU rows with remote/Azure evidence |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| inference | 1,414 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| modernization | 1,505 | 1,154 | 0 | 283 | 0 | 1,141 | 193 | 200 |

Current source/report contrast, read-only:
- TempleOS current `qemu-airgap-report-latest.md` reports 15 files with QEMU mentions, 0 direct QEMU lines missing no-network evidence, 0 forbidden network option lines, and 5 QEMU wrapper files missing no required guard calls.
- TempleOS current `qemu-command-manifest-latest.md` reports 1 QEMU command line, 8 wrapper command lines, 1,114 `-nic none` evidence lines, and gate PASS.
- TempleOS current `qemu-smoke-risk-report-latest.md` reports 5 launcher files, 0 risk files, and gate PASS.
- holyc-inference current `airgap_audit_latest.md` reports 325 recorded QEMU commands checked, 0 findings, all with `-nic none`.
- holyc-inference current `qemu_source_audit_latest.md` reports 1 source command checked, 0 findings, all with `-nic none`.

## Findings

### 1. WARNING: Historical DB under-records Law 2 no-network evidence for QEMU-marked modernization rows

The modernization stream has 1,154 rows whose validation evidence mentions QEMU in the command, result, or notes. Only 283 rows, 24.5%, record explicit `-nic none`, `-nic=none`, `-net none`, or `-net=none` evidence. This does not prove the guest was networked: current TempleOS QEMU wrappers report PASS and include runtime air-gap guards. The drift is that `temple-central.db` cannot independently replay most historical Law 2 conclusions from stored iteration rows alone.

Impact: long-window Law 2 dashboards that use only `iterations.validation_cmd` and `validation_result` will classify 871 QEMU-marked modernization rows as missing no-network proof, even when the underlying wrapper may have enforced it.

### 2. WARNING: No historical QEMU row records Law 10 immutable-image `readonly=on` evidence

Across all 1,154 modernization QEMU evidence rows, the DB found 0 rows containing `readonly=on`. This is an evidence-recording gap against Law 10's QEMU-launch requirement, not a source-code finding. Current reports focus on air-gap, headless, serial, timeout, and teardown properties; the historical iteration record does not show immutable-image proof.

Impact: Sanhedrin can audit current source wrappers, but a retroactive DB-only backfill cannot distinguish a read-only OS-image run from a writable-image run.

### 3. WARNING: Most historical QEMU evidence rows are syntax checks, not expanded VM argv captures

Of 1,154 modernization QEMU evidence rows, 1,141 include `bash -n`. The first rows are typical syntax/static checks such as `bash -n automation/qemu-smoke.sh ...` with result `exit 0`, not final QEMU argv records. There are 0 rows where `validation_cmd` includes `qemu-system`.

Impact: the DB preserves that QEMU-related wrappers existed and parsed, but not the actual VM command line that would prove air-gap, read-only image, serial routing, headless mode, timeout, and teardown in one record.

### 4. WARNING: Inference QEMU benchmark evidence is absent from the historical DB window

The historical inference stream has 1,414 rows but 0 QEMU evidence rows. Current holyc-inference artifacts, outside the DB window, now report 325 checked QEMU commands and a source audit pass. That means cross-repo trend analysis has a blind spot: the inference benchmark lane has QEMU safety evidence in repo artifacts, but not in `temple-central.db` rows.

Impact: historical drift queries can incorrectly conclude that inference never exercised the QEMU path, while current benchmark artifacts prove the evidence exists elsewhere.

### 5. INFO: Current repo reports are stronger than historical DB evidence

The current TempleOS and holyc-inference generated reports both show no-network gates passing and no forbidden network options in reviewed paths. This audit found no guest networking enablement and did not run any VM command. The recommended fix is evidence normalization: store expanded QEMU argv hashes and safety flags in the central DB alongside the wrapper-level reports.

## Daily Modernization Shape

| Day | QEMU rows | No-network evidence rows | `readonly=on` rows | `bash -n` rows | Skipped/unavailable rows |
| --- | ---: | ---: | ---: | ---: | ---: |
| 2026-04-12 | 77 | 7 | 0 | 77 | 24 |
| 2026-04-13 | 113 | 17 | 0 | 112 | 51 |
| 2026-04-15 | 21 | 0 | 0 | 21 | 0 |
| 2026-04-16 | 53 | 8 | 0 | 52 | 0 |
| 2026-04-17 | 89 | 21 | 0 | 89 | 0 |
| 2026-04-18 | 86 | 10 | 0 | 86 | 1 |
| 2026-04-19 | 98 | 46 | 0 | 97 | 19 |
| 2026-04-20 | 167 | 62 | 0 | 161 | 27 |
| 2026-04-21 | 200 | 55 | 0 | 198 | 47 |
| 2026-04-22 | 222 | 53 | 0 | 222 | 24 |
| 2026-04-23 | 28 | 4 | 0 | 26 | 0 |

## Recommendations

- Add structured DB columns for `qemu_final_argv_sha256`, `qemu_no_network_flag`, `qemu_forbidden_network_args`, `qemu_os_image_readonly`, `qemu_serial_mode`, `qemu_headless`, `qemu_timeout_sec`, and `qemu_source_artifact`.
- Require QEMU wrappers to emit a redacted final-argv safety summary that can be copied into `temple-central.db` without leaking local-only Book-of-Truth serial contents.
- Extend current TempleOS QEMU reports with a Law 10 `readonly=on` check or explicitly classify ISO/CDROM boot paths separately from writable disk-image runs.
- Ingest holyc-inference benchmark `airgap_audit_latest` summaries into the central DB so inference QEMU safety evidence is trendable.
- Preserve the current hard air-gap stance: any real QEMU or VM command must include `-nic none` or legacy `-net none`; raw Book-of-Truth serial content remains local-only.

## Read-Only Verification Commands

```bash
sqlite3 /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db '.schema iterations'
sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-28-qemu-safety-evidence-recording-drift.sql
sed -n '1,80p' /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/MODERNIZATION/lint-reports/qemu-airgap-report-latest.md
sed -n '1,80p' /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/MODERNIZATION/lint-reports/qemu-command-manifest-latest.md
sed -n '1,80p' /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/MODERNIZATION/lint-reports/qemu-smoke-risk-report-latest.md
sed -n '1,80p' /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/results/airgap_audit_latest.md
sed -n '1,80p' /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/results/qemu_source_audit_latest.md
```

Finding count: 5 total, 4 warnings and 1 info.
