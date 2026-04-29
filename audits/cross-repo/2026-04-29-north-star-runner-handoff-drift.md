# Cross-Repo Audit: North-Star Runner Handoff Drift

Timestamp: 2026-04-29T22:18:56+02:00
Scope: TempleOS current `codex/modernization-loop` head (`00d1bdc`) and holyc-inference current `main` head (`485af0ea`)
Audit angle: Cross-repo invariant check
Finding count: 5

## Executive Summary

TempleOS and holyc-inference both describe a shared QEMU/serial north-star path, but the current runner surfaces do not compose into one executable handoff. No source code was modified in either repo. The air-gap invariant is preserved in the inspected QEMU command builders (`-nic none` is present), but the inference runner is still a placeholder around repo-local host assets instead of a TempleOS guest boot path.

## Evidence Reviewed

- `TempleOS/MODERNIZATION/NORTH_STAR.md`
- `TempleOS/automation/north-star-e2e.sh`
- `holyc-inference/NORTH_STAR.md`
- `holyc-inference/automation/north-star-e2e.sh`
- `holyc-inference/bench/qemu_prompt_bench.py`
- `holyc-inference/tests/test_qemu_prompt_bench.py`

Commands run:

```bash
rg -n "shared\\.img|run-holyc-forward|gpt2-124m-q4_0\\.bin|QEMU instance|Memory peak|-nic none|-drive readonly" \
  /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS \
  /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference

test -x /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/run-holyc-forward.sh
test -f /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/models/gpt2-124m-q4_0.bin
test -f /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/shared.img
```

Observed file presence:

- `TempleOS/automation/TempleOS.iso` exists.
- `TempleOS/automation/shared.img` is missing.
- `holyc-inference/models/gpt2-124m-q4_0.bin` is missing.
- `holyc-inference/automation/run-holyc-forward.sh` is missing.

## Findings

### 1. WARNING - Inference north-star runner does not execute the documented TempleOS guest path

`holyc-inference/NORTH_STAR.md:7-20` defines success as a HolyC forward pass inside the TempleOS guest, outputting a token over serial with QEMU wall-time and memory constraints. The actual `automation/north-star-e2e.sh` stops at a missing placeholder runner: lines 28-32 set `HOLYC_RUNNER="$REPO_DIR/automation/run-holyc-forward.sh"` and fail if it is absent. There is no QEMU launch, no TempleOS ISO or disk image handoff, and no guest serial capture in this north-star script.

Impact: inference can remain RED for a local placeholder reason even after TempleOS exposes a usable guest boot path, so the trinity cannot tell whether the integration failure is model/runtime work or runner wiring.

### 2. WARNING - Shared model artifact location is inconsistent across docs and runner code

`holyc-inference/NORTH_STAR.md:16` says the Q4_0 GPT-2 weight blob lives on `shared.img`. The runner instead checks `WEIGHTS="$REPO_DIR/models/gpt2-124m-q4_0.bin"` at `holyc-inference/automation/north-star-e2e.sh:5-13`. TempleOS defines `SHARED_IMG` separately at `TempleOS/automation/north-star-e2e.sh:12` and only attaches it if the file exists at lines 112-114.

Impact: neither repo currently owns a verifiable shared-disk layout for the model artifact. This blocks a deterministic handoff from host-prepared weights to guest HolyC load.

### 3. WARNING - QEMU boot contract diverges between TempleOS and inference benchmark tooling

TempleOS documents and implements a CD-ROM ISO boot with an optional IDE `shared.img` data disk: `TempleOS/MODERNIZATION/NORTH_STAR.md:17-18` and `TempleOS/automation/north-star-e2e.sh:101-114`. Inference benchmark tooling builds a different command around one required raw IDE image: `holyc-inference/bench/qemu_prompt_bench.py:146-160` and `--image` at lines 313-318.

Impact: the inference benchmark image is not classified as OS image vs writable data image. If it is an OS image, the command has no `readonly=on` evidence for LAWS.md Law 10. If it is only a data image, the command lacks an explicit TempleOS boot artifact. Either interpretation drifts from the TempleOS north-star contract.

### 4. WARNING - Inference north-star performance constraints are not enforced

`holyc-inference/NORTH_STAR.md:19-20` requires wall time under 30 seconds and memory peak under 256 MB. The runner uses `TIMEOUT=60` at `holyc-inference/automation/north-star-e2e.sh:9` and extracts a token from the placeholder runner output at lines 35-43. It does not measure guest wall time against the 30-second target or collect memory peak evidence.

Impact: a future green result could pass the script while violating the documented north-star constraints.

### 5. WARNING - Serial result schemas are split between exact BoT lines, bare token extraction, and benchmark payloads

TempleOS requires ordered exact serial lines (`BoT: boot ok`, `BoT: keypress=q`, `BoT: halt clean`) in `TempleOS/MODERNIZATION/NORTH_STAR.md:18-22` and validates them in `TempleOS/automation/north-star-e2e.sh:17-33`. Inference north-star extracts the first number from runner stdout at `holyc-inference/automation/north-star-e2e.sh:35-43`. Inference benchmark tooling accepts `BENCH_RESULT` JSON or key/value serial payloads in `holyc-inference/bench/qemu_prompt_bench.py:167-186` and token fields at lines 207-234.

Impact: there is no single serial contract tying a model token result to Book-of-Truth token logging. This weakens the cross-repo invariant that every inference output must be auditable through the TempleOS ledger path.

## Compliance Notes

- Law 2 air-gap: no breach found in inspected QEMU builders. TempleOS uses `-nic none`; inference benchmark builder injects `-nic none` and tests rejection of network arguments.
- Law 10 immutable image: no direct violation proven, but inference benchmark tooling needs explicit image-role classification before it can be considered compliant for OS-image runs.
- Law 5 north-star discipline: the drift above creates a measurable integration blocker because each repo's north-star evidence can fail or pass for different reasons.

## Recommended Remediation

- Define one shared north-star handoff contract: `{TempleOS ISO, readonly OS image role, writable shared/model image role, serial schema, timeout, memory measurement}`.
- Make `holyc-inference/automation/north-star-e2e.sh` call the agreed QEMU runner directly or call a checked TempleOS runner with inference-specific payload arguments.
- Require the serial token result to include a Book-of-Truth event prefix or digest so Sanhedrin can audit inference output and ledger evidence together.
