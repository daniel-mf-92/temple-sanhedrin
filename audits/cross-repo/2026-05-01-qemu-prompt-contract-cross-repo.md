# Cross-Repo Audit: QEMU Prompt Benchmark Contract vs TempleOS Safety Laws

Timestamp: 2026-05-01T20:14:43Z

Scope: historical cross-repo invariant check, read-only against TempleOS and holyc-inference worktrees.

Repos examined:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55` at `b3fe311496f417fc09bf5ab7fa3ab313483ad9f3`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55` at `a70776642a09de7ed01eb75aaaebbdd3243f84c2`
- Sanhedrin laws: `/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55/LAWS.md`

Audit angle: Cross-repo invariant checks.

## Summary

The inference repo's host-side QEMU prompt benchmark now carries strong air-gap evidence (`-nic none`, network-argument rejection, serial stdio capture), but its launch contract has drifted from the TempleOS immutable-image requirement and from a concrete guest-side prompt ingestion contract.

Findings:
- 1 CRITICAL: QEMU benchmark drive is writable by default, conflicting with Law 10's `readonly=on` requirement for OS images.
- 1 WARNING: Benchmark prompt/result protocol is specified by host tooling, but no matching TempleOS guest-side `BENCH_RESULT`/prompt ingestion implementation was found outside generated/log fixtures.
- 1 INFO: Air-gap network disabling is aligned across both repos for this benchmark path.

## Evidence Reviewed

LAWS.md:
- Lines 27-35: Law 2 requires every QEMU/VM command to carry `-nic none` or `-net none`.
- Lines 140-149: Law 10 requires QEMU launch commands to include `-drive readonly=on` for the OS image.
- Lines 13-25 and 51-58: HolyC and integer-runtime purity still allow host-side Python tooling outside core paths.

holyc-inference:
- `bench/qemu_prompt_bench.py:690-704` builds QEMU commands with `-nic none`, `-serial stdio`, `-display none`, and `-drive file=<image>,format=raw,if=ide`.
- `bench/qemu_prompt_bench.py:964-999` sends the prompt to the QEMU process stdin.
- `bench/qemu_prompt_bench.py:1080-1091` also places `HOLYC_BENCH_PROMPT` and `HOLYC_BENCH_PROMPT_ID` in the host child environment.
- `bench/README.md:1913-1918` documents guest output as optional `BENCH_RESULT` JSON with token/time/prompt echo telemetry.
- `bench/fixtures/qemu_synthetic_bench.py` emits that telemetry, but it is explicitly a synthetic non-emulator fixture.

TempleOS:
- A repo-wide search excluding `bench/**`, `automation/logs/**`, and pycache found no committed TempleOS source contract for `BENCH_RESULT`, `HOLYC_BENCH_PROMPT`, `expected_tokens`, or `prompt_sha256`.
- TempleOS has extensive QEMU air-gap/report automation, but this audit did not find evidence that the holyc-inference QEMU benchmark's `-drive` contract is mirrored with `readonly=on`.

## Finding 1: Writable QEMU OS Image in Inference Benchmark

Severity: CRITICAL

Law impact: Law 10, Immutable OS Image.

The inference benchmark constructs the boot image argument as:

```text
-drive file=<image>,format=raw,if=ide
```

It does not include `readonly=on`. LAWS.md explicitly classifies "QEMU launch commands missing `-drive readonly=on` for the OS image" as a Law 10 violation. Even though the file lives in host-side inference tooling, the command boots a TempleOS disk image and therefore can mutate the guest image unless QEMU is forced read-only.

Cross-repo invariant violated:
- TempleOS safety law: OS image must be immutable once installed.
- holyc-inference assumption: benchmark can boot a TempleOS disk image with the default writable block device.

Recommended remediation:
- In holyc-inference host tooling, add `readonly=on` to the generated OS image drive argument.
- Add a host-side smoke/audit assertion that fails if any benchmark artifact command has `-drive file=...` without `readonly=on`.
- Preserve `-nic none`; do not use network-backed disks, sockets, or remote services as an alternative.

## Finding 2: Prompt/Result Protocol Lacks a Committed Guest Counterpart

Severity: WARNING

Law impact: Law 5, No Busywork; cross-repo correctness risk for the inference north-star path.

The inference benchmark expects a guest-visible prompt path and parses guest output from `BENCH_RESULT` JSON, including `tokens`, `prompt_sha256`, and `prompt_bytes`. The host sends the prompt through QEMU stdin and host environment variables, but this audit found no matching committed TempleOS guest-side protocol in the TempleOS repo outside generated automation/log fixtures.

This means benchmark pass/fail evidence can be satisfied by the synthetic fixture while the real TempleOS guest contract remains unproven. The risk is not a direct Law 1 or Law 4 violation; it is that holyc-inference can accumulate benchmark/reporting work that is not tied to an executable HolyC guest integration.

Cross-repo invariant at risk:
- holyc-inference assumes a guest emits prompt echo and token telemetry.
- TempleOS committed source does not currently expose a matching prompt ingestion/result emission contract under the searched tokens.

Recommended remediation:
- Define the real guest protocol in one short spec shared by both repos: transport, prompt framing, output line format, required fields, and failure behavior.
- Add a host-only contract test that distinguishes synthetic fixture telemetry from real guest telemetry.
- Keep implementation HolyC-only for guest/core code and keep QEMU air-gapped.

## Finding 3: Air-Gap Launch Flag Alignment

Severity: INFO

Law impact: Law 2, Air-Gap Sanctity.

The holyc-inference benchmark builder injects `-nic none` and rejects conflicting networking arguments before command construction. This aligns with TempleOS Law 2 and with the hard safety requirement for any QEMU/VM command. No QEMU command was executed during this audit.

Residual risk:
- The benchmark treats legacy `-net none` as redundant and rejects it in favor of `-nic none`; this is stricter than LAWS.md, which accepts either, but it is compatible with the hard air-gap rule.

## Audit Method

Commands were read-only:

```text
rg -n "BENCH_RESULT|HOLYC_BENCH_PROMPT|expected_tokens|prompt_sha256" .
rg -n "def build_command|drive|readonly|serial|nic none|-nic" bench/qemu_prompt_bench.py
nl -ba bench/qemu_prompt_bench.py
nl -ba bench/README.md
nl -ba LAWS.md
git rev-parse HEAD
```

No TempleOS or holyc-inference files were modified. No QEMU/VM command was run.
