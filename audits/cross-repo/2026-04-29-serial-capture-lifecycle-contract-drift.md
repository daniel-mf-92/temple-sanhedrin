# Cross-Repo Serial Capture Lifecycle Contract Drift Audit

Timestamp: 2026-04-29T02:18:15+02:00

Audit owner: gpt-5.5 sibling, retroactive / historical scope only

Repos examined:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `e59af356b0d221c77a0b9a041d63d8ca56d9b50c`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `ce09228422dae06e86feb84925d51df88d67821b`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at `f69762663b7d2b2c198acd583a49c2b3b133e62c`

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source code was modified. No QEMU or VM command was executed.

## Summary

Found 5 findings: 3 warnings and 2 info.

This pass looked specifically at the lifecycle of host-side serial captures once the serial stream can contain Book-of-Truth material. The repos currently disagree on serial-capture treatment: TempleOS compile tooling can delete temporary serial logs after extracting compile errors, while holyc-inference benchmark tooling persists raw stdout/stderr tails in JSON reports. Both behaviors are reasonable for ordinary compile or benchmark output, but they are not safe as an implicit shared contract for Book-of-Truth-bearing serial lines.

The issue is not guest networking. Reviewed QEMU command builders still include explicit no-network flags. The drift is classification: neither repo marks serial output as `metrics_only`, `compile_only`, `book_of_truth_local_raw`, or `redacted`, so host tools cannot consistently decide whether a capture must be retained locally, redacted before persistence, or discarded only after proving it contains no Book-of-Truth rows.

## Finding WARNING-001: TempleOS compile helper deletes serial capture without classifying Book-of-Truth content

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 11: Book of Truth Local Access Only

