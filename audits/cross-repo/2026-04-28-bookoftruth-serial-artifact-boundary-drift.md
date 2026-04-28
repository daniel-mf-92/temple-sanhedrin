# Cross-Repo Invariant Audit: Book-of-Truth Serial Artifact Boundary Drift

Timestamp: 2026-04-28T02:48:38+02:00

Audit owner: gpt-5.5 sibling, retroactive / historical scope only

Repos examined:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `93ad594e8bafbeb20a2dd251822b28af09f6bdea`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `b8a4fc8b7dd7cb2175ff3e4e8f051a7d4b19ca7d`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at `736ff15861e814e83af6c45af5aecdc3ce396ab4`

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source code was modified. No QEMU or VM command was executed.

## Summary

Found 5 findings: 1 critical, 3 warnings, 1 info.

TempleOS now states a strict local-access-only invariant for Book-of-Truth output: the serial mirror may be read only at the physically local QEMU host, with no forwarding, streaming, remote viewing, or export path. holyc-inference meanwhile treats TempleOS serial output as benchmark material and stores stdout/stderr tails in JSON artifacts. This is not a guest networking breach, because the reviewed launch paths still inject `-nic none`. The drift is the artifact boundary: once inference Book-of-Truth token/GPU/policy rows are emitted on the same serial channel as benchmark metrics, host reports can accidentally become Book-of-Truth excerpts.

## Finding CRITICAL-001: holyc-inference benchmark artifacts can persist Book-of-Truth-bearing serial tails

Applicable laws:
- Law 11: Book of Truth Local Access Only
- Law 2: Air-Gap Sanctity, as a non-finding for the reviewed benchmark command

Evidence:
- `holyc-inference/bench/qemu_prompt_bench.py:4-6` documents that the benchmark launches QEMU, captures serial output, and writes normalized results.
- `holyc-inference/bench/qemu_prompt_bench.py:51-53` includes `stdout_tail` and `stderr_tail` in each benchmark record.
- `holyc-inference/bench/qemu_prompt_bench.py:251-259` captures QEMU stdout and stderr, and `:279-296` stores 4096-byte tails in every `BenchRun`.
- `holyc-inference/bench/qemu_prompt_bench.py:299-309` writes those records to `bench/results/qemu_prompt_bench_latest.json` and timestamped JSON.
- `holyc-inference/MASTER_TASKS.md:9-10` says every token is logged to the Book of Truth.
- `holyc-inference/MASTER_TASKS.md:23-24` says every inference call, token, and tensor-op checkpoint is loggable by the Book of Truth ledger.

Assessment:
The benchmark has no classifier that separates harmless `BENCH_RESULT` metrics from Book-of-Truth rows. Once token, policy, attestation, or GPU audit hooks write to serial, the benchmark result JSON can persist the same content that Law 11 says must remain local-only.

Required remediation:
- Store parsed metric fields only by default, not raw serial tails.
- Add a redaction gate that drops lines matching Book-of-Truth prefixes before writing benchmark JSON.
- If raw serial tails are ever needed, require an explicit local-only debug flag and exclude those artifacts from commits/uploads.

## Finding WARNING-001: TempleOS local-only doctrine conflicts with its own remote serial testing prompt

Applicable laws:
- Law 11: Book of Truth Local Access Only

