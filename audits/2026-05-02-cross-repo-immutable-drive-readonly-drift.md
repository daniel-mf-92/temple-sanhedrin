# Cross-Repo Immutable Drive Readonly Drift Audit

- Audit angle: cross-repo invariant checks
- Timestamp: 2026-05-02T05:31:04+02:00
- Repos inspected: `TempleOS`, `holyc-inference`, `temple-sanhedrin`
- TempleOS HEAD: `1b4d28ece89a2f6fa065271a403c8718fb61864e`
- holyc-inference HEAD: `a70776642a09de7ed01eb75aaaebbdd3243f84c2`
- Sanhedrin HEAD: `f9dca072a963aaaf7b7556456ac260930c48e00f`
- Scope note: read-only source/artifact inspection only; no TempleOS guest, QEMU, VM, network, or builder-repo write operation was executed.

## Invariant Under Audit

Law 10 says QEMU launch commands for the OS image must include `readonly=on`. Law 2 requires explicit no-network flags. The repos now have extensive no-network validation, but the immutable-image side of the same launch contract is not yet enforced consistently across TempleOS launchers, holyc-inference benchmark launchers, generated artifacts, or static audit gates.

The invariant should be:

`qemu-system-* ... -nic none ... -drive file=<TempleOS OS image>,...,readonly=on`

Writable scratch or payload disks may exist only when named as non-OS data media. The OS image must be explicitly read-only.

## Evidence

Static scan results from this iteration:
- TempleOS scan over shell/Python/Markdown/JSON launch material found 18 files with `-drive` references where `readonly=on` was absent or underrepresented.
- holyc-inference scan over benchmark/test/artifact material found 170 files with `-drive` references where `readonly=on` was absent or underrepresented.
- These counts include generated artifacts and smoke fixtures; they are not all executable launchers, but they show that the committed evidence contract itself normalizes writable OS-image command strings.

Focused evidence:
- `TempleOS/automation/qemu-headless.sh:89-91` appends `-drive "file=$DISK_IMAGE,format=raw,if=ide"` for a boot disk without `readonly=on`.
- `TempleOS/automation/qemu-smoke.sh:80-82` appends `-drive "file=$DISK_IMAGE,format=raw,if=ide"` without `readonly=on`.
- `TempleOS/automation/qemu-headless-boot-media-smoke.sh:77` asserts the writable drive string as expected output.
- `holyc-inference/bench/qemu_prompt_bench.py:709-723` builds every benchmark launch command with `-nic none`, `-serial stdio`, `-display none`, and `-drive file=<image>,format=raw,if=ide`, but no `readonly=on`.
- `holyc-inference/tests/test_qemu_prompt_bench.py:18-25` asserts the writable drive string as the expected launcher contract.
- `holyc-inference/bench/qemu_prompt_bench.py:612-621` reports air-gap metadata for `-nic none` / `-net none` only; it has no immutable-drive metadata or finding.
- `holyc-inference/bench/qemu_source_audit_ci_smoke.py:49` uses `qemu-system-x86_64 -nic none -display none -drive file=/tmp/TempleOS.img,format=raw,if=ide` as a passing source-audit fixture.

## Findings

### 1. CRITICAL: TempleOS primary disk boot wrappers still mount the OS image writable

`qemu-headless.sh` and `qemu-smoke.sh` both accept `DISK_IMAGE` as the TempleOS boot image and attach it as `file=$DISK_IMAGE,format=raw,if=ide`. Law 10 explicitly classifies QEMU launch commands missing `readonly=on` for the OS image as violations.

Impact:
- A normal live/smoke run can mutate the installed OS image in place.
- The Book-of-Truth and air-gap evidence produced by that run can no longer prove it came from an immutable installed image.

Expected correction in the builder repo:
- Attach the OS image as `file=$DISK_IMAGE,format=raw,if=ide,readonly=on`.
- Introduce separate writable data/scratch media only under explicit non-OS names.

### 2. CRITICAL: holyc-inference benchmark launcher bakes the same writable OS-image command into its runtime contract

`qemu_prompt_bench.build_command()` injects `-nic none` reliably, but its `-drive` argument is `file=<image>,format=raw,if=ide`. The benchmark image is named and documented as a TempleOS image in tests and fixtures, so the inference side assumes the writable TempleOS drive form is valid.

Impact:
- Inference performance/evaluation artifacts can be generated from mutable TempleOS images while still reporting air-gap success.
- Cross-repo trust can drift: TempleOS may harden Law 10 while holyc-inference continues producing accepted benchmark evidence from the old writable command shape.

Expected correction in the builder repo:
- Make the injected OS-image drive read-only by default.
- If a benchmark genuinely needs writable guest storage, require a second explicit scratch-drive option and record it separately from the OS image.

### 3. WARNING: Static QEMU audit gates check air-gap state but do not gate immutable-drive state

TempleOS `qemu-command-manifest.py` and holyc-inference `command_airgap_metadata()` focus on no-network, serial capture, display, timeout, and forbidden remote transports. The current metadata schema has no field for `os_drive_readonly`, `readonly_missing`, or `writable_os_drive`.

Impact:
- A command can be fully green for air-gap and launch integrity while still violating Law 10.
- CI and Sanhedrin artifact review must infer immutable-image compliance manually from raw argv strings.

Expected correction in the builder repos:
- Add immutable-drive parsing to the QEMU command manifest and benchmark metadata.
- Treat `-drive file=<TempleOS image>` without `readonly=on` as a failed gate unless the drive is explicitly declared as non-OS scratch media.

### 4. WARNING: Smoke tests and fixtures now codify the writable drive string as expected behavior

TempleOS boot-media smoke tests and holyc-inference QEMU benchmark tests assert `file=...,format=raw,if=ide` without `readonly=on`. holyc-inference source-audit smoke fixtures also use the writable command as a passing fixture.

Impact:
- A future builder patch that fixes Law 10 by adding `readonly=on` will fail existing tests until the fixtures are updated.
- The tests make the insecure shape sticky even though the law text has moved beyond it.

Expected correction in the builder repos:
- Update positive fixtures to require `readonly=on`.
- Add negative fixtures proving a missing `readonly=on` on TempleOS OS images fails.

### 5. WARNING: Historical benchmark artifacts preserve writable launch commands without immutable-image telemetry

Committed holyc-inference benchmark JSON artifacts repeatedly store launch commands containing `-drive` followed by `file=/tmp/TempleOS.synthetic.img,format=raw,if=ide`. These artifacts also record air-gap success, but they do not record whether the OS drive was read-only.

Impact:
- Historical benchmark evidence cannot be retroactively scored for Law 10 except by parsing raw command arrays.
- Air-gap dashboards can look healthy while immutable-image compliance remains unmeasured.

Expected correction in the builder repo:
- Add an immutable-drive audit/backfill over benchmark artifacts.
- Include an explicit `command_immutable_image_ok` field in future reports so Sanhedrin can trend Law 10 separately from Law 2.

## Summary

Findings: 5 total.

- Critical: 2
- Warning: 3

No evidence in this audit showed guest networking enablement, and no QEMU command was executed. The drift is narrower: the Trinity has largely standardized on `-nic none`, but has not given `readonly=on` the same first-class treatment for TempleOS OS-image drives.
