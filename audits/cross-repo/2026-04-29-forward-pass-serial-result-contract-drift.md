# Cross-Repo Audit: Forward-Pass Serial Result Contract Drift

Timestamp: 2026-04-29T19:48:27+02:00

Scope: retroactive cross-repo invariant check across current heads of TempleOS and holyc-inference.

- TempleOS head audited: `d9c3b620dbe9cf8bde884ed11c8ec1df99a68e89`
- holyc-inference head audited: `485af0ea41a239c8393542d6e0e2fc5944f30f53`
- Audit mode: read-only source inspection; no QEMU/VM commands executed.

## Invariant Under Test

The trinity has two adjacent North Stars that must eventually compose:

- `holyc-inference/NORTH_STAR.md` requires a pure HolyC GPT-2 forward pass inside the TempleOS guest, with the next-token id emitted over serial and matched bit-exactly to `tests/reference_q4_gpt2.py` (`NORTH_STAR.md:7`, `NORTH_STAR.md:16-18`).
- `TempleOS/MODERNIZATION/NORTH_STAR.md` requires a headless TempleOS boot with a `shared.img` HolyC demo and exactly three serial lines: `BoT: boot ok`, `BoT: keypress=q`, `BoT: halt clean` (`MODERNIZATION/NORTH_STAR.md:17-22`).

The cross-repo invariant is: TempleOS serial boot/BoT plumbing should define a stable result envelope that holyc-inference can use for the forward-pass token, reference token, timing, and pass/fail status without confusing telemetry token counts for token ids.

## Findings

### WARNING 1: No shared serial result envelope bridges BoT hello and inference token output

Evidence:

- Inference declares the required payload as "next-token id over serial" and reference equality (`holyc-inference/NORTH_STAR.md:17-18`).
- TempleOS validates only the three fixed BoT hello lines and ordering (`TempleOS/automation/north-star-e2e.sh:17-33`, `:101-114`).
- TempleOS source search did not show `NEXT_TOKEN`, `next_token`, `token_id`, `BENCH_RESULT`, `actual_token`, or `ref_token` in core/automation paths; hits were unrelated compiler vocabulary and historical logs.

Risk:

The two loops can both improve serial machinery while still having no authoritative line grammar for the actual inference result. That makes the eventual handoff vulnerable to ad hoc parsing and false positives.

Suggested contract:

Reserve one exact serial prefix, for example:

```text
HOLYC_FORWARD_RESULT token=<i64> ref=<i64> status=pass elapsed_us=<i64> rss_bytes=<i64>
```

TempleOS should treat that as ordinary local serial output, while inference owns the token/reference fields.

### WARNING 2: Inference E2E token parsing is under-specified and can scrape the wrong integer

Evidence:

- `holyc-inference/automation/north-star-e2e.sh:21-24` extracts the reference token with `tail -1 | grep -oE '[0-9]+' | head -1`.
- `holyc-inference/automation/north-star-e2e.sh:35-43` extracts the HolyC token the same way from the runner's final line.

Risk:

Any final serial line containing timing, memory, sequence number, BoT hash, or status count before the token id can be mistaken for the token. This directly undermines Laws 5 and North Star discipline because the E2E gate can become green on a non-result integer.

Suggested contract:

Require a named field (`token=` or `next_token_id=`) and fail if multiple result lines or multiple token fields are present.

### WARNING 3: Benchmark serial grammar treats `tokens` as throughput count, not next-token id

Evidence:

- `holyc-inference/bench/README.md:30-56` documents `BENCH_RESULT` JSON or key/value metrics with `tokens=64`, `elapsed_us`, and `tok_per_s`.
- `holyc-inference/bench/qemu_prompt_bench.py:167-186` extracts JSON or key/value fields from serial output.
- `holyc-inference/bench/qemu_prompt_bench.py:207-212` reads `tokens`, `generated_tokens`, `decode_tokens`, or `total_tokens` as a count, and `:226-234` uses it for throughput.

Risk:

The only structured serial parser currently present in inference is performance-oriented. If builders reuse it for the North Star, `tokens=64` can mean "64 generated tokens" rather than "next token id is 64". That is a correctness contract collision.

Suggested contract:

Keep benchmark counts under `tokens`/`generated_tokens`, but use a distinct mandatory field for correctness: `next_token_id`.

### WARNING 4: Shared image mounting semantics differ between the two harness families

Evidence:

- Inference North Star requires the Q4_0 GPT-2 blob to live on `shared.img` (`holyc-inference/NORTH_STAR.md:16`).
- TempleOS North Star uses an ISO plus optional `SHARED_IMG`, mounted as one IDE drive if present (`TempleOS/automation/north-star-e2e.sh:5-13`, `:101-114`).
- Inference benchmark command builder accepts one `--image` and emits a single raw IDE drive (`holyc-inference/bench/qemu_prompt_bench.py:146-160`); additional QEMU args are append-only and not typed as model/shared-media inputs (`:316-324`).

Risk:

The inference loop can benchmark an image and the TempleOS loop can boot a BoT demo, but neither current interface names the exact handoff for "TempleOS ISO plus shared model disk plus HolyC forward program". This leaves the final runner (`automation/run-holyc-forward.sh`) to invent private mount conventions later.

Suggested contract:

Define a shared QEMU invocation schema with explicit `--templeos-iso`, `--shared-img`, `--model-img` or equivalent fields, and require air-gap flags on every path.

### INFO 5: Air-gap invariant is present in both inspected harness surfaces

Evidence:

- TempleOS North Star hard-codes `-nic none` (`TempleOS/automation/north-star-e2e.sh:101-105`).
- TempleOS `automation/qemu-headless.sh` forces `-nic none` when supported and `-net none` only as legacy fallback (`:76-82`).
- Inference `bench/qemu_prompt_bench.py` injects `-nic none` into the command (`:146-158`) and rejects conflicting network arguments before appending user QEMU args (`:147`, `:159`).

Risk:

No Law 2 breach was found in this audit slice. The remaining issue is not networking; it is the absence of a correctness payload contract over the already-air-gapped serial channel.

## Summary

Findings: 5 total.

- Warnings: 4
- Info: 1
- Critical: 0

The highest-leverage fix is to add a single documented serial result grammar for inference correctness, then update `holyc-inference/automation/north-star-e2e.sh` and the eventual `automation/run-holyc-forward.sh` to parse only that grammar.
