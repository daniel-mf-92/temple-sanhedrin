# Cross-Repo Audit: QEMU Air-Gap and Immutable Image Launch Drift

Date: 2026-04-30T19:27:13+0200
Scope: Retroactive cross-repo invariant check across current TempleOS and holyc-inference heads.

## Repos Read

- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `f0140c73`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c`
- Sanhedrin laws: `LAWS.md`

## Invariant

Any host-side QEMU launch path that boots TempleOS or a TempleOS-derived image must preserve both:

- Law 2: explicit guest networking disablement (`-nic none`, or `-net none` only as legacy fallback).
- Law 10: explicit immutable OS image launch (`-drive readonly=on` for the OS image).

The holyc-inference benchmark consumes the TempleOS image as an inference runtime substrate, so its benchmark launcher must satisfy the same launch contract as TempleOS' own modernization harnesses.

## Findings

### 1. CRITICAL: TempleOS headless disk-image boots omit `readonly=on`

Evidence: `automation/qemu-headless.sh` accepts `DISK_IMAGE` as the boot image and emits `-drive "file=$DISK_IMAGE,format=raw,if=ide"` without `readonly=on` at lines 84-85. Law 10 explicitly treats QEMU commands missing `-drive readonly=on` for the OS image as violations.

Impact: A historical or future headless smoke run can mutate the installed OS disk while still appearing Law-2 compliant because `-nic none` is present.

### 2. CRITICAL: holyc-inference prompt benchmark boots TempleOS image writable

Evidence: `bench/qemu_prompt_bench.py` builds its command with `-drive f"file={image},format=raw,if=ide"` at lines 146-158. A dry-run produced:

```text
qemu-system-x86_64 -nic none -serial stdio -display none -drive file=/tmp/TempleOS.img,format=raw,if=ide
```

Impact: The inference benchmark meets its documented air-gap claim, but it drifts from the immutable-image half of the TempleOS launch contract.

### 3. WARNING: TempleOS `EXTRA_ARGS` can append conflicting QEMU network or drive options after the air-gap/default drive contract

Evidence: `automation/qemu-headless.sh` appends shell-split `EXTRA_ARGS` after the built-in `-nic none`/`-net none` and after the image drive at lines 92-95, with no rejection for `-nic user`, `-netdev`, network devices, or a second writable boot drive.

Impact: The script's help says networking is "forcibly disabled", but the command construction allows policy-sensitive overrides after the guard. This is a Law 2 drift risk and a Law 10 drift risk.

### 4. CRITICAL: TempleOS compile harness still has a network-dependent ISO fetch path

Evidence: `automation/qemu-compile-test.sh` defines `ISO_URL="https://templeos.org/Downloads/TempleOS.ISO"` and runs `curl -sL "$ISO_URL" -o "$ISO_FILE"` when the ISO is missing at lines 12-29.

Impact: Law 2 forbids network-dependent package managers or build steps, and the user's hard safety requirement rejects network-dependent runtime services. Even though failure exits 0 as a skip, the harness still attempts a network fetch before declaring the QEMU test unavailable.

### 5. WARNING: Cross-repo policy text is asymmetrical: holyc-inference documents only `-nic none`, not immutable-image launch

Evidence: `bench/README.md` requires QEMU commands under `bench/` to pass `-nic none` and describes rejected networking arguments at lines 3-5 and 34-35, but says nothing about `readonly=on` for the boot image. The implementation mirrors that gap.

Impact: Future inference benchmark work can remain locally "compliant" with holyc-inference docs while violating Sanhedrin Law 10. This is a documentation-to-implementation drift between trinity members.

## Non-Findings

- holyc-inference `bench/qemu_prompt_bench.py` rejects explicit `-nic`/`-net` values other than `none`, rejects `-netdev`, and rejects common NIC device models at lines 114-141.
- No VM was launched during this audit; only dry-run command construction was inspected.
- No TempleOS or holyc-inference source files were modified.

## Recommended Backlog

- TempleOS: add `readonly=on` to OS-image `-drive` construction in `automation/qemu-headless.sh`.
- TempleOS: replace raw `EXTRA_ARGS` with parsed allowlist or reject network/drive-affecting options.
- TempleOS: remove the live `curl` ISO acquisition path or require a preseeded local ISO.
- holyc-inference: add `readonly=on` to `bench/qemu_prompt_bench.py` for the `--image` drive.
- holyc-inference: update `bench/README.md` to require both `-nic none` and immutable OS-image launch.
