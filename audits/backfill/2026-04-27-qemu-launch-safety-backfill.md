# Compliance Backfill: QEMU Launch Safety

Scope: retroactive / historical compliance backfill for QEMU and VM launch safety. No TempleOS or holyc-inference source was modified, and no VM/QEMU command was executed.

Repos inspected:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55`
- Sanhedrin audit branch: `codex/sanhedrin-gpt55-audit`

Applicable rules:
- Law 2: any QEMU/VM command must explicitly disable networking; network-dependent build steps are violations.
- Law 10: QEMU launch commands must use `-drive readonly=on` for the OS image.
- User hard safety requirement: TempleOS guest remains fully air-gapped; any QEMU/VM command must explicitly use `-nic none` or `-net none`.

## Backfill Window

Historical file-introduction points checked:
- TempleOS `automation/qemu-smoke.sh`: introduced by `39c618ab03849f14f3a42ddcc1b093892c77e1d7` on 2026-04-11, air-gap hardened again by `5208dec84404be5099c49a3569969bf35837aab7` on 2026-04-27.
- TempleOS `automation/qemu-headless.sh`: introduced by `48608e22561985badab9a5b19c54d862b3658181` on 2026-04-12, air-gap hardened again by `5208dec84404be5099c49a3569969bf35837aab7` on 2026-04-27.
- TempleOS `automation/qemu-compile-test.sh`: introduced by `05af8d5111a0c9c129533d54036b4e4fcbed984b` on 2026-04-12, modified by `0793da89952294892335692c88715ec907522fe0` on 2026-04-22.
- holyc-inference `bench/qemu_prompt_bench.py`: introduced by `842e667a8fa4a152c96fd97d691dc49181609ca5` on 2026-04-27, hardened by `ab3ee4115c8b22c983b859bfe9ddc7a6b632e6a7` and `452824a7646a82bbdbb3f851303e6544047e922c`.

Current state summary:
- Air-gap flags are present in the canonical TempleOS QEMU launchers and in holyc-inference's benchmark runner.
- `readonly=on` appears in TempleOS modernization task text, but not in current canonical QEMU launch code.
- holyc-inference contains no `readonly=on` usage in its benchmark runner or benchmark docs.

## Finding CRITICAL-001: TempleOS DISK_IMAGE launch paths do not mark the OS image read-only

Applicable law:
- Law 10: immutable OS image.

Evidence:
- `automation/qemu-smoke.sh:78-80` appends `-drive "file=$DISK_IMAGE,format=raw,if=ide"` without `readonly=on`.
- `automation/qemu-headless.sh:87-89` appends `-drive "file=$DISK_IMAGE,format=raw,if=ide"` without `readonly=on`.
- `MODERNIZATION/MASTER_TASKS.md:218` explicitly says QEMU should use `-drive readonly=on` for the immutable OS image.
- `rg -n "readonly=on" automation MODERNIZATION README.md` only found the modernization task text, not launcher enforcement.

Backfill assessment:
The air-gap hardening commit `5208dec84404be5099c49a3569969bf35837aab7` fixed explicit no-network evidence but did not backfill Law 10 into the same launch builders. Any run using `DISK_IMAGE` can boot a mutable OS image unless the caller manually supplies a separate read-only drive argument, which the wrappers do not require or verify.

Risk:
A host-side smoke or headless test can mutate the TempleOS disk image during validation, invalidating the "full reinstall required for any change" invariant and making later audit evidence ambiguous.

Required remediation:
- In TempleOS launch wrappers, add `readonly=on` to the OS-image `DISK_IMAGE` drive path or split OS image and writable scratch image variables explicitly.
- Add a static guard that rejects QEMU launch builders with `DISK_IMAGE`/OS image drives missing `readonly=on`.

## Finding WARNING-001: holyc-inference QEMU benchmark enforces no-network but not immutable TempleOS image semantics

Applicable laws:
- Law 2: air-gap sanctity.
- Law 10: immutable OS image, when booting a TempleOS OS image.

Evidence:
- `bench/qemu_prompt_bench.py:144-165` rejects non-`none` NIC/network options and common virtual NIC devices.
- `bench/qemu_prompt_bench.py:170-182` builds every benchmark command with `-nic none`, then `-drive f"file={image},format=raw,if=ide"` without `readonly=on`.
- `rg -n "readonly=on" bench docs MASTER_TASKS.md` in holyc-inference found no matches.

Backfill assessment:
The inference benchmark runner is good on air-gap enforcement, but it can still boot its TempleOS image as a writable drive. Law 10 is formally written for the modernization agent, yet this runner boots a TempleOS guest and therefore shares the immutable-image risk when `--image` is an OS image rather than a disposable scratch disk.

Risk:
Performance benchmarks may silently change the guest image they measure, making later cross-build comparisons and Book-of-Truth assumptions depend on mutable state.

Required remediation:
- Treat benchmark `--image` as read-only by default, or require an explicit `--writable-scratch-image` for benchmark data exchange.
- Add tests asserting that the generated QEMU command contains both `-nic none` and OS-image `readonly=on`.

## Finding WARNING-002: TempleOS compile harness still has a host-side remote ISO download path

Applicable law:
- Law 2: network-dependent build steps are violations.

Evidence:
- `automation/qemu-compile-test.sh:13` defines `ISO_URL="https://templeos.org/Downloads/TempleOS.ISO"`.
- `automation/qemu-compile-test.sh:23-29` runs `curl -sL "$ISO_URL" -o "$ISO_FILE"` when the ISO is missing.
- The same QEMU command uses `-nic none` at `automation/qemu-compile-test.sh:70-71`, so this is not a guest NIC breach.

Backfill assessment:
This path predates the latest air-gap hardening and is host-side, but it is still a network-dependent test/build prerequisite. The script skips on curl failure, which limits damage, but the happy path still reaches a remote runtime dependency during a compile harness run.

Risk:
An audit or CI run can depend on network availability and an external ISO source, weakening reproducibility and violating the stricter local-only posture around TempleOS guest validation.

Required remediation:
- Remove automatic ISO download from the harness.
- Require a pre-provisioned local ISO path and fail closed with a clear message when missing.

## Non-Findings

- The current canonical TempleOS smoke/headless launchers explicitly add `-nic none` or `-net none` fallback.
- The current TempleOS shared `qemu-airgap-lib.sh` rejects `-netdev`, non-`none` `-nic`/`-net`, host/guest forwarding, and common virtual NIC devices in extra args.
- The holyc-inference benchmark runner rejects non-`none` networking options and common network device models before building its command.
- No WS8 networking execution was found in the inspected QEMU launch paths.

## Commands Run

- `sed -n '1,240p' LAWS.md`
- `rg -n "qemu|QEMU|qemu-system|-nic|-net none|-drive|readonly=on|netdev|user,|tap," ...`
- `git log --follow --date=iso-strict --format=... -- automation/qemu-smoke.sh`
- `git log --follow --date=iso-strict --format=... -- automation/qemu-headless.sh`
- `git log --follow --date=iso-strict --format=... -- automation/qemu-compile-test.sh`
- `git log --follow --date=iso-strict --format=... -- bench/qemu_prompt_bench.py`
- `nl -ba .../automation/qemu-smoke.sh`
- `nl -ba .../automation/qemu-headless.sh`
- `nl -ba .../automation/qemu-compile-test.sh`
- `nl -ba .../bench/qemu_prompt_bench.py`
- `rg -n "readonly=on" ...`
- `rg -n "curl|wget|http://|https://" ...`
