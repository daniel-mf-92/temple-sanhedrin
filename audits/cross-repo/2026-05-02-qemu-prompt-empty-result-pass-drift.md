# Cross-Repo Audit: QEMU Prompt Empty-Result Pass Drift

Timestamp: 2026-05-02T04:28:21+02:00

Scope: read-only cross-repo invariant check across `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` and `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`.

Audited heads:
- TempleOS: `9f3abbf263982bf9344f8973a52f845f1f48d109`
- holyc-inference: `2799283c9554bea44c132137c590f02034c8f726`
- Sanhedrin audit branch before this report: `fa868e9a68d21f80f6348bdad59f470d30c5fc65`

No TempleOS or holyc-inference source files were modified. No QEMU or VM command was executed. No live liveness watching, process restart, WS8 networking task, socket, NIC, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, package-manager, or remote-runtime action was executed. The only executable proof was a host-side Python fixture that runs `bench/qemu_prompt_bench.py` against a local Python subprocess, not a guest.

## Invariant Under Audit

The inference north star requires a pure HolyC forward pass inside the TempleOS guest and a next-token result over local serial. The cross-repo acceptance invariant is:

1. a successful benchmark report must prove that the serial stream contained an inference result payload;
2. `tokens` / `generated_tokens` absence must not be equivalent to success;
3. host process exit status alone must not stand in for guest inference correctness.

## Findings

### WARNING 1. The QEMU prompt report can be `pass` with no parsed token result

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py:273` through `277` parse stdout/stderr into payload fields, but allow `tokens = extract_tokens(payload)` to remain `None`.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py:279` through `296` records that `None` token state directly in `BenchRun`.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py:301` through `304` sets report status to `pass` using only `returncode == 0` and `not timed_out`; it does not require tokens, throughput, `BENCH_RESULT`, or a named `next_token_id`.

Host-only proof:

```text
returncode 0
timed_out False
tokens None
tok_per_s None
report_status pass
bench_tokens None
```

Impact: a guest or fixture can print a non-result line, exit 0, and produce a green benchmark artifact. That weakens Law 5 / North Star Discipline because the report can claim successful benchmark execution without proving that the TempleOS guest emitted the required next-token result over serial.

Recommended closure: make `write_report` or `run_prompt` fail closed for north-star profiles unless a bounded result line is parsed and required fields are present. Minimum fields should include `tokens` or `generated_tokens` for throughput runs, and a separate `next_token_id` / `reference_token_id` / `match` tuple for correctness runs.

### WARNING 2. The documented benchmark grammar treats token metrics as optional performance telemetry, not an acceptance gate

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/README.md:30` through `32` says the runner extracts `BENCH_RESULT` JSON or key/value metrics and writes normalized records.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/README.md:47` through `57` shows expected token/time examples, but does not state that missing token fields make a run fail.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_qemu_prompt_bench.py:130` through `155` asserts that `write_report` emits `pass` for an explicitly populated run, but there is no negative test for an empty/irrelevant serial payload.

Impact: the current docs and tests protect air-gap command shape and happy-path normalization, but not the north-star acceptance boundary. Future TempleOS-side work could wire a serial boot path that exits cleanly while emitting only Book-of-Truth boot/status lines, and the inference benchmark would still be able to mark that run green if the host process exits 0.

Recommended closure: add a negative unit test where stdout lacks `BENCH_RESULT` / key-value token fields and assert report `status=fail`. Then document required result fields separately from optional telemetry.

### WARNING 3. Host elapsed time fallback hides missing guest timing evidence

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py:273` computes `host_elapsed_us`.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py:275` uses `extract_elapsed_us(payload) or host_elapsed_us`.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py:289` records that fallback as the run's `elapsed_us` with no flag separating guest-reported timing from host-observed wall time.

Impact: when the guest emits no benchmark payload, the artifact still contains a plausible positive `elapsed_us`. That can make a missing guest result look like a measured guest result, especially when paired with `status=pass`.

Recommended closure: add `elapsed_source=guest|host_fallback` and make north-star / secure-local profiles require `elapsed_source=guest` plus token fields. Host fallback is useful diagnostic data, but it should not satisfy the correctness gate.

### INFO 4. The air-gap command boundary remained intact in this slice

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py:146` through `160` builds commands with `-nic none`, `-serial stdio`, and `-display none`.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py:114` through `143` rejects conflicting QEMU networking arguments.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_qemu_prompt_bench.py:19` through `51` covers the no-network command shape and common forbidden network forms.

Impact: this audit found no Law 2 breach in the inspected benchmark source. The drift is acceptance semantics: a local, air-gapped serial channel is present, but the benchmark can accept an empty semantic result.

## Recommended Cross-Repo Acceptance Contract

- `status=pass` requires a parsed result envelope, not just process exit 0.
- Performance runs require `generated_tokens > 0` and guest-reported elapsed time.
- Correctness runs require `next_token_id`, `reference_token_id`, `match=true`, `prompt_sha256`, and a Book-of-Truth local-serial preamble proving mirror-on / fail-stop state.
- Missing result payloads should be `fail` with `failure_reason=missing_bench_result`.

Finding count: 4

## Read-Only Commands Used

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
git rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py | sed -n '260,380p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/README.md | sed -n '1,180p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_qemu_prompt_bench.py | sed -n '1,220p'
PYTHONPATH=/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference python3 - <<'PY'
from pathlib import Path
from bench import qemu_prompt_bench as bench
import json, sys, tempfile
run = bench.run_prompt([sys.executable, '-c', 'import sys; sys.stdin.read(); print("boot ok")'], bench.PromptCase('no-result','Hello'), 10, {'profile':'audit','model':'fixture','quantization':'none','commit':'auditsha'})
print('returncode', run.returncode)
print('timed_out', run.timed_out)
print('tokens', run.tokens)
print('tok_per_s', run.tok_per_s)
with tempfile.TemporaryDirectory() as d:
    latest = bench.write_report([run], Path(d))
    payload = json.loads(latest.read_text())
    print('report_status', payload['status'])
    print('bench_tokens', payload['benchmarks'][0]['tokens'])
PY
```
