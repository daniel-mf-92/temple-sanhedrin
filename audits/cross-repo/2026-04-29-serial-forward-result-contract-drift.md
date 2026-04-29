# Cross-Repo Serial Forward-Result Contract Drift Audit

Timestamp: 2026-04-29T02:49:19+02:00

Scope: TempleOS `9ecc6aa99630` and holyc-inference `ce09228422da`, read-only. This audit checks whether the serial-output contract that TempleOS exposes for local, air-gapped QEMU runs is precise enough for the holyc-inference forward-pass and benchmark harnesses to consume without ambiguity.

Laws reviewed: Law 2 air-gap sanctity, Law 5 north-star discipline, Law 11 local-only Book of Truth access.

## Summary

The two repos agree on local serial as the handoff surface, and the checked QEMU benchmark runner correctly injects `-nic none`. The drift is that holyc-inference has three incompatible result grammars for the same serial channel: bare integer extraction in its North Star script, `BENCH_RESULT` JSON/key-value metrics in the benchmark runner, and TempleOS Book-of-Truth `BoT:` lines in the OS North Star. That makes a future "token id over serial" success ambiguous unless a single line grammar is defined and enforced.

Findings: 4 warnings, 0 critical.

## Evidence

- TempleOS North Star requires exactly ordered serial lines: `BoT: boot ok`, `BoT: keypress=q`, and `BoT: halt clean` in `TempleOS/automation/north-star-e2e.sh:16-20` and validates ordering at `:165-173`.
- TempleOS North Star launches QEMU with `-nic none`, `-serial file:$LOG`, and optional `shared.img` at `TempleOS/automation/north-star-e2e.sh:105-118`.
- holyc-inference North Star expects weights at `models/gpt2-124m-q4_0.bin`, reference oracle at `tests/reference_q4_gpt2.py`, and a future executable `automation/run-holyc-forward.sh` at `holyc-inference/automation/north-star-e2e.sh:5-35`.
- holyc-inference North Star extracts the first integer from the last output line of both reference and HolyC runs with `tail -1 | grep -oE '[0-9]+' | head -1` at `holyc-inference/automation/north-star-e2e.sh:21-35`.
- holyc-inference benchmark tooling expects `BENCH_RESULT` JSON or key/value metric lines, per `holyc-inference/bench/README.md:30-57` and parser regexes in `holyc-inference/bench/qemu_prompt_bench.py:26-27`.
- `qemu_prompt_bench.py` rejects QEMU networking arguments and injects `-nic none` at `holyc-inference/bench/qemu_prompt_bench.py:114-160`.
- Current tree check found no `holyc-inference/tests/reference_q4_gpt2.py`, no `holyc-inference/automation/run-holyc-forward.sh`, no `holyc-inference/models/gpt2-124m-q4_0.bin`, and no holyc-inference `automation/shared.img`.

## Findings

### WARNING 1 - Forward-pass token parsing is ambiguous on a shared serial channel

holyc-inference accepts the first decimal substring on the final line as the token id. That can misclassify any final diagnostic containing a number, including Book-of-Truth sequence ids, elapsed time, error counts, or benchmark metrics. TempleOS already treats serial output as structured evidence with exact expected lines, so the inference runner should not use an unlabelled integer as its success criterion.

Impact: A false GREEN is possible if a non-token diagnostic is the final serial line and happens to match the reference token. This is a Law 5 warning because the North Star can report progress without proving the forward-pass contract.

Recommended invariant: Require a single labelled line, for example `INFER_RESULT token_id=<id> prompt_sha256=<hash> model_sha256=<hash>`, and reject unlabelled integers.

### WARNING 2 - Benchmark and North Star result grammars disagree

The benchmark path expects `BENCH_RESULT` JSON or key/value metrics, while the North Star path expects a bare token id. These two contracts cannot both be the canonical forward-pass serial ABI unless one wraps or derives from the other.

Impact: A runner can satisfy the benchmark parser without satisfying the North Star parser, or satisfy the North Star with output the benchmark cannot normalize. This blocks reliable cross-repo trend comparison and makes regressions look like parser drift.

Recommended invariant: Make `BENCH_RESULT` include `token_id` and let the North Star parser validate that labelled field, or define a distinct `INFER_RESULT` line and have benchmark tooling parse it alongside timing fields.

### WARNING 3 - Air-gap guarantees are proven in benchmark tooling but not in the North Star runner placeholder

The benchmark runner enforces `-nic none`, but `automation/north-star-e2e.sh` delegates the actual HolyC QEMU launch to a not-yet-present `automation/run-holyc-forward.sh`. Until that runner exists with the same explicit networking rejection and QEMU argument evidence, the inference North Star cannot prove Law 2 compliance on the path that matters most.

Impact: No current networking breach was found, because the runner is absent. The risk is contract drift: a future runner could pass token checks while bypassing the benchmark runner's air-gap guard.

Recommended invariant: The future forward runner must either call the existing guarded QEMU builder or independently enforce `-nic none`/`-net none` and reject `-netdev` and network `-device` values.

### WARNING 4 - Shared-image and artifact placement are not aligned

TempleOS optionally attaches `TempleOS/automation/shared.img`, while holyc-inference's North Star looks for `models/gpt2-124m-q4_0.bin` in its repo and does not define how that file is staged onto the TempleOS-accessible disk image. The North Star text says the weight blob lives on `shared.img`, but the executable check currently fails before any image staging can be verified.

Impact: The repos can each make local progress while disagreeing about where the guest-visible model artifact lives. This is a Law 5 warning because a future "runner exists" change may still fail the actual cross-repo boot/load path.

Recommended invariant: Define one model staging contract: source path, image path, checksum, readonly/mutable status, and the exact QEMU `-drive` option used for the guest-visible artifact.

## Non-Findings

- No source-code networking implementation was introduced by this audit.
- No QEMU command was executed.
- The benchmark runner's current QEMU construction is consistent with Law 2 because it injects `-nic none` and rejects conflicting network arguments.
- All inspected inference runtime files remain HolyC in `src/`; host-side Python remains in allowed tooling paths.

## Follow-Up

Open one issue or queue item to define the canonical serial forward-result ABI before implementing `automation/run-holyc-forward.sh`. The minimum acceptance test should feed a serial fixture containing Book-of-Truth lines, benchmark metrics, and exactly one labelled inference result, then assert that only the labelled inference result can satisfy the North Star.
