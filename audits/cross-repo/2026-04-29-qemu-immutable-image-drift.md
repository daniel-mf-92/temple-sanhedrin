# Cross-Repo Audit: QEMU Immutable Image Contract Drift

- Timestamp: 2026-04-29T06:06:21Z
- Audit lane: retroactive / historical / cross-repo invariant check
- Repos inspected:
  - `/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55`
  - `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55`
  - `/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55`
- Laws in scope: Law 2 Air-Gap Sanctity, Law 10 Immutable OS Image, cross-repo Trinity policy parity

## Summary

The Trinity policy-doc sync gate passes for `secure-local`, `dev-local`, quarantine/hash, GPU/IOMMU/Book-of-Truth, attestation/policy digest, and drift-guard language. Air-gap enforcement is also consistently present in the inspected QEMU launch surfaces.

However, the concrete QEMU disk-image contract has drifted from LAWS.md Law 10. Both TempleOS host launch tooling and holyc-inference benchmark tooling can launch a TempleOS disk image without `readonly=on`. This leaves the air-gap invariant well covered while the immutable-OS-image invariant is not enforced across the same launch surfaces.

## Findings

### CRITICAL: TempleOS headless disk boot can mount the OS image writable

- Law: Law 10 - Immutable OS Image
- Evidence: `/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/qemu-headless.sh:87-88`
- Current launch fragment: `-drive "file=$DISK_IMAGE,format=raw,if=ide"`
- Required invariant: QEMU launch commands for the OS image must include `readonly=on`.
- Impact: A caller using `DISK_IMAGE=/path/to/TempleOS.img automation/qemu-headless.sh` gets `-nic none`, but the boot disk is not explicitly read-only. That conflicts with the immutable installed-OS rule and can let test or benchmark runs mutate the OS image.

### CRITICAL: holyc-inference prompt benchmark assumes a writable TempleOS image

- Law: Law 10 - Immutable OS Image; cross-repo invariant with TempleOS guest safety
- Evidence: `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/qemu_prompt_bench.py:394-406`
- Current generated command from a dry run:
  `qemu-system-x86_64 -nic none -serial stdio -display none -drive file=/tmp/TempleOS.audit.img,format=raw,if=ide`
- Documentation repeats the same shape at `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/README.md:483-508` and raw QEMU example line 548.
- Impact: The inference bench validates and documents air-gapped guest execution, but it does not preserve the TempleOS immutable image contract. This means benchmark artifacts can look compliant on Law 2 while violating Law 10.

### WARNING: Existing Trinity policy sync does not cover concrete QEMU immutability

- Evidence: `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/automation/check-trinity-policy-sync.sh` checks profile, quarantine, GPU, attestation, and drift language, but no `readonly=on` or immutable-QEMU launch invariant.
- Gate result: `passed=21 failed=0 drift=false` when pointed at the three sibling worktrees.
- Impact: Cross-repo docs can remain in sync while shared launch tooling drifts from the immutable-OS contract. This is a coverage gap in historical audit tooling, not a source-code change request for this audit lane.

## Non-Findings

- Air-gap flags were present in the inspected launch paths:
  - TempleOS `automation/qemu-headless.sh` injects `-nic none` or legacy `-net none`.
  - TempleOS `automation/qemu-compile-test.sh` uses `-nic none`.
  - holyc-inference `bench/qemu_prompt_bench.py` injects `-nic none` and rejects network devices/backends.
- `automation/qemu-compile-test.sh` uses `-cdrom "$ISO_FILE"` for the TempleOS OS medium and a separate shared test disk. The shared disk is intentionally writable test media, so the missing `readonly=on` on `SHARED_DISK` is not counted as an OS-image violation.

## Verification Commands

```bash
TRINITY_TEMPLE_DOC=/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/MODERNIZATION/MASTER_TASKS.md \
TRINITY_INFERENCE_DOC=/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/LOOP_PROMPT.md \
TRINITY_SANHEDRIN_DOC=/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55/LOOP_PROMPT.md \
  /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/automation/check-trinity-policy-sync.sh

python3 bench/qemu_prompt_bench.py \
  --image /tmp/TempleOS.audit.img \
  --prompts bench/prompts/smoke.jsonl \
  --output-dir /tmp/gpt55-qemu-dry-run-audit \
  --max-launches 10 \
  --dry-run

rg --pcre2 -n -- '-drive[^\n]*(TempleOS\.img|DISK_IMAGE|SHARED_DISK|format=raw,if=ide)(?![^\n]*readonly=on)' \
  /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/qemu_prompt_bench.py \
  /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/README.md \
  /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/qemu-headless.sh \
  /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/qemu-compile-test.sh
```

## Recommended Backlog Items

- Add `readonly=on` to TempleOS `automation/qemu-headless.sh` only for `DISK_IMAGE` that represents the OS image; keep separate data/shared disks writable only when explicitly declared non-OS media.
- Add `readonly=on` to holyc-inference `qemu_prompt_bench.py` for the `--image` boot disk, and reject extra QEMU args that override that OS drive with a writable equivalent.
- Extend Sanhedrin or inference static QEMU audit coverage to check both `-nic none` and OS-image `readonly=on` so Law 2 and Law 10 are enforced together.

