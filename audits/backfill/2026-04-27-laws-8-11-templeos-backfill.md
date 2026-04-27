# Laws 8-11 TempleOS Compliance Backfill

Timestamp: 2026-04-27T13:59:28Z

Scope: Compliance backfill for Laws 8-11 against `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS`. This audit was read-only against TempleOS, did not inspect or control live loops, did not run QEMU/VM commands, and did not modify trinity source code.

Law introduction points in `temple-sanhedrin`:

| Law | Sanhedrin commit | Timestamp |
| --- | --- | --- |
| Law 8, Book of Truth immediacy | `83220a9443b2d875abc03bda73794b7b82260f69` | 2026-04-12T14:42:05+02:00 |
| Law 9, resource supremacy / HLT | `63399d9b4093200e17c0af64a5986d95c6bbb615` | 2026-04-12T14:48:30+02:00 |
| Laws 10-11, immutable image / local-only access | `5edba91f54a6aace364c195547d0386d76044527` | 2026-04-12T14:58:12+02:00 |

TempleOS history sampled:

| Metric | Count |
| --- | ---: |
| Total TempleOS commits on current branch | 1,949 |
| Commits before Law 8 existed | 70 |
| Commits at/after Law 8 timestamp | 1,879 |
| Commits at/after Laws 10-11 timestamp | 1,877 |
| Core-path commits at/after Law 8 timestamp | 845 |
| Automation/script commits at/after Law 8 timestamp | 1,303 |

## Findings

### 1. CRITICAL: Law 10 backfill failure in QEMU disk-image boot wrappers

`automation/qemu-headless.sh` and `automation/qemu-smoke.sh` both accept `DISK_IMAGE` and pass it to QEMU with `-drive file=...,format=raw,if=ide`, but neither includes `readonly=on`. Law 10 explicitly lists "QEMU launch commands missing `-drive readonly=on` for the OS image" as a violation.

Evidence:

| File | Lines | Evidence |
| --- | --- | --- |
| `automation/qemu-headless.sh` | 84-85 | `qemu_args+=( -drive "file=$DISK_IMAGE,format=raw,if=ide" )` |
| `automation/qemu-smoke.sh` | 75-76 | `qemu_args+=(-drive "file=$DISK_IMAGE,format=raw,if=ide")` |

Historical persistence: `automation/qemu-smoke.sh` existed before Law 10 and remains non-compliant after Law 10. The same DISK_IMAGE pattern was introduced into `automation/qemu-headless.sh` by TempleOS commit `48608e22561985badab9a5b19c54d862b3658181` on 2026-04-12T16:14:58+02:00, after Laws 8-11 were already in force, and persisted to HEAD.

Compliance score: Law 10 QEMU immutable-image backfill = 0/2 primary DISK_IMAGE wrappers compliant.

### 2. CRITICAL: Law 2/Law 10 escape hatch through unfiltered `EXTRA_ARGS`

Both primary QEMU wrappers append unparsed `EXTRA_ARGS` after the enforced baseline arguments. That allows a caller to inject additional QEMU device, network, serial, or drive flags after the wrapper has printed "air-gap" evidence. Even if QEMU rejects some conflicting combinations, the wrapper policy does not forbid them before launch.

Evidence:

| File | Lines | Evidence |
| --- | --- | --- |
| `automation/qemu-headless.sh` | 92-95 | `extra_parts=( $EXTRA_ARGS )` then append to `qemu_args` |
| `automation/qemu-smoke.sh` | 83-86 | same append pattern |

Historical persistence: `EXTRA_ARGS` appeared in `automation/qemu-smoke.sh` before Law 8 and in `automation/qemu-headless.sh` at commit `48608e22561985badab9a5b19c54d862b3658181`; no later commit removes or filters it. This is a backfill violation because the post-law wrapper still permits user-supplied launch mutations around immutable-image and air-gap constraints.

Compliance score: QEMU argument hardening = 0/2 primary wrappers compliant.

### 3. WARNING: Network-dependent ISO fetch remains in a validation path

`automation/qemu-compile-test.sh` downloads `https://templeos.org/Downloads/TempleOS.ISO` with `curl` when the ISO is absent. Guest networking is disabled in the eventual QEMU command, but the validation path itself depends on external network availability and silently skips the compile test when the download fails.

Evidence:

