# Cross-Repo QEMU Launch Enforcement Current-Head Drift Audit

- Audit angle: cross-repo invariant checks
- Timestamp: 2026-05-01T08:16:44+02:00
- TempleOS HEAD: `c81806b97e2e698a1e18f695b2c43253c173b844`
- holyc-inference HEAD: `2799283c9554bea44c132137c590f02034c8f726`
- Scope note: read-only source inspection only. No TempleOS guest, QEMU, VM, networking command, WS8 task, or builder-repo write was executed.

## Invariant Under Audit

All QEMU or VM launch surfaces shared by TempleOS and holyc-inference must preserve two independent properties:

- Law 2: the guest remains air-gapped with explicit `-nic none` or legacy `-net none`, and no later launch argument can re-enable a NIC/backend.
- Law 10: any installed TempleOS OS image is mounted read-only with `readonly=on`; writable media must be explicit scratch/data images, not the boot OS image.

This pass refreshed the QEMU launch surface at current heads after earlier immutable-image and serial-contract audits, with attention to whether enforcement is actually encoded in launchers/tests rather than only described in policy docs.

## Findings

### 1. CRITICAL: TempleOS disk-image launchers still mount `DISK_IMAGE` writable

Evidence:
- `TempleOS/automation/qemu-headless.sh:25-27` documents `DISK_IMAGE=/absolute/path/to/TempleOS.img` as a boot input.
- `TempleOS/automation/qemu-headless.sh:84-85` appends `-drive "file=$DISK_IMAGE,format=raw,if=ide"` with no `readonly=on`.
- `TempleOS/automation/qemu-smoke.sh:23-25` documents the same `DISK_IMAGE` boot input.
- `TempleOS/automation/qemu-smoke.sh:75-76` appends `-drive "file=$DISK_IMAGE,format=raw,if=ide"` with no `readonly=on`.

Assessment:
These launchers can boot an installed TempleOS disk image in mutable mode while still satisfying their air-gap checks. That violates Law 10's QEMU OS-image clause and keeps producing validation evidence that proves `-nic none` but not image immutability.

### 2. WARNING: TempleOS `EXTRA_ARGS` can append network-enabling QEMU flags after the no-network flag

Evidence:
- `TempleOS/automation/qemu-headless.sh:76-82` adds `-nic none` or `-net none`, but `TempleOS/automation/qemu-headless.sh:92-95` appends unfiltered `EXTRA_ARGS` after that policy flag.
- `TempleOS/automation/qemu-smoke.sh:69-73` adds `-nic none` or `-net none`, but `TempleOS/automation/qemu-smoke.sh:83-86` appends unfiltered `EXTRA_ARGS` after that policy flag.
- `TempleOS/automation/enforce-templeos-airgap.sh:55-69` scans changed source files for QEMU networking tokens, but it cannot reject runtime environment values like `EXTRA_ARGS='-nic user'`.

Assessment:
The scripts print an air-gap posture, yet their final argv can include a second NIC/backend supplied at runtime. The safer invariant is to reject `EXTRA_ARGS` containing `-nic`, `-net`, `-netdev`, NIC device models, `hostfwd`, `guestfwd`, `tap`, `bridge`, `socket`, or `user` networking fragments before launch.

### 3. CRITICAL: holyc-inference benchmark launcher still encodes writable TempleOS boot image semantics

Evidence:
- `holyc-inference/bench/qemu_prompt_bench.py:146-158` builds a QEMU command with `-nic none`, `-serial stdio`, `-display none`, and `-drive f"file={image},format=raw,if=ide"`; it does not include `readonly=on`.
- `holyc-inference/tests/test_qemu_prompt_bench.py:19-33` asserts that exact writable drive fragment, so the test suite locks in the mutable image contract.
- `holyc-inference/bench/qemu_prompt_bench.py:315` describes `--image` as the TempleOS disk image to boot in QEMU.

Assessment:
The inference benchmark preserves the air-gap but not the immutable-image invariant it inherits from TempleOS. Because the test asserts the drive fragment without `readonly=on`, a future fix will need both launcher and test updates before benchmark artifacts can be used as Law 10-compliant evidence.

### 4. WARNING: TempleOS `qemu-holyc-load-test.sh` air-gap evidence check can fail independently of argv safety

Evidence:
- `TempleOS/automation/qemu-holyc-load-test.sh:120-127` launches QEMU with `-nic none` and redirects QEMU stdout/stderr to `QEMU_META_LOG`.
- `TempleOS/automation/qemu-holyc-load-test.sh:136-138` then greps `QEMU_META_LOG` for `-nic none`.
- The script does not echo the constructed QEMU command into `QEMU_META_LOG` before launch, so the evidence check depends on QEMU itself emitting its argv.

Assessment:
The launch line itself is air-gapped, so this is not a Law 2 violation. It is an evidence-quality drift: a safe launch can fail the proof check or produce no durable command evidence. The fix is to write a local pre-launch metadata line containing the exact argv, including `-nic none`, before executing QEMU.

## Non-Findings

- ISO boot paths using `-cdrom` were not counted as Law 10 violations by themselves.
- Writable shared/payload images were not counted as Law 10 violations when they are clearly scratch media rather than installed OS images.
- holyc-inference `qemu_prompt_bench.py` does reject explicit networking extras in `qemu_args`; the problem there is the missing read-only boot-image flag.

## Summary

Findings: 4 total.

- Critical: 2
- Warning: 2

No current evidence shows either repo intentionally executing WS8 networking work or adding a TempleOS guest network stack. The drift is enforcement fidelity: launchers and tests still prove air-gap more strongly than immutable-image safety, and two TempleOS wrappers expose runtime argument paths that source scanners cannot police.

## Read-Only Verification Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/qemu-headless.sh | sed -n '1,130p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/qemu-smoke.sh | sed -n '1,120p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/qemu-holyc-load-test.sh | sed -n '115,140p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/enforce-templeos-airgap.sh | sed -n '55,69p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py | sed -n '146,160p;315,318p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_qemu_prompt_bench.py | sed -n '19,33p'
```
