# Law 10 Post-Rule QEMU Readonly Backfill

Timestamp: 2026-04-28T15:55:34+02:00

Scope: compliance backfill for Law 10 immutable-image enforcement after the 2026-04-27 Law 10 backfill. This audit was read-only against TempleOS, did not inspect live liveness, did not run QEMU or any VM command, did not execute WS8 networking tasks, and did not modify TempleOS or holyc-inference source code.

Repos referenced read-only:
- TempleOS primary worktree: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `0a1df95f6ff5ebc9ce370db06adc1d4288a76f5f`
- TempleOS gpt55 worktree: `/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55` at `88dde1668b082d37922522dc436432351001a3a4`
- Sanhedrin audit branch: `codex/sanhedrin-gpt55-audit`

Applicable rule: Law 10 says QEMU launch commands must use `-drive readonly=on` for the OS image, and that once installed, the OS cannot be modified on device without full reinstall.

## Historical Coverage

Read-only history scan:
- TempleOS all-ref commit count: 2,114.
- Commits touching the scoped Law 10 surfaces (`automation`, `MODERNIZATION`, `.github`, and core OS paths): 2,112.
- Commits touching core OS paths (`Kernel`, `Adam`, `Apps`, `Compiler`, `0000Boot`): 862.
- Commits touching host/policy surfaces (`automation`, `MODERNIZATION`, `.github`): 2,024.
- Commits matching Law 10/QEMU evidence terms (`readonly=on`, `qemu-system`, `-drive`, `remount`, `kexec`, `module load`, `hotfix`, update/patch mechanism): 59.
- Commits matching `readonly=on`/`snapshot=on`: 1.
- Commits matching QEMU/drive terms in host/policy surfaces: 58.
- Commits touching the current QEMU launcher and North Star command surfaces: 21.

Current gpt55 worktree generated reports show strong Law 2 coverage but not Law 10 readonly coverage:
- `qemu-command-manifest-latest`: 1 direct QEMU command line, 8 wrapper command lines, 1,375 no-network evidence lines, 0 forbidden network lines, gate PASS.
- `qemu-smoke-risk-report-latest`: 5 launcher files, 1 QEMU smoke launcher, 0 risk files, 0 smoke launchers missing no-network/headless/serial/timeout/teardown, gate PASS.
- `qemu-airgap-report-latest`: 16 files with QEMU mentions, 0 direct QEMU lines missing no-network evidence, 0 forbidden network option lines.

## Findings

### 1. CRITICAL: Law 10 QEMU OS-image readonly violation remains open

The current gpt55 TempleOS launcher surfaces still build writable raw disk drives:
- `automation/qemu-smoke.sh:79`: `qemu_args+=(-drive "file=$DISK_IMAGE,format=raw,if=ide")`
- `automation/qemu-headless.sh:88`: `qemu_args+=( -drive "file=$DISK_IMAGE,format=raw,if=ide" )`
- `automation/qemu-compile-test.sh:69`: `-drive file="$SHARED_DISK",format=raw,if=ide`
- `automation/north-star-e2e.sh:21`: direct QEMU command is air-gapped and ISO-backed, but does not exercise/readiness-check the Law 10 `readonly=on` disk-image contract.

Backfill assessment: this is the same class of Law 10 issue identified on 2026-04-27, still present after the later QEMU-reporting work. The launchers are air-gapped, but the OS/shared image drive contract is mutable.

### 2. WARNING: Current QEMU gates can pass while Law 10 readonly is absent

The current generated reports count no-network, headless, serial, timeout, teardown, and forbidden-network evidence, but not `readonly=on`. A direct scan found only one `readonly=on` occurrence across the current gpt55 QEMU manifest/report and launcher surfaces, and that occurrence is policy/task text rather than executable launcher enforcement.

Impact: a Sanhedrin or builder iteration can truthfully report QEMU safety PASS for Law 2 while still failing Law 10's immutable-image QEMU clause. The gate vocabulary needs a distinct `readonly=on`/OS-image classification metric.

### 3. WARNING: Policy examples continue to normalize mutable shared image drives

Current policy/North Star text still shows writable shared image examples:
- `MODERNIZATION/NORTH_STAR.md:17`: `-drive file=shared.img,format=raw,if=ide -nic none ...`
- `MODERNIZATION/LOOP_PROMPT.md:89`: `-drive file=shared.img,format=raw,if=ide -nic none ...`

Backfill assessment: these examples are historical command surfaces, not just prose. They teach future agents the expected QEMU shape and omit the Law 10-required `readonly=on` attribute for the OS image.

### 4. INFO: No new guest networking enablement was found in this Law 10 pass

This audit found no QEMU launcher missing `-nic none`/`-net none` evidence in the current gpt55 reports, and no forbidden network option lines in the generated QEMU reports. The issue is image mutability, not air-gap drift.

## Compliance Score

- TempleOS QEMU readonly compliance: fail.
- Current QEMU report coverage for Law 10 readonly: fail.
- Air-gap preservation in reviewed QEMU surfaces: pass.
- Backfill result: 4 findings total, 1 critical, 2 warnings, 1 info.

## Recommended Backfill Closure Criteria

- Add `readonly=on` to OS-image `-drive` arguments in `qemu-headless.sh`, `qemu-smoke.sh`, and `qemu-compile-test.sh`; use a separate explicitly writable scratch drive for state that must persist.
- Update `NORTH_STAR.md` and `LOOP_PROMPT.md` command examples so future agents inherit the Law 10 drive shape.
- Extend `qemu-command-manifest.py` and `qemu-smoke-risk-report.py` with `readonly_on_evidence_lines`, `os_image_drive_lines`, and `os_image_drive_missing_readonly_count`.
- Treat any direct QEMU OS-image drive without `readonly=on` as Law 10 failure even when Law 2 air-gap checks pass.

## Read-Only Verification Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-list --count --all
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS log --all -G 'readonly=on|snapshot=on|qemu-system|-drive|remount|kexec|module load|hotfix|patch mechanism|update mechanism' --format='%H' -- automation MODERNIZATION Kernel Adam Apps Compiler 0000Boot .github | wc -l
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS log --all -G 'readonly=on|snapshot=on' --format='%H' -- automation MODERNIZATION Kernel Adam Apps Compiler 0000Boot .github | wc -l
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS log --all -G 'qemu-system|-drive' --format='%H' -- automation MODERNIZATION .github | wc -l
rg -n 'drive_args|qemu-system|readonly|drive' /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/qemu-headless.sh /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/qemu-smoke.sh /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/qemu-compile-test.sh /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/north-star-e2e.sh
jq '{qemu_command_lines, wrapper_command_lines, no_network_evidence_lines, forbidden_network_lines, gate_failed, smoke_launcher_count, smoke_missing_no_network_count}' /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/MODERNIZATION/lint-reports/qemu-command-manifest-latest.json
jq '.metrics // .' /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/MODERNIZATION/lint-reports/qemu-smoke-risk-report-latest.json
```
