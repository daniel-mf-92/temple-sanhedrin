# Cross-Repo Immutable OS Image QEMU Contract Drift Audit

- Audit angle: cross-repo invariant checks
- Audit time: `2026-04-29T22:10:09+02:00`
- TempleOS HEAD: `00d1bdcd92c1af0b5c10b5ccc25cc1503f98937e`
- holyc-inference HEAD: `485af0ea41a239c8393542d6e0e2fc5944f30f53`
- Sanhedrin HEAD at audit start: `317db8b8e6a8fd399d5bcd4da81d73b02182f5da`
- Scope: read-only review of current QEMU launch contracts, immutable-image policy text, and inference benchmark assumptions. No TempleOS or holyc-inference source was modified. No QEMU/VM command was executed. No WS8 networking task, socket, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, package fetch, deployment, or live liveness check was executed.

## Summary

Found 5 findings: 2 critical and 3 warnings.

TempleOS policy already says QEMU must mount the OS image with `readonly=on` and place mutable user data on a separate disk. The executable TempleOS launchers and the holyc-inference benchmark runner do not yet encode that invariant. They consistently preserve `-nic none` evidence, but they still build `-drive file=...,format=raw,if=ide` OS-image arguments without `readonly=on`. The cross-repo result is a validation drift: benchmark and smoke evidence can be air-gapped while still booting a mutable OS disk, which is not enough for Law 10.

## Findings

### CRITICAL-001: TempleOS headless DISK_IMAGE path mounts the OS drive writable by default

Applicable laws:
- Law 10: Immutable OS Image
- Law 2: Air-Gap Sanctity, because QEMU launch evidence is currently treated as a safety proof surface

Evidence:
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:217-219` says QEMU must use `-drive readonly=on` for the OS image and a separate writable disk for user data.
- `TempleOS/automation/qemu-headless.sh:25-27` documents `DISK_IMAGE` and `ISO_IMAGE` as the required boot image inputs.
- `TempleOS/automation/qemu-headless.sh:84-86` appends `-drive "file=$DISK_IMAGE,format=raw,if=ide"` without `readonly=on`.
- `TempleOS/automation/qemu-headless.sh:88-90` uses `-cdrom "$ISO_IMAGE"` for ISO mode, which is read-only by medium type; the writable gap is specifically the disk-image path.

Assessment:

The headless runner is the canonical serial/Book-of-Truth validation path. When callers provide `DISK_IMAGE`, the OS image can be written by the guest. That violates the explicit QEMU-side immutable-image contract and weakens any validation evidence that depends on a sealed OS artifact.

Required remediation:
- Split boot media from data media in the launcher interface: `OS_IMAGE` must be mounted with `readonly=on`; writable shared/model/user disks must be separate arguments.
- Reject `DISK_IMAGE` launches that do not classify the image as read-only OS media or explicitly as a non-OS data disk.
- Print final immutable-image evidence alongside air-gap evidence, e.g. `os_drive_readonly=true`.

### CRITICAL-002: holyc-inference benchmark boots `--image` as writable even though it benchmarks TempleOS trust-plane behavior

Applicable laws:
- Law 10: Immutable OS Image
- Law 5: North Star Discipline, because benchmark evidence can look on-path while testing the wrong trust boundary

Evidence:
- `holyc-inference/bench/qemu_prompt_bench.py:1-7` defines the tool as a QEMU prompt benchmark runner for the HolyC inference engine and states networking is disabled.
- `holyc-inference/bench/qemu_prompt_bench.py:146-158` builds the command with `-drive f"file={image},format=raw,if=ide"` and no `readonly=on`.
- `holyc-inference/bench/qemu_prompt_bench.py:315` describes `--image` as the TempleOS disk image to boot.
- `holyc-inference/bench/README.md:30-35` documents the runner as booting a TempleOS image and only states `-nic none` / networking rejection, with no immutable OS-image requirement.

Assessment:

The inference plane assumes TempleOS is the secure local control plane, but its benchmark runner does not preserve the control-plane immutable-image invariant. A benchmark can therefore claim air-gapped QEMU execution while using a mutable TempleOS image. That is cross-repo drift: TempleOS policy requires a sealed OS artifact, while inference benchmark tooling treats the boot image as ordinary writable disk media.

Required remediation:
- Add `readonly=on` to the boot image drive in `build_command()`.
- Add a separate writable data/model disk argument if the benchmark needs mutable payload input.
- Extend the dry-run JSON to include an explicit immutable-image classification, not only the raw command list.

### WARNING-001: TempleOS smoke runner repeats the writable DISK_IMAGE pattern

Applicable laws:
- Law 10: Immutable OS Image

Evidence:
- `TempleOS/automation/qemu-smoke.sh:23-25` documents `DISK_IMAGE` and `ISO_IMAGE` as required input alternatives.
- `TempleOS/automation/qemu-smoke.sh:75-77` appends `-drive "file=$DISK_IMAGE,format=raw,if=ide"` without `readonly=on`.
- `TempleOS/automation/qemu-smoke.sh:67-73` does enforce `-nic none` / `-net none`, so the gap is immutable-image evidence rather than guest networking.

Assessment:

Smoke results can currently prove the guest had no NIC while failing to prove the OS image was immutable. This matters because smoke is likely to be cited by builder iterations as North Star or harness evidence.

Required remediation:
- Use the same shared QEMU drive builder as the headless runner after it enforces read-only OS media.
- Add a static smoke test that fails if any boot-image `-drive` lacks `readonly=on`.

### WARNING-002: TempleOS compile validation mixes read-only boot media with a writable shared disk but does not label the boundary

Applicable laws:
- Law 10: Immutable OS Image

Evidence:
- `TempleOS/automation/qemu-compile-test.sh:67-73` boots with `-cdrom "$ISO_FILE"` and a second `-drive file="$SHARED_DISK",format=raw,if=ide`.
- `TempleOS/automation/qemu-compile-test.sh:50-61` creates and populates `shared.img` with test HolyC files.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:213-219` allows user data and models on a separate writable partition while requiring the OS image to be read-only.

