# Cross-Repo Audit: Book-of-Truth Hook Semantics Drift

Timestamp: 2026-05-02T06:32:28+02:00

Scope: historical/deep cross-repo invariant check across current heads of `~/Documents/local-codebases/TempleOS` and `~/Documents/local-codebases/holyc-inference`.

Repos inspected:
- TempleOS: `9f3abbf2 feat(modernization): codex iteration 20260501-111528`
- holyc-inference: `2799283c feat(inference): codex iteration 20260430-025722`

Laws evaluated:
- Law 3: Book of Truth immutability.
- Law 8: Book of Truth immediacy and hardware proximity.
- Law 9: resource supremacy / crash on log failure.
- Law 11: local access only.

## Summary

The inference repo has grown several "Book-of-Truth hook" and "attestation" concepts, but those concepts are not semantically equivalent to the TempleOS Book of Truth. The drift is not a direct source-code violation inside holyc-inference, because it is still pure HolyC and hostless, but it is a cross-repo contract risk: inference can report or gate on "BoT hooks active" even when the evidence is only an overwritable local event buffer or a manifest flag, not a TempleOS append path with hash-chain, serial proximity, local-only access, and fail-stop semantics.

Finding count: 5 warnings.

## Findings

### WARNING 1: inference `BOTGPUBridge` overwrites old GPU events while using Book-of-Truth naming

Evidence:
- `holyc-inference/src/gpu/book_of_truth_bridge.HC` defines `BOTGPUBridge` with caller-owned `events`, `capacity`, `count`, `head`, and `next_seq_id`.
- `BOTGPUBridgeAppendChecked` writes into `bridge->events[bridge->head]`, advances `head`, wraps to zero, and explicitly comments that the ring overwrites the oldest event when full.
- TempleOS LAWS.md Law 3 forbids clearing/truncating/overwriting sealed log pages, and Law 8 requires synchronous emission close to UART output rather than a decoupled queue/ring.

Impact:
- Cross-repo consumers may treat `BOTGPUBridge` output as Book-of-Truth-grade evidence, but its retention semantics are the opposite of the immutable/sealed ledger contract.

Recommendation:
- Rename or document the inference structure as a pre-BoT staging/audit buffer unless it is explicitly bridged into TempleOS `BookTruthAppend` semantics.
- Add a trinity policy check that `book_of_truth`-named inference buffers cannot claim immutable ledger semantics unless they prove no overwrite and fail-stop behavior.

### WARNING 2: `bot_gpu_hooks_active` is only a binary attestation field

Evidence:
- `holyc-inference/src/runtime/attestation_manifest.HC` stores `bot_gpu_hooks_active` as a binary field and emits it as `bot_gpu_hooks_active=<0|1>`.
- The manifest does not bind that flag to a TempleOS sequence number, entry hash, serial liveness result, append return, or local-console proof.
- TempleOS `Kernel/BookOfTruthSerialCore.HC` has fail-stop machinery such as `BookTruthWriteFailHlt`, `BookTruthFailStopSet`, and serial TX readiness checks.

Impact:
- A secure inference session can advertise hook activation without proving that the hooks reached the TempleOS ledger or inherited Law 9 fail-stop behavior.

Recommendation:
- Require attestation manifests to distinguish `hook_configured`, `append_confirmed`, `serial_confirmed`, and `failstop_confirmed`.
- Do not let a single binary `bot_gpu_hooks_active` satisfy trinity policy for Book-of-Truth-backed GPU dispatch.

### WARNING 3: GPU security gates require a hook flag, not the TempleOS append contract

Evidence:
- `holyc-inference/src/gpu/security_perf_matrix.HC` repeatedly accepts `book_of_truth_gpu_hooks` as a boolean gate input and snapshots it for parity/digest checks.
- `holyc-inference/automation/inference-secure-gate.sh` checks for the existence of `src/gpu/book_of_truth_bridge.HC` symbols as evidence that Book-of-Truth DMA/MMIO/dispatch hooks exist.
- TempleOS `Kernel/BookOfTruth.HC` exposes concrete DMA recording via `BookTruthDMARecord`, which produces a Book-of-Truth payload and calls `BookTruthAppend`.

Impact:
- Current inference gates can pass on symbol presence and boolean parity even if no cross-repo adapter maps GPU events to TempleOS event types, sources, payloads, and append/fail-stop outcomes.

Recommendation:
- Upgrade the cross-repo gate from symbol existence to contract verification: event class mapping, payload schema compatibility, append result handling, and failure handling.

### WARNING 4: inference token/dispatch event wording risks remote-log semantics

Evidence:
- `holyc-inference/MASTER_TASKS.md` recent IQ items describe `InferenceBookOfTruthTokenEventEmitChecked*` functions that emit per-token Book-of-Truth events with session IDs, token IDs, logits, policy digests, and profile modes.
- Law 11 says Book-of-Truth contents cannot be exposed through remote APIs, export paths, or non-local viewing channels.
- `holyc-inference/src/runtime/attestation_manifest.HC` emits human-readable manifest lines including session IDs, policy digest, counts, and GPU hook state.

Impact:
- If these emitted inference events are later treated as externally consumable attestation artifacts, they could drift into a remote-readable mirror of Book-of-Truth contents.

Recommendation:
- Define a boundary: public/portable inference attestation may contain policy summaries, but not Book-of-Truth ledger contents, sequence IDs, raw payloads, or per-token log evidence.
- Add a LAWS issue if the project wants "attestation" and "Book of Truth" terms to have distinct allowed disclosure semantics.

### WARNING 5: TempleOS has real DMA BoT payloads, but inference uses a separate event taxonomy

Evidence:
- TempleOS defines `BOT_DMA_OP_READ`, `BOT_DMA_OP_WRITE`, `BOT_DMA_OP_BIDIR`, `BookTruthDMAPayloadEncode`, `BookTruthDMAPayloadDecode`, and `BookTruthDMARecord`.
- inference defines `BOT_GPU_EVENT_DMA`, `BOT_GPU_DMA_MAP`, `BOT_GPU_DMA_UPDATE`, and `BOT_GPU_DMA_UNMAP`.
- There is no observed mapping document or contract test tying inference DMA lifecycle events to the TempleOS DMA payload schema.

Impact:
- Cross-repo drift can accumulate where inference records map/update/unmap lifecycle events, while TempleOS records read/write/bidirectional DMA operation payloads. Audits may compare names but miss incompatible event meaning.

Recommendation:
- Add a small `audits/cross-repo` contract table or future trinity policy check mapping inference GPU DMA lifecycle fields to TempleOS DMA payload fields.
- Treat missing mapping as a warning before allowing `book_of_truth_gpu_hooks=1` to satisfy secure-local GPU policy.

## Commands Run

Read-only commands only:
- `git status --short --branch`
- `git log --oneline -n 8`
- `sed -n` over TempleOS and holyc-inference HolyC files
- `rg -n` over TempleOS and holyc-inference sources/tests/docs/automation

No QEMU or VM command was run. No trinity source code was modified.
