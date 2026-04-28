# Cross-Repo Invariant Audit: GPU Book-of-Truth Event Vocabulary Drift

Timestamp: 2026-04-28T01:23:43Z

Auditor: gpt-5.5 sibling, retroactive/deep audit scope

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source code was modified, and no VM/QEMU command was executed.

Repos examined:
- TempleOS committed HEAD: `ffc8a1309fac5c9c6a5592823d609f46707f26f7`
- holyc-inference committed HEAD: `b8a4fc8b7dd7cb2175ff3e4e8f051a7d4b19ca7d`
- temple-sanhedrin committed baseline: `49ed827cf8a0e6c447f43a80d7fc5bd708defb85`
- temple-sanhedrin branch: `codex/sanhedrin-gpt55-audit`

## Executive Summary

Found 4 findings: 4 warnings, 0 critical findings.

The current heads are policy-aligned on the high-level rule that GPU work is allowed only under IOMMU enforcement plus Book-of-Truth telemetry. The drift is at the schema boundary. `holyc-inference` has committed GPU telemetry and attestation primitives for DMA, MMIO, dispatch, IOMMU state, and Book-of-Truth hook state, but TempleOS' committed Book-of-Truth event/source vocabulary still ends at `BOT_EVENT_SERIAL_WATCHDOG` and `BOT_SOURCE_DISK`. Without a shared event/source ID contract, inference can claim "Book-of-Truth GPU hooks active" while TempleOS has no canonical ledger code range, source name, payload decoder, or serial replay shape for those GPU records.

## Finding WARNING-001: holyc-inference GPU event classes have no TempleOS Book-of-Truth event IDs

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity
- Law 5: North Star Discipline

Evidence:
- `holyc-inference/src/gpu/book_of_truth_bridge.HC:22-34` defines GPU event classes and operations: DMA, MMIO, dispatch, map/update/unmap, write, submit/complete/timeout.
- `TempleOS/Kernel/BookOfTruth.HC:3-22` defines canonical `BOT_EVENT_*` values only through `BOT_EVENT_SERIAL_WATCHDOG 20`.
- `TempleOS/Kernel/BookOfTruth.HC:1123-1227` defaults event-range utilities to `BOT_EVENT_INIT` through `BOT_EVENT_SERIAL_WATCHDOG`.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:265-272` still lists Book-of-Truth events for profile/model/gate failures and GPU DMA/MMIO/dispatch logging as open WS14 tasks.

Assessment:
The inference repo has a local GPU telemetry vocabulary, but the TempleOS ledger has not reserved corresponding event IDs. Until the event IDs are canonical in TempleOS, a GPU telemetry row cannot be unambiguously represented in the immutable Book-of-Truth stream.

Risk:
Future integration can silently map inference-side GPU event class `1` to a TempleOS ledger event that already means `INIT`, or compress all GPU events into generic `NOTE`/payload records that Sanhedrin cannot decode as DMA/MMIO/dispatch evidence.

Required remediation:
- Reserve explicit TempleOS `BOT_EVENT_GPU_DMA`, `BOT_EVENT_GPU_MMIO`, and `BOT_EVENT_GPU_DISPATCH` IDs before enabling secure-local GPU dispatch.
- Add the same numeric mapping to holyc-inference as a contract, not as a private bridge-local enum.
- Extend serial replay parsers to recognize the new event IDs before considering GPU Book-of-Truth hooks active.

## Finding WARNING-002: holyc-inference assumes a GPU telemetry source that TempleOS does not expose

Applicable laws:
- Law 8: Book of Truth Immediacy & Hardware Proximity
- Law 5: North Star Discipline

Evidence:
- `TempleOS/Kernel/BookOfTruth.HC:79-86` defines sources only as kernel, CLI, IRQ, MSR, exception, IO, and disk, with `BOT_SOURCE_MASK_ALL` based on `BOT_SOURCE_DISK`.
- `TempleOS/Kernel/BookOfTruth.HC:1490-1510` clamps source filters outside `-1..BOT_SOURCE_DISK`.
- `TempleOS/Kernel/BookOfTruthSerialCore.HC:41-48` and related source-total arrays are sized as `BOT_SOURCE_DISK+1`.
- `holyc-inference/src/gpu/book_of_truth_bridge.HC:9-12` describes GPU telemetry for DMA lifecycle, MMIO writes, and dispatch submissions.

Assessment:
The inference side treats GPU as a first-class telemetry producer, but TempleOS' source model has no `BOT_SOURCE_GPU`, `BOT_SOURCE_DMA`, or equivalent. The source-mask, top-N, decode-ratio, and drift tooling would classify any future GPU ledger entries as unknown unless the source vocabulary and array bounds are widened.

Risk:
GPU audit records can be present but invisible to source-scoped health reports. That weakens Law 8 evidence because Sanhedrin could see "known source share" degrade or miss GPU-origin failures entirely.

Required remediation:
- Add a canonical GPU source slot and update source masks, source-name formatting, and source-scoped arrays.
- Backfill replay fixtures with GPU source rows so source-mask and top-N smoke tests fail if the source is omitted.
- Require holyc-inference GPU bridge tests to assert the TempleOS source ID, not only bridge-local event class IDs.

## Finding WARNING-003: Attestation can publish GPU hook state without a TempleOS-backed proof binding

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- `holyc-inference/src/runtime/attestation_manifest.HC:17-30` includes `gpu_dispatch_allowed`, `iommu_active`, and `bot_gpu_hooks_active` fields.
- `holyc-inference/src/runtime/attestation_manifest.HC:226-239` accepts those three fields as boolean inputs.
- `holyc-inference/src/runtime/attestation_manifest.HC:299-316` emits those fields as manifest lines.
- `TempleOS/MODERNIZATION/LOOP_PROMPT.md:54-57` says TempleOS owns trust-plane decisions and requires performance/security evidence with Book-of-Truth and IOMMU controls on.

Assessment:
The attestation emitter can serialize `bot_gpu_hooks_active=1`, but the reviewed TempleOS Book-of-Truth schema has no GPU event/source code or proof line that binds this boolean to ledger append evidence.

Risk:
A manifest can become stronger than the underlying ledger contract. Sanhedrin might accept a self-reported boolean as proof that GPU telemetry is active, even though no TempleOS-side immutable GPU event vocabulary exists to verify it.

Required remediation:
- Treat `bot_gpu_hooks_active=1` as invalid unless accompanied by a TempleOS Book-of-Truth proof tuple: ledger event ID, source ID, last sequence, and decoded GPU payload class.
- Add Sanhedrin checks that reject GPU attestation lines when TempleOS lacks the corresponding canonical event/source mapping.
- Make the attestation schema reference TempleOS event/source constants by name and value.

## Finding WARNING-004: holyc-inference bridge storage is a ring, but TempleOS policy requires immutable ledger semantics for canonical records

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 9: Resource Supremacy / Crash on Log Failure

Evidence:
- `holyc-inference/src/gpu/book_of_truth_bridge.HC:47-54` models bridge storage as `events`, `capacity`, `count`, `head`, and `next_seq_id`.
- `holyc-inference/src/gpu/book_of_truth_bridge.HC:154-161` explicitly advances the ring head and overwrites the oldest event when full.
- `temple-sanhedrin/LAWS.md` Law 3 forbids clearing, truncating, or overwriting sealed log pages.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:159-205` documents the Book of Truth as non-negotiably immutable and resource-supreme.