Assessment:

This compile harness is closer to the desired model because the OS ISO is read-only and the mutable files sit on a separate drive. The report gap is that the command and wrapper output do not classify which drive is OS media versus writable data media. Without that classification, Sanhedrin checks can only grep for `-drive` and cannot distinguish compliant shared-data disks from non-compliant writable OS disks.

Required remediation:
- Emit a machine-checkable launch summary with `os_media=cdrom`, `os_readonly=true`, and `data_drive_writable=true`.
- Keep the shared disk explicitly separate and never reuse the `DISK_IMAGE`/boot-image variable for test payload storage.

### WARNING-003: North Star and loop prompt examples preserve old writable-drive command shapes

Applicable laws:
- Law 10: Immutable OS Image
- Law 5: North Star Discipline

Evidence:
- `TempleOS/MODERNIZATION/NORTH_STAR.md:16-18` shows the concrete QEMU North Star command with `-cdrom TempleOS.ISO -drive file=shared.img,format=raw,if=ide`, but does not state that the OS image must be read-only or that `shared.img` must be non-OS data.
- `TempleOS/MODERNIZATION/LOOP_PROMPT.md:88-89` repeats the Azure QEMU command with `-cdrom /home/azureuser/TempleOS.ISO -drive file=shared.img,format=raw,if=ide -nic none`.
- `holyc-inference/NORTH_STAR.md:16-19` requires the GPT-2 weight blob to live on `shared.img` and a HolyC forward pass to run in QEMU, but does not bind that shared image to a separate read/write data disk under a read-only TempleOS OS image.
- `holyc-inference/docs/GGUF_FORMAT.md:198-202` documents disk-only runtime and `-nic none` but not immutable OS media.

Assessment:

The examples are not direct Law 10 violations when `-cdrom` is the OS medium and `shared.img` is only data. They are still drift-prone because they teach builders to preserve `-nic none` as the only QEMU safety evidence. The immutable-image invariant is present in TempleOS task policy but absent from the cross-repo executable examples that builders and inference benchmarks follow.

Required remediation:
- Update examples to name the boot medium and data medium separately.
- Add `readonly=on` in any disk-image boot example.
- Require cross-repo benchmark reports to record both `guest_network=none` and `os_image_readonly=true`.

## Positive Observations

- No reviewed path added or executed guest networking; the inspected QEMU launchers still include `-nic none` or `-net none`.
- The TempleOS compile harness uses an ISO boot path plus a separate shared disk, which matches the intended OS/read-write data split if reported explicitly.
- No source changes were made outside Sanhedrin audit artifacts.

## Read-Only Verification

Commands run were limited to `git rev-parse`, `rg`, `find`, `nl`, `sed`, `tail`, and `date` against local repositories and audit files. No QEMU command was run, no VM was started, and no network command was executed.

Representative evidence commands:

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/qemu-headless.sh | sed -n '1,180p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/qemu-smoke.sh | sed -n '1,120p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/qemu-compile-test.sh | sed -n '1,100p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py | sed -n '1,190p;300,340p'
```
