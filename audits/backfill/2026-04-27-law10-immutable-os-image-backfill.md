# Compliance Backfill: Law 10 Immutable OS Image

Scope: retroactive / historical compliance backfill for immutable installed OS image semantics. No TempleOS or holyc-inference source was modified, and no VM/QEMU command was executed.

Repos inspected:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`
- Sanhedrin audit branch: `codex/sanhedrin-gpt55-audit`

Applicable rule:
- Law 10: once installed, the OS cannot be modified on the device; full reinstall required for any change.
- Law 10 violations include remount-as-writable paths, update/patch/hotfix mechanisms, self-modifying or runtime patching, module loading that alters kernel behavior after boot, and QEMU OS-image drives missing `readonly=on`.

## Backfill Window

Historical introduction points checked:
- TempleOS inherited `BootHDIns`, `BootMHDIns`, `Mount`, `DrvIsWritable`, and `Load` paths from the initial import commit `ac16273c14d8cf9e6f7be78807673b5c38a04c23` on 2026-04-09.
- TempleOS `automation/qemu-headless.sh` was introduced by `48608e22561985badab9a5b19c54d862b3658181` on 2026-04-12 and remains the main live-mode runner.
- TempleOS QEMU launcher history was later air-gap hardened by `5208dec84404be5099c49a3569969bf35837aab7` on 2026-04-27, but the `DISK_IMAGE` drive builders still omit `readonly=on`.
- holyc-inference `bench/qemu_prompt_bench.py` currently builds its TempleOS image drive without `readonly=on` and has no `readonly=on` occurrence anywhere in the repo.

Current search surface:
- TempleOS has 672 shell files that reference `automation/qemu-headless.sh`.
- TempleOS has 134 shell files exposing `DISK_IMAGE` live-mode inputs.
- TempleOS has exactly one `readonly=on` occurrence in inspected project text, and it is task guidance in `MODERNIZATION/MASTER_TASKS.md`, not launcher enforcement.
- holyc-inference has zero `readonly=on` occurrences.

## Finding CRITICAL-001: Installed TempleOS can still rewrite its own kernel and boot sectors

Applicable law:
- Law 10: no update/patch/hotfix path; full reinstall required for any change.

Evidence:
- `Adam/Opt/Boot/BootHDIns.HC:18-19` defines `BootHDIns` as `MakeAll` plus new boot-loader install.
- `Adam/Opt/Boot/BootHDIns.HC:28-32` compiles compiler/kernel artifacts and moves `/Kernel/Kernel.BIN.Z` to `/Kernel.BIN.C`.
- `Adam/Opt/Boot/BootHDIns.HC:37-50` modifies the partition boot record and calls `BlkWrite(dv,&br,dv->drv_offset,1)`.
- `Adam/Opt/Boot/BootMHDIns.HC:37-47` restores an old MBR by calling `ATAWriteBlks(bd,mbr,0,1)`.
- `Adam/Opt/Boot/BootMHDIns.HC:52-66` has an explicit `BootMHDZero` path that writes a zeroed MBR.
- `Adam/Opt/Boot/BootMHDIns.HC:122-145` writes a fresh stage-2 boot image and then writes the master boot record with `ATAWriteBlks(bd,&mbr,0,1)`.

Backfill assessment:
These are inherited TempleOS installation/update paths, not newly introduced modernization code. Under Law 10, however, the modernization target cannot leave an installed device capable of recompiling kernel/compiler artifacts and rewriting partition or master boot records in place. The law requires a reinstall boundary, and these paths are direct in-place mutation mechanisms.

Risk:
An installed image can drift from the sealed baseline through normal in-guest commands, making Book-of-Truth evidence and later audit conclusions depend on mutable local state rather than a known image generation.

Required remediation:
- Gate `BootHDIns`, `BootMHDIns`, `BootMHDOldWrite`, and `BootMHDZero` behind an installer-only boot mode that is absent from normal installed images.
- Require a fresh install image or physically write-enabled maintenance medium for these operations.
- Add a Law 10 static check for boot-sector and kernel artifact write paths reachable in installed mode.

## Finding CRITICAL-002: Runtime module loading remains available in core kernel code

Applicable law:
- Law 10: no module loading that alters kernel behavior post-boot.

Evidence:
- `Kernel/KLoad.HC:181-182` defines `Load` as loading a `.BIN` file module into memory.
- `Kernel/KLoad.HC:188-192` reads a module from disk using `FileRead`.
- `Kernel/KLoad.HC:202-220` allocates/copies module bytes into executable memory.
- `Kernel/KLoad.HC:163-165` can call an imported `IET_MAIN` entry point after relocations are processed.

Backfill assessment:
This path is also inherited from the initial TempleOS import. It is still material to Law 10 because a post-boot `.BIN` module can alter behavior without a full reinstall. The current modernization tree does not appear to add a Law 10 installed-mode guard around this loader.

Risk:
Even if the OS disk image is made read-only, runtime behavior can still be changed by loading executable modules from writable media or existing files, weakening the immutable-device model.

Required remediation:
- Define an installed-mode policy that disables `Load` for behavior-changing modules or restricts it to immutable, measured image content.
- Record any permitted loader exceptions explicitly in LAWS.md or a Law 10 design note.
- Add a regression check that fails if core runtime module loading is reachable in normal installed mode.

## Finding CRITICAL-003: TempleOS live-mode automation fans out mutable `DISK_IMAGE` booting

Applicable law:
- Law 10: QEMU launch commands must use `-drive readonly=on` for the OS image.

Evidence:
- `automation/qemu-headless.sh:84-85` appends `-drive "file=$DISK_IMAGE,format=raw,if=ide"` with no `readonly=on`.
- `automation/qemu-smoke.sh:75-76` appends the same mutable raw `DISK_IMAGE` drive.
- `automation/north-star-e2e.sh:21-26` uses an ISO path and `-nic none`, so that specific script is not a mutable-disk finding.
- Current TempleOS scans found 672 shell files referencing `automation/qemu-headless.sh` and 134 shell files exposing `DISK_IMAGE` live-mode inputs.
- Current TempleOS scans found `readonly=on` only in `MODERNIZATION/MASTER_TASKS.md:218`, not in executable launchers.

Backfill assessment:
The direct launcher issue was already visible in the QEMU launch-safety backfill, but this Law 10 pass shows the larger blast radius: many live wrappers delegate to the mutable `qemu-headless.sh` path or expose the same `DISK_IMAGE` convention. Air-gap hardening is therefore not enough; the common live-runner contract itself needs immutable-image semantics.

Risk:
Replay, liveness, watchdog, and Book-of-Truth harnesses can mutate the same disk image they are measuring. That breaks historical comparability and can mask whether observed behavior came from source commits or from persistent guest image drift.

Required remediation:
- Make `qemu-headless.sh` and `qemu-smoke.sh` add `readonly=on` to OS-image drives by default.
- If tests need writable storage, require a second explicit scratch drive variable and document it as non-OS state.
- Add a Sanhedrin static guard that treats any `DISK_IMAGE` QEMU drive without `readonly=on` as Law 10 failure.

## Finding WARNING-001: holyc-inference benchmark boots TempleOS images mutably

Applicable law:
- Law 10 applies when the inference repo boots a TempleOS OS image for benchmark execution.

Evidence:
- `bench/qemu_prompt_bench.py:146-160` constructs QEMU with `-nic none`, `-serial stdio`, `-display none`, and `-drive file=<image>,format=raw,if=ide`.
- `tests/test_qemu_prompt_bench.py:19-33` asserts air-gap and drive construction, but it only checks `file=<image>,format=raw,if=ide`; it does not require `readonly=on`.
- `rg -n "readonly=on"` found no matches in holyc-inference.

Backfill assessment:
The inference repo does not own TempleOS modernization internals, but it does run TempleOS images. Its current benchmark command can mutate the image under test unless the caller supplies a disposable copy. This is a cross-repo Law 10 warning rather than a direct modernization critical.

Risk:
Inference benchmark state can become path-dependent on prior runs, which undermines reproducible token/runtime comparisons and any Book-of-Truth assumptions inherited from the guest image.

Required remediation:
- Default benchmark image drives to `readonly=on`.
- Add an explicit writable scratch-image option for any test that needs guest persistence.
- Extend `tests/test_qemu_prompt_bench.py` to require both `-nic none` and read-only OS-image evidence.

## Compliance Score

- TempleOS inherited installed-image immutability: fail, due in-place kernel/boot-sector installation paths and runtime module loading.
- TempleOS QEMU OS-image immutability: fail, due mutable `DISK_IMAGE` launchers and large live-mode wrapper fan-out.
- holyc-inference TempleOS benchmark immutability: warning, due mutable QEMU image drive construction.
- Backfill result: 4 findings total, 3 critical and 1 warning.

## Non-Findings

- No QEMU or VM command was executed during this audit.
- The cited current QEMU launchers and benchmark runner include explicit no-network evidence (`-nic none` or fallback logic), so these findings are Law 10 image-mutability findings, not Law 2 guest-network findings.
- The broad TempleOS core write APIs such as `BlkWrite` and filesystem writes are expected OS primitives; this report only escalates the installed-OS update, boot-sector rewrite, runtime module load, and QEMU OS-image cases that map directly to Law 10.

## Commands Run

- `sed -n '1,240p' LAWS.md`
- `git rev-list --count HEAD`
- `git status --short`
- `rg -n --hidden ... "qemu-system|-drive|DISK_IMAGE|readonly=on|..." ...`
- `rg -n --hidden ... "BootHDIns|BootMHDIns|DskPrt|Mount|BlkWrite|Load(...)" ...`
- `nl -ba .../Adam/Opt/Boot/BootHDIns.HC`
- `nl -ba .../Adam/Opt/Boot/BootMHDIns.HC`
- `nl -ba .../Kernel/KLoad.HC`
- `nl -ba .../Kernel/BlkDev/DskDrv.HC`
- `nl -ba .../Adam/ABlkDev/Mount.HC`
- `nl -ba .../automation/qemu-headless.sh`
- `nl -ba .../automation/qemu-smoke.sh`
- `nl -ba .../automation/north-star-e2e.sh`
- `nl -ba .../bench/qemu_prompt_bench.py`
- `nl -ba .../tests/test_qemu_prompt_bench.py`
- `rg -l --glob '*.sh' 'qemu-headless\\.sh' automation | wc -l`
- `rg -l --glob '*.sh' 'DISK_IMAGE=' automation | wc -l`
- `rg -n 'readonly=on' ...`
