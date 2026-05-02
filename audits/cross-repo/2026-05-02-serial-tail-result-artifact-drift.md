# Cross-Repo Audit: Serial Tail Result Artifact Drift

Timestamp: 2026-05-02T08:36:24+02:00

Scope: cross-repo invariant check across current TempleOS and holyc-inference heads. TempleOS and holyc-inference were read-only. No live liveness watching, process restart, QEMU/VM command, WS8 networking task, socket, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, package install, remote fetch, or trinity source edit was executed.

Repos inspected:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `9f3abbf2d0d2`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit`

Audit angle: cross-repo invariant check. Does the inference benchmark evidence contract preserve TempleOS Law 11 local-only Book-of-Truth access when serial output is captured into durable result artifacts?

Findings: 4

## Summary

TempleOS policy treats Book-of-Truth serial output as a local-only witness: the serial mirror may go to the physically local QEMU host, but it must not be forwarded, streamed, or made available through a remote path. holyc-inference's QEMU prompt benchmark correctly disables guest networking, but it also captures serial/stdout and stderr, stores 4 KiB tails in JSON benchmark artifacts, and writes those artifacts under an unignored `bench/results/` path. This is not evidence of a current network breach; it is a cross-repo artifact-boundary drift that can turn local serial evidence into portable benchmark output unless redaction and retention rules are made explicit.

## Findings

### WARNING-001: Inference benchmark result JSON persists raw serial/stdout tails

Evidence:
- `holyc-inference/bench/qemu_prompt_bench.py:4-6` describes the runner as launching QEMU, capturing serial output, and writing normalized results under `bench/results`.
- `holyc-inference/bench/qemu_prompt_bench.py:52-53` includes `stdout_tail` and `stderr_tail` fields in the durable `BenchRun` record.
- `holyc-inference/bench/qemu_prompt_bench.py:251-262` captures subprocess stdout and stderr.
- `holyc-inference/bench/qemu_prompt_bench.py:274` parses the benchmark payload from `stdout + "\n" + stderr`.
- `holyc-inference/bench/qemu_prompt_bench.py:294-295` stores the tail text into the result object.
- `holyc-inference/bench/qemu_prompt_bench.py:299-309` writes both latest and timestamped JSON reports.

Impact: once the runner is pointed at a TempleOS guest that emits Book-of-Truth lines over serial, the benchmark record can retain raw local serial content. That content may include more than the normalized `BENCH_RESULT` tuple needed for throughput evidence. Under Law 11, local serial capture is allowed only as physically local evidence; durable benchmark JSON needs an explicit redaction/retention boundary before it becomes portable CI or review material.

Recommended issue: change benchmark result artifacts to store only parsed metrics plus hashes/counts of serial evidence by default. Keep raw serial tails only behind a local-only opt-in path that is ignored by git and excluded from CI uploads.

### WARNING-002: holyc-inference does not ignore `bench/results/` JSON artifacts

Evidence:
- `holyc-inference/.gitignore:1` ignores only `automation/logs/`.
- The benchmark default output directory is `bench/results` at `holyc-inference/bench/qemu_prompt_bench.py:320`.
- The report writer creates JSON files directly under that output directory at `holyc-inference/bench/qemu_prompt_bench.py:306-309`.

Impact: unlike TempleOS `*.log` artifacts, benchmark JSON containing `stdout_tail` and `stderr_tail` is not protected by a repository-level ignore rule. Even if no current `bench/results` files are tracked, a future run can generate commit-ready JSON containing serial tails. This makes Law 11 compliance depend on human restraint instead of a local artifact policy.

Recommended issue: ignore raw benchmark result directories or split outputs into `bench/results-public/` for sanitized metrics and `bench/results-local/` for raw local-only captures.

### WARNING-003: TempleOS North Star writes local serial evidence, while inference benchmark treats serial as portable benchmark payload

Evidence:
- `TempleOS/MODERNIZATION/NORTH_STAR.md:17-22` defines success as a headless QEMU boot that emits three exact `BoT:` lines on serial.
- `TempleOS/automation/north-star-e2e.sh:5` writes the serial transcript to `/tmp/north-star.log` by default.
- `TempleOS/automation/north-star-e2e.sh:92-100` launches QEMU with `-nic none`, a pipe-backed serial chardev, `-monitor none`, and `-vga none`.
- `TempleOS/automation/north-star-e2e.sh:128-129` copies the serial pipe output into the local log.
- `TempleOS/.gitignore:18-19` ignores `*.log`.
- `holyc-inference/bench/README.md:30-35` defines the benchmark as capturing serial output and writing normalized records, but only says the runner injects `-nic none` and rejects conflicting networking arguments.

Impact: both repos are individually plausible, but they assign different artifact classes to serial output. TempleOS treats serial as local run evidence and keeps the default transcript in `/tmp`/ignored log form. holyc-inference treats serial/stdout tails as a field in normalized JSON. Cross-repo acceptance can therefore say "air-gap passed" while silently changing "local-only serial witness" into "benchmark result payload."

Recommended issue: add a shared serial-evidence schema with classes such as `raw_local_only`, `redacted_tail`, `metric_only`, and `hash_only`, and require benchmark JSON to declare which class it contains.

### INFO-004: Current CI workflows do not upload benchmark or serial artifacts

Evidence:
- TempleOS `.github/workflows/modernization-smoke.yml` runs syntax checks and an air-gap reminder only; it does not run QEMU or upload artifacts.
- TempleOS `.github/workflows/secret-scan.yml` and holyc-inference `.github/workflows/secret-scan.yml` only run gitleaks.
- No `actions/upload-artifact` usage was found in the inspected current workflow files.

Impact: this audit did not find current CI exfiltration of Book-of-Truth serial content. The risk is pre-CI: unignored JSON artifacts can be committed or later uploaded by a future workflow because the artifact class is not encoded in the output path or schema.

Recommended issue: before adding benchmark-artifact CI upload, require a gate that fails any upload candidate containing `stdout_tail`, `stderr_tail`, raw `BOT seq=`, `BoT:`, or full serial transcript fields.

## Law Mapping

- Law 2: no guest networking was added or executed; the inspected launch surfaces still use explicit no-network policy.
- Law 11: raw Book-of-Truth serial evidence must remain local-only. The drift is that holyc-inference benchmark artifacts can preserve raw serial tails in portable JSON without a local-only marker or ignore boundary.
- Law 5/North Star Discipline: normalized benchmark evidence is useful only if it does not weaken the Book-of-Truth trust boundary it is supposed to measure.

## Validation

Commands run:
- `rg -n "upload-artifact|actions/upload|artifact|serial|BookTruth|Book of Truth|BookOfTruth|cat .*serial|tail .*serial|tee .*serial|scp|rsync|curl|wget|http|https|socket|qmp|monitor|telnet|unix:" ...`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/north-star-e2e.sh`
- `find .../.github/workflows -type f -maxdepth 1 -print -exec sed -n '1,220p' {} \;`
- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference ls-files bench/results`
- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference status --ignored --short bench/results`

No QEMU/VM command was executed.