Evidence:
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:222-230` says Book-of-Truth output is local-only, with no remote viewing, no forwarding, and host-side serial capture readable only while sitting at the host.
- `TempleOS/MODERNIZATION/LOOP_PROMPT.md:81-89` directs builders to SSH into Azure VM `52.157.85.234` and shows QEMU with `-serial file:/tmp/serial.log`.
- `TempleOS/MODERNIZATION/LOOP_PROMPT.md:95-98` tells builders to check serial output for compilation errors or Book-of-Truth log entries.

Assessment:
This is historical doctrine drift inside TempleOS planning artifacts. The QEMU example includes `-nic none`, so it preserves guest air-gap. It still teaches remote reading of a serial file that may contain Book-of-Truth rows.

Required remediation:
- Mark the Azure workflow as compile-only and explicitly forbid Book-of-Truth-bearing serial review over SSH.
- Replace raw `/tmp/serial.log` inspection with local-only use or redacted pass/fail summaries for remote compile checks.

## Finding WARNING-002: holyc-inference prompt still normalizes remote serial capture as compile evidence

Applicable laws:
- Law 11: Book of Truth Local Access Only

Evidence:
- `holyc-inference/LOOP_PROMPT.md:81-92` points builders to the same Azure host, says SSH testing is allowed, and says serial output captures compilation results.
- `holyc-inference/NORTH_STAR.md:7-18` defines success as running a HolyC forward pass inside TempleOS and outputting a token id over serial.
- `holyc-inference/bench/README.md:30-32` says the benchmark captures serial output and writes normalized records to `bench/results/`.

Assessment:
The inference prompt does not explicitly say Book-of-Truth rows are readable over SSH, but its north-star and benchmark paths make serial output the main evidence channel. That becomes unsafe when combined with the mission-level requirement that every token be logged to the Book of Truth.

Required remediation:
- Add a benchmark evidence class: `metrics_only`, `redacted_serial`, or `local_raw_serial`.
- Require remote compile runs to emit only compile status and metrics, not Book-of-Truth rows or token-event ledger content.

## Finding WARNING-003: Inference Book-of-Truth event payloads are richer than TempleOS local-access artifact policy accounts for

Applicable laws:
- Law 11: Book of Truth Local Access Only
- Law 3: Book of Truth Immutability

Evidence:
- `holyc-inference/src/gpu/book_of_truth_bridge.HC:9-13` defines GPU event classes for DMA lifecycle, MMIO writes, and dispatch submissions.
- `holyc-inference/src/gpu/book_of_truth_bridge.HC:36-45` stores sequence id, event type/op, and four arguments per event.
- `holyc-inference/src/runtime/policy_digest.HC:135-147` emits a human-auditable policy bitfield.
- `holyc-inference/src/runtime/attestation_manifest.HC:17-30` stores session id, profile, policy digest, nonce, trust counts, GPU/IOMMU/Book-of-Truth hook flags, and formatted lines.

Assessment:
These are valid HolyC-side security artifacts, but they raise the sensitivity of serial tails beyond simple benchmark timing. A raw tail can contain trusted-run state, device mapping metadata, policy bits, and session identifiers. TempleOS's local-only policy covers the Book of Truth in principle, but cross-repo benchmark/report tooling does not yet encode this sensitivity boundary.

Required remediation:
- Define a shared "Book-of-Truth-bearing serial" marker contract for inference and TempleOS.
- Require host tools to treat any line with that marker as local-only and non-persistable unless stored in a physically local, explicitly classified ledger artifact.

## Finding INFO-001: Reviewed command builders still preserve guest air-gap

Applicable laws:
- Law 2: Air-Gap Sanctity

Evidence:
- `holyc-inference/bench/qemu_prompt_bench.py:146-160` always starts the generated QEMU command with `-nic none`, `-serial stdio`, and `-display none`.
- `holyc-inference/bench/qemu_prompt_bench.py:114-143` rejects conflicting network arguments.
- `TempleOS/automation/qemu-headless.sh:76-82` appends `-nic none` or legacy fallback `-net none`.
- `TempleOS/MODERNIZATION/LOOP_PROMPT.md:88-89` includes `-nic none` in the remote QEMU example.

Assessment:
This audit found serial artifact boundary drift, not guest networking enablement. No VM was launched, no WS8 networking task was executed, and no networking stack/NIC/socket/TCP/IP/UDP/TLS/DHCP/DNS/HTTP implementation was added or enabled by this audit.

## Historical Notes

- The TempleOS local-access-only rule appears in history by `6c24b8155fdf32a64338198b5c183c111f0f0b07` on 2026-04-12.
- holyc-inference benchmark raw tail persistence appears in history by `842e667a8fa4a152c96fd97d691dc49181609ca5` on 2026-04-27, with later `stdout_tail` touches through `fc7f117bde2df8e69b668748b7ae9859c846ccad`.
- The holyc-inference GPU Book-of-Truth bridge appears in history by `9e836f893b7f486cea81f4f609ca54ba4dee2d0b` on 2026-04-27.

## Read-Only Verification Commands

```bash
git rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py | sed -n '1,360p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/README.md | sed -n '1,120p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/book_of_truth_bridge.HC | sed -n '1,260p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/attestation_manifest.HC | sed -n '1,220p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/policy_digest.HC | sed -n '1,180p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '155,236p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/qemu-headless.sh | sed -n '1,150p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/LOOP_PROMPT.md | sed -n '80,100p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/LOOP_PROMPT.md | sed -n '75,100p'
```
