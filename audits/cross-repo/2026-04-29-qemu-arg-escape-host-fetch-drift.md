# Cross-Repo QEMU Arg Escape and Host Fetch Drift Audit

- Audit angle: cross-repo invariant checks
- Audit time: `2026-04-29T19:13:50+02:00`
- TempleOS HEAD: `d9c3b620dbe9cf8bde884ed11c8ec1df99a68e89`
- holyc-inference HEAD: `485af0ea41a239c8393542d6e0e2fc5944f30f53`
- Scope: read-only review of QEMU launcher argument handling and host-side network fetch surfaces. No TempleOS or holyc-inference source was modified. No QEMU/VM command, WS8 networking task, socket/TCP/IP/UDP/DNS/DHCP/HTTP/TLS work, package download, or live liveness check was executed.

## Summary

TempleOS and holyc-inference agree on the policy text that QEMU guest networking must be disabled. They do not enforce the same invariant at the argument-boundary level. holyc-inference validates user-supplied `--qemu-arg` values and rejects network backends/devices before constructing the command. TempleOS `qemu-headless.sh` and `qemu-smoke.sh` add `-nic none` or `-net none`, but then append unvalidated `EXTRA_ARGS` last. A caller can therefore add a second QEMU network backend or NIC device after the no-network flag, and the wrapper still prints that it is enforcing the air-gap.

Separately, TempleOS `qemu-compile-test.sh` still has an executable `curl` path for fetching `TempleOS.ISO` when missing. That is host-side tooling, not a guest network stack, but it conflicts with the hard requirement to reject network-dependent validation/package-fetch paths.

## Findings

### CRITICAL-001: TempleOS `qemu-headless.sh` has a late unvalidated QEMU argument escape hatch

Laws implicated:
- Law 2: Air-Gap Sanctity

Evidence:
- `TempleOS/automation/qemu-headless.sh:38-41` says guest networking is forcibly disabled and names `-nic none` / `-net none`.
- `TempleOS/automation/qemu-headless.sh:76-82` appends the no-network flag.
- `TempleOS/automation/qemu-headless.sh:92-95` splits `EXTRA_ARGS` and appends the tokens after the no-network flag.
- `TempleOS/automation/qemu-headless.sh:98-100` reports the selected air-gap flag even if appended extra arguments later introduce network devices.

Impact:

QEMU accepts multiple device/backend options. Because `EXTRA_ARGS` is appended after the guard, a caller can supply values such as `-nic user`, `-netdev user,id=n0`, or `-device virtio-net-pci` and produce a command line that contains both `-nic none` and a networking surface. That violates the project rule that any QEMU/VM command must explicitly disable networking and must not add NIC devices, sockets, user-mode networking, taps, bridges, or host forwarding.

Recommendation:

Reject forbidden QEMU network arguments before launch, using the holyc-inference pattern as the reference: allow only `-nic none`, `-nic=none`, `-net none`, or `-net=none`, and fail closed on `-netdev`, `-device` NIC models, `tap`, `bridge`, `user`, and host-forwarding tokens. Prefer an argv array input over whitespace-splitting `EXTRA_ARGS`.

### CRITICAL-002: TempleOS `qemu-smoke.sh` repeats the same late argument escape hatch

Laws implicated:
- Law 2: Air-Gap Sanctity

Evidence:
- `TempleOS/automation/qemu-smoke.sh:34-37` states the runner always disables guest networking.
- `TempleOS/automation/qemu-smoke.sh:67-73` appends `-nic none` or `-net none`.
- `TempleOS/automation/qemu-smoke.sh:83-86` appends unvalidated `EXTRA_ARGS` after the no-network flag.
- `TempleOS/automation/qemu-smoke.sh:89-98` launches the final command without a post-append network-argument check.

Impact:

The smoke path is a core validation surface. If it can be made to run with an appended NIC/backend while still containing the earlier `-nic none` token, downstream evidence that only greps for no-network text can overstate Law 2 compliance.

Recommendation:

Share one QEMU argument validator between `qemu-headless.sh`, `qemu-smoke.sh`, and any compile/batch wrappers. The validator should inspect the final argv immediately before execution and fail if any forbidden network option remains.

### WARNING-001: holyc-inference has a stronger QEMU argument-boundary guard than TempleOS

Laws implicated:
- Law 2: Air-Gap Sanctity
- Law 5: North Star Discipline, because cross-repo benchmark evidence depends on equivalent QEMU safety semantics

Evidence:
- `holyc-inference/bench/qemu_prompt_bench.py:114-143` rejects user-supplied `-nic` values other than `none`, `-net` values other than `none`, all `-netdev` values, and common NIC device models.
- `holyc-inference/bench/qemu_prompt_bench.py:146-159` calls the rejector before prepending `-nic none` and appending user `qemu_args`.
- `holyc-inference/bench/qemu_prompt_bench.py:315-318` exposes the user extension surface as repeated `--qemu-arg` tokens.
- Read-only import check confirmed the rejector blocks `['-nic','user']`, `['-nic=user']`, `['-netdev','user,id=n0']`, and `['-device=virtio-net-pci']`; it accepts `['-net','none']` as the documented legacy no-network fallback.

Impact:

The inference benchmark runner is currently safer than the TempleOS generic QEMU wrappers for user-supplied arguments. Cross-repo Sanhedrin reports should not treat "contains `-nic none`" as equivalent proof across the two repos until TempleOS validates final argv semantics too.

Recommendation:

Mirror the holyc-inference argument rejector in TempleOS host tooling, then add tests for the same forbidden cases in both repos. Keep the legacy `-net none` acceptance aligned with LAWS.md if the fallback remains policy.

### WARNING-002: TempleOS compile validation has an executable host-side ISO download path

Laws implicated:
- Law 2: Air-Gap Sanctity

Evidence:
- `TempleOS/automation/qemu-compile-test.sh:2-4` describes the helper as downloading the TempleOS ISO if missing, then booting QEMU.
- `TempleOS/automation/qemu-compile-test.sh:13` defines `ISO_URL="https://templeos.org/Downloads/TempleOS.ISO"`.
- `TempleOS/automation/qemu-compile-test.sh:23-29` runs `curl -sL "$ISO_URL" -o "$ISO_FILE"` when the ISO is absent, then exits 0 if the fetch fails.
- `TempleOS/automation/qemu-compile-test.sh:67-73` does use `-nic none` for the guest launch, so this is a host validation dependency issue, not guest networking enablement.

Impact:

The helper can turn a local compile validation into a network-dependent host step. On an air-gapped host it skips with exit 0, which can also make validation evidence look green while QEMU compilation did not actually run. This matches historical drift already seen in validation rows that mention skipped ISO downloads.

Recommendation:

Require a pre-provisioned local ISO path and fail with a distinct non-pass status when the ISO is missing. If a fetch helper is kept for developer convenience, it should be a separate manual tool outside the validation path and clearly out-of-scope for builder iterations.

## Positive Observations

- TempleOS `qemu-compile-test.sh` includes explicit `-nic none` in the actual guest launch path.
- holyc-inference `qemu_prompt_bench.py` rejects conflicting QEMU networking arguments before launch and has tests covering common forbidden forms.
- This audit found no new core TempleOS or inference runtime networking implementation in the inspected paths.

## Read-Only Verification

Commands run were file reads, greps, `git rev-parse`, `date`, and one local Python import of `holyc-inference/bench/qemu_prompt_bench.py` to exercise its pure argument rejector. No QEMU command was run, no VM was started, and no network command was executed.

Finding count: 4 total, 2 critical and 2 warnings.