Assessment:
The bridge can be acceptable as a transient producer buffer only if it is not the canonical Book-of-Truth store. The file name and comments call it a "Book-of-Truth event bridge", but the overwrite behavior is incompatible with canonical ledger semantics unless every append is synchronously mirrored into TempleOS' immutable ledger before ring overwrite.

Risk:
Future code may treat the bridge ring as the audit record itself. That would allow old GPU DMA/MMIO/dispatch records to disappear under load, violating the project-level immutability contract.

Required remediation:
- Rename or document the bridge as a transient pre-ledger producer buffer, or change semantics to fail closed on capacity.
- Require every bridge append path to return or emit the TempleOS ledger sequence ID after synchronous Book-of-Truth append.
- Add a capacity-exhaustion test asserting secure-local GPU dispatch blocks or halts rather than overwriting unaudited records.

## Non-Findings

- No current air-gap breach was found or induced by this audit.
- No WS8 networking task was executed.
- No TempleOS guest, QEMU, or VM command was run.
- No non-HolyC implementation was added to either builder repo.

## Read-Only Verification Commands

- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD`
- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD`
- `git -C /Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55 rev-parse HEAD`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '1,260p'`
- `rg -n "BookTruthSourceName|BOT_SOURCE_|BOT_EVENT_" /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruthSerialCore.HC`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/book_of_truth_bridge.HC | sed -n '1,240p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/attestation_manifest.HC | sed -n '1,380p'`
- `rg -n "GPU|IOMMU|Book-of-Truth|secure-local|profile|quarantine|policy parity|trinity" /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/LOOP_PROMPT.md /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md`
- `rg -n "GPU|IOMMU|Book-of-Truth|secure-local|profile|quarantine" /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src`
