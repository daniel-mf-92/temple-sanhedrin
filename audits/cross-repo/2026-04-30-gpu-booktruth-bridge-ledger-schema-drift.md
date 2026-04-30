# Cross-Repo Audit: GPU Book-of-Truth Bridge Ledger Schema Drift

Audit timestamp: 2026-04-30T13:00:36+02:00

Scope: cross-repo invariant check between `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `0b35c1a70820aa59170ff9a8216bbf24936a3ee2` and `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554bea44c132137c590f02034c8f726`.

This audit was read-only against TempleOS and holyc-inference. It did not run QEMU, did not start a VM, did not inspect live loop liveness, did not execute any WS8 networking task, and did not modify trinity source code.

## Invariant

If holyc-inference marks GPU acceleration as allowable only when IOMMU enforcement plus Book-of-Truth GPU telemetry are active, its GPU telemetry bridge must map to the TempleOS sealed Book-of-Truth ledger schema. A GPU event accepted by inference-side policy should be representable as a local, append-only TempleOS ledger row with enough event identity to distinguish DMA mapping, MMIO writes, dispatch submit/complete/timeout, IOMMU state, and fail-closed blocked state.

This matters for Laws 3, 5, 8, and 9. The security claim is not just "a host-side buffer saw an event"; it is "the guest recorded the event synchronously into the immutable local ledger and would fail closed if the record could not be written."

## Findings

1. **WARNING - holyc-inference's GPU bridge is an in-memory event ring, not a TempleOS Book-of-Truth append contract.**
   Evidence: `src/gpu/book_of_truth_bridge.HC:36-54` defines private `BOTGPUEvent` and `BOTGPUBridge` storage with `events`, `capacity`, `count`, `head`, and `next_seq_id`; `src/gpu/book_of_truth_bridge.HC:104-164` appends by writing the caller-provided ring slot and advancing `head`. There is no call to TempleOS `BookTruthAppend`, no serial output path, no sealed-log failure return from TempleOS, and no shared ABI field for TempleOS' `seq`, `tsc`, `event_type`, `source`, `payload`, or hash-chain state.

2. **WARNING - TempleOS currently exposes only generic DMA payload rows for GPU-adjacent telemetry.**
   Evidence: `Kernel/BookOfTruth.HC:3-22` defines ledger event types only through `BOT_EVENT_SERIAL_WATCHDOG` and does not define `BOT_EVENT_GPU_DMA`, `BOT_EVENT_GPU_MMIO`, or `BOT_EVENT_GPU_DISPATCH`. `Kernel/BookOfTruth.HC:81770-81798` records DMA by encoding marker `BOT_DMA_PAYLOAD_MARKER` and appending `BookTruthAppend(BOT_EVENT_NOTE, source, payload)`. This can prove "some DMA-like payload existed" but cannot natively distinguish inference GPU dispatch lifecycle from other note payloads at the ledger event-type layer.

3. **WARNING - the two repos disagree on GPU operation vocabulary.**
   Evidence: holyc-inference uses `BOT_GPU_EVENT_DMA`, `BOT_GPU_EVENT_MMIO`, and `BOT_GPU_EVENT_DISPATCH` with ops for map/update/unmap, MMIO write, and dispatch submit/complete/timeout in `src/gpu/book_of_truth_bridge.HC:22-34`. TempleOS' DMA payload schema encodes only `BOT_DMA_OP_READ`, `BOT_DMA_OP_WRITE`, and `BOT_DMA_OP_BIDIR` plus `chan`, `bytes`, `dev`, `iommu`, and `blocked` in `Kernel/BookOfTruth.HC:66-70` and `Kernel/BookOfTruth.HC:81703-81733`. There is no shared mapping for MMIO register writes or dispatch completion/timeout.

4. **WARNING - TempleOS' DMA smoke validates source and payload marker, not the inference bridge contract.**
   Evidence: `automation/bookoftruth-dma-smoke.sh:34-38` expects marker `D2`, `src=6`, and a `BookTruthDMAStatus` summary. `automation/bookoftruth-dma-smoke.sh:82-107` counts marker rows and rejects non-`src=6` rows, but it does not assert any `BOT_GPU_EVENT_*` fields, dispatch operation states, MMIO allowlist fields, model/profile join keys, or correlation with holyc-inference bridge sequence IDs.

5. **INFO - no direct air-gap or HolyC purity violation was found in this audit.**
   Evidence: the inspected implementation files are HolyC or host-side tests/smokes in allowed paths. This audit executed only local read commands and did not run QEMU or any network-dependent workflow.

## Required Closure

- Define a shared GPU Book-of-Truth ABI that both repos can name, including event class, operation, sequence/correlation ID, model/profile context, IOMMU state, blocked/fail-closed state, and digest/hash-chain join fields.
- Add TempleOS ledger event types or an explicit payload sub-schema for GPU DMA, MMIO, and dispatch events instead of encoding all GPU-adjacent state as generic `BOT_EVENT_NOTE`.
- Change holyc-inference's bridge to target the shared TempleOS ledger ABI, or clearly mark it as a pre-ledger staging buffer that is insufficient for secure-local release evidence.
- Extend `bookoftruth-dma-smoke.sh` or add a GPU-specific smoke that verifies DMA/MMIO/DISPATCH rows can be parsed from real TempleOS ledger output and joined back to holyc-inference bridge expectations.

## Evidence Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/book_of_truth_bridge.HC | sed -n '1,260p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_gpu_book_of_truth_event_bridge.py | sed -n '1,320p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '1,160p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '81680,81930p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/bookoftruth-dma-smoke.sh | sed -n '1,260p'
```
