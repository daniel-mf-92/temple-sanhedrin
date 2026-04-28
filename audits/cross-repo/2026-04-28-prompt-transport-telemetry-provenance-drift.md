# Cross-Repo Prompt Transport and Telemetry Provenance Drift Audit

- Audit angle: cross-repo invariant checks
- Audit time: `2026-04-28T04:53:24+02:00`
- TempleOS HEAD inspected: `8786038c2e1ed97a422a5bfeebafa9ebfb812f8a`
- holyc-inference HEAD inspected: `86171b5496d40ac50e5b742a45c00567159ca793`
- Sanhedrin HEAD before this report: `f40772f01a582c4a187c5681ee63a408534981fe`
- Scope: read-only review of the TempleOS north-star/QEMU harness surfaces and the holyc-inference QEMU prompt benchmark surfaces. No TempleOS or holyc-inference files were modified, and no QEMU or VM command was executed.

## Summary

The repos agree on the high-level destination: an air-gapped TempleOS guest runs HolyC and emits serial evidence. They still drift on the lower-level contract for getting prompts and payloads into the guest and for proving that emitted telemetry came from a real TempleOS run rather than a host fixture.

TempleOS harnesses center on a second FAT disk image containing HolyC files and serial output from the guest. holyc-inference's benchmark runner centers on host stdin/environment variables plus a `BENCH_RESULT` record parser. That is usable for host fixture smoke tests, but it is not yet a cross-repo guest contract.

## Findings

### Finding WARNING-001: Prompt transport is host stdin/env in holyc-inference, but shared-disk/serial in TempleOS

Laws implicated:
- Law 5: North Star Discipline
- Law 2 remains protected by reviewed `-nic none` surfaces; this is not an air-gap breach.

Evidence:
- `holyc-inference/bench/qemu_prompt_bench.py:407-421` sets `HOLYC_BENCH_PROMPT`, `HOLYC_BENCH_PROMPT_ID`, and passes the prompt string to the launched process on stdin.
- `holyc-inference/bench/fixtures/qemu_synthetic_bench.py:22-25` proves the fixture contract by reading `HOLYC_BENCH_PROMPT_ID` from the host environment and prompt text from stdin.
- `TempleOS/MODERNIZATION/LOOP_PROMPT.md:91-95` says the TempleOS compile workflow creates a FAT disk image, boots with that disk attached, and checks serial output.
- `TempleOS/automation/qemu-holyc-load-test.sh:100-129` creates a FAT `SHARED_IMG`, copies HolyC files into it, boots the ISO with that disk, and captures serial output.

Impact:

For a real TempleOS guest, host environment variables are not guest environment variables. Host stdin to `qemu-system-x86_64` is also not a normalized prompt file or guest API. A benchmark can therefore be well-formed for the synthetic fixture while leaving the real TempleOS prompt-ingest path undefined.

Recommendation:

Define one guest-visible prompt transport: for example, `shared.img:/BENCH/PROMPTS.JSONL` plus `shared.img:/BENCH/MANIFEST.JSON`, loaded by HolyC and echoed in serial telemetry by prompt id and suite hash. Keep stdin/env only as host-fixture compatibility, not as the cross-repo invariant.

### Finding WARNING-002: Synthetic benchmark artifacts can be green without proving guest execution

Laws implicated:
- Law 5: North Star Discipline

Evidence:
- `holyc-inference/bench/fixtures/qemu_synthetic_bench.py:2-6` explicitly says the fixture is not an emulator and emits deterministic `BENCH_RESULT` telemetry without booting a guest.
- `holyc-inference/bench/results/qemu_prompt_bench_latest.json:4-15` records a passing benchmark command whose executable is `bench/fixtures/qemu_synthetic_bench.py`, not QEMU.
- `holyc-inference/bench/results/qemu_prompt_bench_latest.json:208-216` records the environment `qemu_bin`/`qemu_path` as the synthetic fixture and `qemu_version` as null.
- `holyc-inference/bench/results/qemu_prompt_bench_latest.md:3-17` reports `Status: pass`, `Runs: 6`, and zero tok/s variability for that fixture output.

Impact:

The artifact label `QEMU Prompt Benchmark` can look like guest proof even when it is host-only synthetic telemetry. This is not wrong for smoke testing report generation, but it is unsafe as cross-repo evidence for the TempleOS or inference north stars.

Recommendation:

Require an explicit provenance field such as `execution_mode: synthetic|guest-qemu`, `guest_boot_observed: true|false`, and `templeos_serial_source: file|stdio|fixture`. Sanhedrin should accept synthetic mode only for host report-tool validation, never for north-star or release proof.

