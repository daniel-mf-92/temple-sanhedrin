# Cross-Repo Benchmark Image Handoff Drift Audit

Timestamp: 2026-05-02T05:48:33+02:00

Scope: read-only cross-repo invariant check across `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` and `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`.

TempleOS head inspected: `9f3abbf263982bf9344f8973a52f845f1f48d109` on `codex/modernization-loop`.

holyc-inference head inspected: `2799283c9554bea44c132137c590f02034c8f726` on `main`.

No TempleOS or holyc-inference source files were modified. No QEMU, VM, networking, package download, WS8 networking task, live liveness watcher, or current-iteration compliance loop was executed.

## Invariant Under Audit

The inference benchmark handoff must boot an air-gapped TempleOS guest while preserving TempleOS's immutable-image contract and the inference loop's fixed-prompt/token-result contract. A compliant cross-repo benchmark should make these roles explicit:

- OS image: read-only, sealed TempleOS artifact.
- Data/model image: separate writable partition for prompts, models, logs, and Book-of-Truth host capture.
- Prompt authority: fixed or explicitly injected through a documented TempleOS-side protocol.
- Result authority: benchmark pass criteria tied to token id/reference parity plus Book-of-Truth/serial evidence, not only process exit.

## Findings

### WARNING 1. holyc-inference QEMU benchmark boots the OS image writable

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py:146` through `160` builds the QEMU command.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py:156` through `157` adds `-drive file=<image>,format=raw,if=ide`.
- The command does not include `readonly=on` for the TempleOS image.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:206` through `219` says the installed OS image is immutable and QEMU must use `-drive readonly=on` for the OS image.

Impact: this is direct drift against Law 10's QEMU image requirement. It is not an observed source mutation, but the benchmark harness normalizes a writable OS disk path for the exact cross-repo forward-pass workflow.

### WARNING 2. TempleOS canonical QEMU runners share the same missing readonly guard

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/qemu-headless.sh:84` through `90` attach `DISK_IMAGE` with `-drive file=$DISK_IMAGE,format=raw,if=ide` and `ISO_IMAGE` with `-cdrom`.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/qemu-smoke.sh:75` through `80` uses the same writable `DISK_IMAGE` drive form.
- Both scripts enforce `-nic none` or `-net none`, but neither distinguishes a read-only OS image from writable user/model media.

Impact: holyc-inference is copying an unsafe launch shape that TempleOS itself still exposes. Cross-repo release evidence can therefore prove air-gap while silently failing the immutable-image half of the same policy.

### WARNING 3. The benchmark has no first-class user/model disk role

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/NORTH_STAR.md:16` requires a Q4_0 GPT-2 weight blob on `shared.img`.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:213` through `219` require user data, Book-of-Truth logs, and LLM models on a separate writable partition while the OS image remains read-only.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py:315` exposes only `--image` as the TempleOS disk image.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py:318` allows raw repeated `--qemu-arg`, but the guard only rejects networking flags; it does not enforce a separate writable model/data drive or readonly status on the OS drive.

Impact: the inference benchmark can be made to run only by overloading `--image` or free-form QEMU args. That leaves Sanhedrin without a reliable way to tell whether a run used a sealed OS image plus separate model media, or a single writable disk that violates the installed-image contract.

### WARNING 4. Prompt handoff semantics are not a TempleOS-side contract

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/NORTH_STAR.md:17` defines the first E2E prompt as fixed token ids `[15496, 11, 995]`.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py:246` through `258` attempts to pass each prompt through host environment variables and subprocess stdin.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/NORTH_STAR.md:17` through `21` currently defines a serial/keyboarding demo, not an inference prompt-ingest protocol.
- A targeted TempleOS source scan found model deterministic prompt-hash status helpers, but no `HOLYC_BENCH_PROMPT`, `BENCH_RESULT`, or benchmark prompt input ABI.

Impact: host-side prompt iteration can diverge from the TempleOS guest's actual prompt. A benchmark report may hash and label a host prompt while the guest runs a built-in fixed prompt, no prompt, or a stale prompt from disk.

### WARNING 5. Result acceptance is too generic for bit-exact inference evidence

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py:167` through `186` accepts any JSON object after `BENCH_RESULT` or any key/value text parsed from serial output.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py:207` through `235` extracts token counts, elapsed time, and throughput, but no next-token id, reference token id, prompt token tuple, Book-of-Truth sequence, or entry hash.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py:301` through `304` marks the report `pass` when all QEMU invocations return 0 and do not time out.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/NORTH_STAR.md:17` through `18` requires the output to match the reference bit-exactly.

Impact: the current benchmark format is useful throughput telemetry, but it is not sufficient north-star evidence. It can report pass for a run that emitted timing metrics but never proved the expected next-token id or Book-of-Truth-backed token event.

## Healthy Observations

- The holyc-inference benchmark forcibly injects `-nic none` and rejects common QEMU networking arguments.
- The TempleOS QEMU runners also enforce `-nic none` or legacy `-net none`.
- The reviewed runtime/source paths remain HolyC for core implementation; Python is confined to host-side benchmark/test tooling.
- No remote log viewing, socket, HTTP, DHCP, DNS, TLS, or WS8 networking execution was observed in this audit slice.

## Recommended Remediation

- Split benchmark launch arguments into `--os-image` and `--data-image`; require `readonly=on` on `--os-image` and writable mode only on the explicit data/model image.
- Update TempleOS `qemu-headless.sh` and `qemu-smoke.sh` so OS-image launches include `readonly=on`, with a separate writable drive for shared/model data.
- Define one TempleOS-side prompt/result ABI for the benchmark: fixed prompt id or input file path, expected token id, actual token id, prompt hash, model hash, Book-of-Truth sequence/hash, and serial mirror/fail-stop status.
- Change holyc-inference benchmark pass criteria to require the bit-exact next-token evidence, not only QEMU return code and timing fields.

Finding count: 5 warnings, 0 critical findings.