| File | Lines | Evidence |
| --- | --- | --- |
| `automation/qemu-compile-test.sh` | 12-13 | `ISO_URL="https://templeos.org/Downloads/TempleOS.ISO"` |
| `automation/qemu-compile-test.sh` | 23-29 | `curl -sL "$ISO_URL" -o "$ISO_FILE"` then `exit 0` on failure |

Historical persistence: the `curl -sL` pattern appears from commit `d231ad137c7818f566ae8561194891ff5e2c0fb3` on 2026-04-12T15:54:08+02:00 and remains at HEAD. This is host-side automation, so it is not a guest networking breach, but it weakens Law 2 auditability because missing local artifacts produce skipped validation rather than a hard failure.

Compliance score: network-independent validation artifact handling = 0/1 for this compile harness.

### 4. INFO: Core-path networking backfill did not find a guest stack addition

The post-Law-8 history search for `socket`, `TCP`, `UDP`, `DNS`, `DHCP`, `HTTP`, `TLS`, `network`, `NIC`, `E1000`, and `rtl8139` across `Kernel`, `Adam`, `Apps`, `Compiler`, `0000Boot`, and automation did not identify a core guest networking stack addition. Hits were concentrated in automation air-gap assertions and textual policy checks rather than guest drivers or protocols.

Compliance score: core guest networking additions found by this lexical pass = 0 candidate violations.

### 5. INFO: Book of Truth source-mask "Disable" is mask algebra, not a persisted logging kill switch

The only current core hit matching a disable-shaped Book of Truth API was `BookTruthSourceMaskDisable` in `Kernel/BookOfTruth.HC`. Its implementation clamps a caller-provided mask, clears a bit in a local return value, prints a status line, and does not assign to a global Book of Truth enable flag in the inspected block. Current callers are declarations only (`Kernel/BookOfTruth.HC`, `Kernel/KExts.HC`).

Evidence:

| File | Lines | Evidence |
| --- | --- | --- |
| `Kernel/BookOfTruth.HC` | 16709-16733 | computes `disabled_mask` from a local mask and returns it |

Backfill result: no Law 3/8/9 violation was confirmed from this symbol alone, but the name is easy for future auditors to misclassify. A clearer name such as source-mask-subtract would reduce false positives if builders are permitted to touch this area later.

## Backfill Summary

| Rule area | Score | Result |
| --- | ---: | --- |
| Law 8 immediacy / metal proximity | not fully machine-scored | no confirmed violation in this pass |
| Law 9 resource supremacy / HLT | not fully machine-scored | no confirmed violation in this pass |
| Law 10 immutable image, QEMU readonly | 0/2 | critical violation |
| Law 11 local-only access | not fully machine-scored | no confirmed violation in this pass |
| Law 2 air-gap wrapper hardening | 0/2 for `EXTRA_ARGS` filtering | critical escape risk |
| Network-independent validation | 0/1 | warning |

## Reproduction Commands

Run these read-only commands from `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS`:

```bash
git rev-list --count HEAD
git rev-list --count --before='2026-04-12T14:42:05+02:00' HEAD
git rev-list --count --since='2026-04-12T14:42:05+02:00' HEAD
git log --since='2026-04-12T14:42:05+02:00' --format='%H' -- Kernel Adam Apps Compiler 0000Boot | wc -l
git log --since='2026-04-12T14:42:05+02:00' --format='%H' -- automation '*.sh' | wc -l
git grep -n -- '-drive' -- automation '*.sh' templeos-compile-test.sh
git grep -n -- 'readonly=on' -- automation '*.sh' templeos-compile-test.sh
git grep -n -E 'qemu-system|qemu-' -- automation/qemu-headless.sh automation/qemu-compile-test.sh automation/qemu-smoke.sh templeos-compile-test.sh
git grep -n -E 'BookTruth.*(Disable|Clear|Reset|Export|Dump|Copy)|Disable.*BookTruth|Clear.*BookTruth|Serial.*(Forward|Proxy|Stream)|socket|TCP|UDP|DNS|DHCP|HTTP|TLS|network' -- Kernel Adam Apps Compiler 0000Boot
```

## Recommendation

Sanhedrin should open blocker issues for the two critical QEMU wrapper findings. The safe target behavior is: always launch OS disk images with `readonly=on`; reject or allowlist `EXTRA_ARGS` so networking, mutable drive, and serial forwarding flags cannot be injected; and make missing local ISO artifacts fail validation instead of downloading or silently skipping.