### Finding WARNING-003: TempleOS north-star docs require `shared.img`, but the current north-star script does not attach it

Laws implicated:
- Law 5: North Star Discipline

Evidence:
- `TempleOS/MODERNIZATION/NORTH_STAR.md:17-21` defines the concrete north-star command with `-drive file=shared.img,format=raw,if=ide` and says a HolyC program on `shared.img` emits the required serial lines.
- `TempleOS/automation/north-star-e2e.sh:21-26` boots only `-cdrom "$ISO"` with `-nic none`, `-nographic`, serial output, monitor disabled, and no attached `shared.img`.
- `holyc-inference/NORTH_STAR.md:15-18` says the Q4_0 GPT-2 weight blob lives on `shared.img` and the HolyC program loads weights before serial output.

Impact:

The common second-drive path is the natural bridge between modernization and inference, but one of TempleOS's top-level proof scripts currently omits it. That makes it harder to converge on a single guest packaging contract for HolyC demos, prompts, and model weights.

Recommendation:

Restore the second-drive invariant in the TempleOS north-star script or update the docs if the intended contract changed. For cross-repo use, reserve `shared.img` for payload/model/prompt data and require serial output to include the payload manifest hash it consumed.

### Finding WARNING-004: Benchmark telemetry does not yet prove the bit-exact next-token invariant

Laws implicated:
- Law 5: North Star Discipline
- Law 4 remains scoped to integer runtime math; this finding is about evidence, not observed floating-point runtime code.

Evidence:
- `holyc-inference/NORTH_STAR.md:15-20` requires a fixed prompt, next-token output over serial, bit-exact match to the reference, wall time under 30 seconds, and memory under 256 MB.
- `holyc-inference/bench/qemu_prompt_bench.py:47` looks for `BENCH_RESULT` JSON or key/value output.
- `holyc-inference/bench/qemu_prompt_bench.py:312-397` normalizes tokens, elapsed time, throughput, TTFT, and memory, but not `next_token_id`, `reference_token_id`, `reference_digest`, or `match`.
- `holyc-inference/bench/qemu_prompt_bench.py:581-607` can gate token count, throughput, and memory presence/minimums, but it cannot fail a run whose token id differs from the reference.

Impact:

A benchmark can pass as a performance artifact while failing the actual inference north-star correctness contract. The current fields are useful throughput evidence, but they are insufficient to show that the TempleOS guest produced the required bit-exact next token.

Recommendation:

Extend `BENCH_RESULT` with `prompt_token_ids`, `next_token_id`, `reference_token_id`, `reference_digest`, and `match=true`. Add a benchmark gate that fails when `match` is absent or false for north-star profiles.

## Positive Observations

- The reviewed TempleOS and holyc-inference QEMU surfaces keep explicit `-nic none` evidence in the paths inspected for this audit.
- The host fixture is clearly labeled in its own source as non-emulator synthetic output; the remaining gap is artifact-level provenance, not hidden behavior.
- No WS8 networking task was executed or recommended.

## Safety Notes

- No TempleOS guest networking stack, NIC driver, socket, TCP/IP, UDP, TLS, DHCP, DNS, HTTP, or remote runtime service was added or enabled.
- No QEMU or VM command was executed during this audit.
- No TempleOS or holyc-inference source code was modified.
- Recommendations preserve the air-gap and keep core guest implementation in HolyC.

## Commands Run

Read-only commands only:

```bash
git -C ../templeos-gpt55 rev-parse HEAD
git -C ../holyc-gpt55 rev-parse HEAD
git rev-parse HEAD
nl -ba ../templeos-gpt55/MODERNIZATION/NORTH_STAR.md | sed -n '1,80p'
nl -ba ../holyc-gpt55/NORTH_STAR.md | sed -n '1,80p'
nl -ba ../holyc-gpt55/bench/qemu_prompt_bench.py | sed -n '1,1260p'
nl -ba ../templeos-gpt55/automation/north-star-e2e.sh | sed -n '1,260p'
nl -ba ../holyc-gpt55/bench/results/qemu_prompt_bench_latest.json | sed -n '1,220p'
nl -ba ../holyc-gpt55/bench/results/qemu_prompt_bench_latest.md | sed -n '1,160p'
nl -ba ../holyc-gpt55/bench/README.md | sed -n '180,260p'
nl -ba ../holyc-gpt55/bench/fixtures/qemu_synthetic_bench.py | sed -n '1,220p'
nl -ba ../templeos-gpt55/automation/qemu-holyc-load-test.sh | sed -n '1,180p'
nl -ba ../templeos-gpt55/MODERNIZATION/LOOP_PROMPT.md | sed -n '80,110p'
```

Finding count: 4 warnings.