Evidence:
- `TempleOS/automation/qemu-compile-test.sh:66` creates the serial log with `mktemp`.
- `TempleOS/automation/qemu-compile-test.sh:76-86` checks the serial log for compile-error strings, prints a short error excerpt if found, then removes the serial log on both error and success paths.
- `TempleOS/MODERNIZATION/LOOP_PROMPT.md:95` tells builders to check serial output for compilation errors or Book-of-Truth log entries.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:222-230` says Book-of-Truth output is local-only and host-side serial capture may be read only while physically present at the host.

Assessment:
The helper treats serial as transient compile output, while the modernization prompt also treats serial as a possible Book-of-Truth observation channel. If a run emits Book-of-Truth rows, deleting the unclassified host capture destroys local audit evidence; if the helper prints excerpts, it may also leak selected serial lines outside the local-only handling model.

Required remediation:
- Classify serial mode before cleanup: `compile_only` may be deleted, `book_of_truth_local_raw` must not be auto-deleted, and `redacted` may emit only non-ledger summaries.
- Make compile-error extraction ignore or redact Book-of-Truth-prefixed lines before echoing snippets.
- Add a guard that refuses to delete a serial log containing Book-of-Truth prefixes unless an explicit local-retention policy has already copied it into a classified local ledger path.

## Finding WARNING-002: holyc-inference benchmark reports persist raw serial tails without a Book-of-Truth redaction gate

Applicable laws:
- Law 11: Book of Truth Local Access Only
- Law 5: North Star Discipline, because benchmark artifacts can be mistaken for safe north-star evidence

Evidence:
- `holyc-inference/bench/qemu_prompt_bench.py:4-6` documents serial capture and normalized result writing.
- `holyc-inference/bench/qemu_prompt_bench.py:37-53` includes `stdout_tail` and `stderr_tail` in every `BenchRun`.
- `holyc-inference/bench/qemu_prompt_bench.py:251-259` captures QEMU stdout/stderr, and `:279-296` stores 4096-byte tails.
- `holyc-inference/bench/qemu_prompt_bench.py:299-309` writes those runs to latest and timestamped JSON files.
- `holyc-inference/MASTER_TASKS.md:9-10` says the target experience logs every token to the Book of Truth; `:23-24` broadens that to inference calls, tokens, and tensor checkpoints.

Assessment:
The benchmark parser extracts metrics, but the report writer still persists raw tails. Once per-token, policy, attestation, or GPU audit events are emitted over the same serial channel, the benchmark JSON can become a durable copy of Book-of-Truth-bearing content. That conflicts with the local-only rule unless the artifact is explicitly classified as local raw serial and kept out of remote reports/commits.

Required remediation:
- Store parsed benchmark metrics by default, not raw serial tails.
- Add redaction for Book-of-Truth prefixes before JSON persistence.
- If raw tails are needed for local diagnosis, require an explicit local-only flag and classify the output path as non-uploadable evidence.

## Finding WARNING-003: Cross-repo serial semantics have no shared lifecycle vocabulary

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity
- Law 11: Book of Truth Local Access Only

Evidence:
- `TempleOS/MODERNIZATION/NORTH_STAR.md:17-21` makes serial output part of the north-star success criteria.
- `TempleOS/MODERNIZATION/NORTH_STAR.md:26` says the pipeline exercises a Book-of-Truth log line over serial.
- `holyc-inference/bench/README.md:30-32` says QEMU prompt benchmarking captures serial output, extracts metrics, and writes normalized records.
- `holyc-inference/src/model/inference.HC:3371-3378` defines per-token Book-of-Truth event emission around immutable token-event tuples.
- `holyc-inference/src/model/inference.HC:3519-3525` adds a commit-only wrapper for the same token-event path, making this material structured enough that raw serial tails can carry meaningful ledger payload.

Assessment:
Both repos rely on serial as evidence, but they use different implicit lifecycle rules. TempleOS doctrine says Book-of-Truth serial is local raw evidence; TempleOS compile tooling treats serial as disposable; holyc-inference benchmarking treats serial tails as persistable JSON metadata. A shared classification vocabulary would let host tools make deterministic choices before deleting, redacting, or committing captures.

Required remediation:
- Define a shared serial evidence class field: `compile_only`, `metrics_only`, `redacted_serial`, `book_of_truth_local_raw`.
- Require every host serial capture tool to declare one of those classes in help text and machine-readable artifacts.
- Treat unclassified serial that contains Book-of-Truth prefixes as `book_of_truth_local_raw` by default.

## Finding INFO-001: Reviewed QEMU command builders preserve guest air-gap

Applicable laws:
- Law 2: Air-Gap Sanctity

Evidence:
- `TempleOS/automation/qemu-compile-test.sh:67-74` launches QEMU with `-nic none`.
- `TempleOS/automation/qemu-headless.sh:76-82` injects `-nic none` or legacy `-net none`.
- `holyc-inference/bench/qemu_prompt_bench.py:146-160` builds commands with `-nic none`, `-serial stdio`, and `-display none`.
- `holyc-inference/bench/qemu_prompt_bench.py:114-143` rejects conflicting QEMU network args and common virtual NIC devices.

Assessment:
This audit found serial-capture lifecycle drift, not a guest networking breach. No WS8 networking task was executed, no network stack/NIC/socket/TCP/IP/UDP/TLS/DHCP/DNS/HTTP feature was added or enabled, and no VM was launched.

## Finding INFO-002: Law 10 mutable-image drift remains a separate pre-existing issue

Applicable laws:
- Law 10: Immutable OS Image

Evidence:
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:206-219` requires `readonly=on` for the OS image in QEMU and a separate writable disk for user data.
- `TempleOS/automation/qemu-headless.sh:84-86` attaches `DISK_IMAGE` as `file=$DISK_IMAGE,format=raw,if=ide` with no `readonly=on`.
- `holyc-inference/bench/qemu_prompt_bench.py:156-158` builds the benchmark drive as `file={image},format=raw,if=ide`.
- This same Law 10 drift class was already recorded in `audits/cross-repo/2026-04-28-immutable-os-image-qemu-contract-drift.md` and `audits/backfill/2026-04-28-law10-postrule-qemu-readonly-backfill.md`.

Assessment:
Mutable-image drift compounds serial evidence lifecycle risk because repeated benchmark or smoke runs may alter the OS image that produced the serial evidence. This report does not recount that as a new violation; it records the dependency so remediation can coordinate serial classification with OS/data drive role separation.

## Non-Findings

- No TempleOS or holyc-inference source file was edited.
- No QEMU or VM command was executed.
- No live liveness watching, current-iteration compliance check, process restart, or real-time Sanhedrin audit was performed.
- The reviewed QEMU command builders still include explicit `-nic none` or `-net none`.

## Read-Only Verification Commands

```bash
git rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/qemu-compile-test.sh | sed -n '1,110p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/qemu-headless.sh | sed -n '1,130p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '200,235p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/NORTH_STAR.md | sed -n '1,35p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/LOOP_PROMPT.md | sed -n '80,100p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py | sed -n '1,360p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/README.md | sed -n '1,70p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md | sed -n '1,35p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/inference.HC | sed -n '3360,3835p'
```
