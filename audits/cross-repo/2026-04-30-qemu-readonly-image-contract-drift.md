# Cross-Repo Audit: QEMU Read-Only Image Contract Drift

Timestamp: 2026-04-30T15:27:35+02:00

Audit owner: gpt-5.5 sibling, retroactive / historical scope only.

Repos examined:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55` at `8f846c433da3fba9276dbeb5aeb9702781bf2b58`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55` at `a70776642a09de7ed01eb75aaaebbdd3243f84c2`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at pre-commit `2af86dd83f3550d7e6481ac9b9b4b4b5980aadd9`

Audit angle: cross-repo invariant check. This pass compared TempleOS QEMU launch contracts with holyc-inference benchmark launch contracts against Law 10. It did not modify TempleOS or holyc-inference source, did not run QEMU/VM commands, did not inspect live liveness, did not execute WS8 networking tasks, and did not add or enable any networking feature.

## Expected Invariant

Any QEMU launch that boots an installed TempleOS disk image must mount that OS image read-only. Writable scratch payload images are allowed only when they are not the installed OS image. Air-gap evidence is necessary but insufficient: `-nic none` proves network isolation, while `readonly=on` proves the immutable installed-image boundary required by Law 10.

Finding count: 5 findings.

## Findings

### CRITICAL-001: TempleOS headless disk-image launcher omits `readonly=on`

Applicable law:
- Law 10: Immutable OS Image

Evidence:
- `automation/qemu-headless.sh` documents `DISK_IMAGE=/absolute/path/to/TempleOS.img` as a boot input at lines 28-30.
- The same script builds `-drive "file=$DISK_IMAGE,format=raw,if=ide"` at line 90.
- The final guard only calls `qemu_airgap_require_disabled_network(...)` at line 104, so the launch is checked for no-network flags but not for read-only OS media.

Assessment:
For disk-image boot mode, `DISK_IMAGE` is the installed TempleOS image. Launching it without `readonly=on` violates the Law 10 QEMU clause and lets smoke or live replay runs mutate the OS image while still looking air-gap compliant.

Required remediation:
- Add `readonly=on` to the OS disk-image drive in `qemu-headless.sh`.
- If a writable second disk is needed for payloads, make it a separate explicit data-drive argument and label it separately in evidence.

### CRITICAL-002: TempleOS smoke runner repeats the writable OS image pattern

Applicable law:
- Law 10: Immutable OS Image

Evidence:
- `automation/qemu-smoke.sh` documents `DISK_IMAGE=/absolute/path/to/TempleOS.img` as a boot input at lines 26-28.
- The disk-image path is passed to QEMU as `-drive "file=$DISK_IMAGE,format=raw,if=ide"` at line 81.
- The script then validates only the no-network state with `qemu_airgap_require_disabled_network(...)` at line 95.

Assessment:
The smoke runner is the policy reference for modernization validation. Its current disk-image path can mutate an installed OS image during validation, while the smoke rubric records only air-gap compliance.

Required remediation:
- Require `readonly=on` for `DISK_IMAGE` in `qemu-smoke.sh`.
- Add a smoke assertion that fails if bootable OS image drives lack `readonly=on`.

### CRITICAL-003: holyc-inference benchmark launcher boots `--image` writable

Applicable laws:
- Law 10: Immutable OS Image
- Law 5: North Star Discipline

Evidence:
- `bench/qemu_prompt_bench.py` describes `--image` as the "TempleOS disk image to boot in QEMU" at line 3632.
- `build_command(...)` always emits `-nic none`, `-serial stdio`, and `-display none`, then emits `-drive f"file={image},format=raw,if=ide"` at lines 577-589.
- The launcher records image metadata and optional SHA-256 at lines 3903-3905, but does not mark the image read-only before running or dry-running.

Assessment:
holyc-inference can benchmark a TempleOS disk image with strong air-gap metadata while still permitting writes to the installed OS image. That drifts from TempleOS Law 10 and makes benchmark artifacts unsuitable as immutable-image evidence.

Required remediation:
- Add `readonly=on` to the boot image drive emitted by `build_command(...)`.
- Preserve writable benchmark payloads, if needed, as a second explicitly named data image rather than overloading the boot OS image.

### WARNING-004: Air-gap source audits do not check the read-only image invariant

Applicable laws:
- Law 10: Immutable OS Image
- Law 2: Air-Gap Sanctity

Evidence:
- `bench/qemu_source_audit.py` states that discovered QEMU commands must include `-nic none` and reject network backends at lines 4-7.
- Its `fragment_violations(...)` implementation checks `-nic`, `-net`, `-netdev`, and NIC devices at lines 141-183, but has no `-drive readonly=on` rule.
- `bench/qemu_args_policy_audit.py` similarly validates fragment networking and rejects legacy `-net none` in benchmark fragments at lines 126-177, but has no read-only drive check.
- TempleOS `automation/qemu-airgap-lib.sh` enforces disabled networking at lines 120-132, but has no companion immutable-image guard.

Assessment:
The two repos have converged on air-gap command scanning, but the scanner contract stops before Law 10. A QEMU command can pass the current source audits while still mounting the OS image writable.

Required remediation:
- Add a reusable read-only OS drive audit alongside air-gap audits.
- Distinguish OS boot drives from writable payload drives in audit output instead of treating all `-drive` entries identically.

### WARNING-005: Documentation examples normalize writable boot-image commands

Applicable law:
- Law 10: Immutable OS Image

Evidence:
- TempleOS `MODERNIZATION/SMOKE_TEST_CRITERIA.md` requires a bootable TempleOS image and explicit `-nic none` in preconditions at lines 14-16, but does not require `readonly=on`.
- holyc-inference `bench/README.md` shows a dry-run command and explains that artifacts record exact `-nic none` command metadata around lines 1362-1385, but the documented launch contract does not mention read-only OS media.
- The same README includes an example drive fragment `-drive file=/tmp/TempleOS.img,format=raw,if=ide` at line 1432.

Assessment:
Operator-facing examples preserve the air-gap invariant but omit the immutable-image invariant. This increases the chance that future historical evidence will keep proving `-nic none` while missing writable OS image exposure.

Required remediation:
- Update examples and smoke criteria to require `readonly=on` for installed OS images.
- Add an explicit exception note for scratch/shared payload images that are intentionally writable and are not the installed OS image.

## Non-Findings

- No QEMU or VM command was executed during this audit.
- ISO boot paths using `-cdrom` were not counted as Law 10 violations.
- Writable `shared.img` / payload FAT drives were not counted as Law 10 violations when paired with ISO boot, because those are data-transfer media rather than installed OS images.
- No networking violation was found in the reviewed launchers; the drift is that air-gap validation does not cover immutable-image validation.

## Read-Only Verification Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55 rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55 rev-parse HEAD
git rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/qemu-headless.sh | sed -n '21,110p'
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/qemu-smoke.sh | sed -n '19,100p'
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/qemu_prompt_bench.py | sed -n '577,589p;3630,3633p;3901,3905p'
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/qemu_source_audit.py | sed -n '1,8p;141,183p'
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/qemu_args_policy_audit.py | sed -n '1,8p;126,177p'
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/qemu-airgap-lib.sh | sed -n '120,132p'
```
