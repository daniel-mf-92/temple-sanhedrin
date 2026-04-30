# Cross-Repo Audit: Book-of-Truth GPU Bridge vs Immutable Ledger Contract

Date: 2026-04-30T09:50:33Z
Scope: TempleOS + holyc-inference cross-repo invariant check
Repos audited:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`

## Invariant

Inference-side GPU, model, and token audit hooks must resolve to the TempleOS Book of Truth as the authoritative immutable append ledger. A bridge or release gate must not treat an in-memory event buffer, marker presence, or host-side evidence as equivalent to TempleOS `BookTruthAppend` / serial-backed fail-stop behavior.

Applicable laws:
- Law 3: Book of Truth immutability
- Law 8: synchronous hardware-proximate Book of Truth recording
- Law 9: crash on log failure
- Law 11: local access only

## Evidence

TempleOS records DMA events through the real Book of Truth append path:
- `Kernel/BookOfTruth.HC:81740-81767` defines `BookTruthDMARecord(...)`, updates DMA counters, encodes payload with the TempleOS DMA payload schema, and returns `BookTruthAppend(BOT_EVENT_NOTE,source,payload)`.
- `Kernel/BookOfTruth.HC:81798-81880` reports DMA status from `bot_entries` with `verify_state`, sequence range, payload decode failures, and digest.
- `Kernel/BookOfTruthSerialCore.HC:1236-1254` samples COM1 LSR with `InU8(BOT_COM1_BASE+BOT_COM1_LSR)` and appends serial watchdog events through `BookTruthAppend`.
- `Kernel/BookOfTruthSerialCore.HC:1378-1386` appends serial-dead evidence and calls `BookTruthWriteFailHlt(...)` when liveness fails.

holyc-inference currently has a separate GPU bridge abstraction:
- `src/gpu/book_of_truth_bridge.HC:36-54` defines `BOTGPUEvent` and `BOTGPUBridge` as caller-provided storage with `capacity`, `count`, `head`, and `next_seq_id`.
- `src/gpu/book_of_truth_bridge.HC:104-163` writes into `bridge->events[bridge->head]`, advances modulo `capacity`, and explicitly notes that it overwrites the oldest event when full.
- `src/gpu/book_of_truth_bridge.HC:166-211` records DMA/MMIO/dispatch events into that bridge, not into TempleOS `BookTruthDMARecord` or `BookTruthAppend`.
- `automation/inference-secure-gate.sh:63-65` passes WS9-08/WS9-17 by checking only for marker strings `BOTGPUBridgeRecordMMIOWrite` and `BOT_GPU_DMA_UNMAP`.

Search checks run:

```text
rg -n "BookTruthAppend|BookTruthDMARecord|BookTruthSerial|BOT_GPU|BOTGPU" src/gpu/book_of_truth_bridge.HC automation/inference-secure-gate.sh
rg -n "BOT_GPU|BOTGPU|BookTruthDMARecord|BookTruthDMAPayload|BookTruthAppend\(BOT_EVENT_NOTE" Kernel/BookOfTruth.HC
```

## Findings

1. CRITICAL - The inference secure-local gate can pass with a non-Book-of-Truth ring buffer.

   The inference gate treats marker presence in `src/gpu/book_of_truth_bridge.HC` as evidence that Book-of-Truth DMA/MMIO/dispatch hooks exist. The audited bridge records into caller-provided storage and wraps at fixed capacity. It has no call to TempleOS `BookTruthAppend`, no serial liveness/fail-stop path, and no binding to the TempleOS DMA payload schema. This is cross-repo drift from Law 3 and Law 8 because a bounded overwrite buffer is not an immutable append ledger.

2. WARNING - The GPU event schema is not joined to TempleOS's DMA evidence schema.

   holyc-inference uses generic `{event_type,event_op,arg0..arg3}` fields and GPU-specific constants. TempleOS's audited DMA status expects `BookTruthDMAPayloadEncode(op,chan,bytes,dev,iommu,blocked)` and reports read/write/bidir, IOMMU, blocked, sequence bounds, verify state, and digest. Without a documented mapping or shared fixture, Sanhedrin cannot prove that an inference `BOT_GPU_DMA_UNMAP` event is the same evidence class TempleOS later reports via `BookTruthDMAStatus`.

3. WARNING - Release gating checks for symbolic hooks, not immutable/local evidence.

   `automation/inference-secure-gate.sh` accepts the Book-of-Truth bridge when two strings are present. It does not require a TempleOS-side status line, serial-log replay fixture, digest parity, fail-stop evidence, or local-only access proof. This leaves WS9-08/WS9-17 green even if the runtime only emits local bridge records that never reach the TempleOS Book of Truth.

## Recommended Follow-Up

- Add a cross-repo contract doc or fixture that maps inference GPU events to TempleOS `BookTruthDMARecord` payload fields.
- Harden `automation/inference-secure-gate.sh` so WS9-08/WS9-17 require a TempleOS-compatible evidence tuple, not only marker strings.
- Require a replayable local serial fixture showing the corresponding `BookTruthDMAStatus` digest and sequence range for representative map/update/unmap/MMIO/dispatch events.

No trinity source code was modified during this audit.
