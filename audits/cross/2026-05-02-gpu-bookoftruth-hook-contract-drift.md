# Cross-Repo GPU Book-of-Truth Hook Contract Drift

Audit timestamp: 2026-05-02T07:14:26+02:00

Audit angle: cross-repo invariant check. This pass compared current TempleOS `HEAD` (`9f3abbf263982bf9344f8973a52f845f1f48d109`) against current holyc-inference `HEAD` (`2799283c9554bea44c132137c590f02034c8f726`) for the GPU secure-local Book-of-Truth hook contract. It was read-only for both sibling repositories. No TempleOS or holyc-inference source was modified. No live liveness watching, process restart, QEMU/VM command, networking command, or WS8 networking task was executed. The TempleOS guest air-gap was not touched.

Analyzer: `audits/cross/2026-05-02-gpu-bookoftruth-hook-contract-drift.py`

## Summary

holyc-inference currently models GPU dispatch as allowed only when IOMMU plus three Book-of-Truth hooks are active: DMA, MMIO, and dispatch. TempleOS has current GPU IOMMU and MMIO guard surfaces, and those paths record through `BookTruthDMARecord`, but the Book-of-Truth schema does not expose a native GPU dispatch event/source or distinct MMIO hook bit that maps cleanly to the inference contract. The result is a cross-repo contract drift, not a confirmed live air-gap breach.

Finding count: 5 warnings.

## Evidence Matrix

| Check | Result |
| --- | ---: |
| TempleOS has `BOT_DMA_PAYLOAD_MARKER` | 1 |
| TempleOS has `BookTruthDMARecord` | 1 |
| TempleOS has `IOMMUGPUMap` | 1 |
| TempleOS has `IOMMUGPUMMIOWrite` | 1 |
| TempleOS has a GPU dispatch Book-of-Truth event | 0 |
| TempleOS has a GPU/inference Book-of-Truth source | 0 |
| holyc-inference policy requires DMA/MMIO/dispatch hook booleans | 1 |
| holyc-inference bridge has dispatch event type | 1 |
| holyc-inference bridge documents overwrite-on-full behavior | 1 |
| holyc-inference policy digest defaults all hook booleans to enabled | 1 |

## Findings

### WARNING-001: Inference requires a dispatch hook that TempleOS does not currently publish as a Book-of-Truth event

Law: Book of Truth Immediacy and Hardware Proximity; cross-repo invariant.

Evidence: `holyc-inference/src/gpu/policy.HC` denies dispatch unless `bot_dma_log_enabled`, `bot_mmio_log_enabled`, and `bot_dispatch_log_enabled` are all true. `holyc-inference/src/gpu/book_of_truth_bridge.HC` defines `BOT_GPU_EVENT_DISPATCH` and dispatch operations. TempleOS `Kernel/BookOfTruth.HC` currently defines event IDs through `BOT_EVENT_SERIAL_WATCHDOG` and DMA payload markers, but no `BOT_EVENT_GPU_DISPATCH`, `BOT_GPU_EVENT_DISPATCH`, or equivalent dispatch-specific Book-of-Truth event.

Impact: inference can pass its own secure-local policy with a caller-supplied dispatch boolean even though the TempleOS producer side has no native dispatch ledger row to prove that boolean.

### WARNING-002: MMIO is logged through the generic DMA payload path, while inference treats MMIO as a separate hook

Law: Book of Truth Immediacy and Hardware Proximity; cross-repo invariant.

Evidence: TempleOS `Kernel/IOMMU.HC` routes `IOMMUGPUMMIOWrite` through `BookTruthDMARecord(BOT_DMA_OP_WRITE, ...)`, and `BookTruthDMARecord` appends a `BOT_EVENT_NOTE` with a `BOT_DMA_PAYLOAD_MARKER`. holyc-inference separately models `bot_dma_log_enabled` and `bot_mmio_log_enabled`, and its bridge has separate `BOT_GPU_EVENT_DMA` and `BOT_GPU_EVENT_MMIO` event types.

Impact: consumers cannot distinguish "MMIO hook active" from "generic DMA write payload exists" without an out-of-band convention. That weakens the secure-local proof because the boolean contract is more specific than the TempleOS ledger vocabulary.

### WARNING-003: The inference bridge is an overwrite ring, not the TempleOS immutable Book-of-Truth ledger

Law: Book of Truth Immutability; cross-repo invariant.

Evidence: `holyc-inference/src/gpu/book_of_truth_bridge.HC` writes `BOTGPUEvent` rows into caller-provided storage and documents that ring progression overwrites the oldest event when full. TempleOS Book-of-Truth doctrine requires no deletion or overwrite of sealed log pages.

Impact: the bridge can be a staging structure, but it should not be treated as equivalent to the TempleOS Book-of-Truth until there is an explicit append/serial/hash-chain handoff contract. Without that, "Book-of-Truth bridge" evidence can be mistaken for immutable ledger evidence.

### WARNING-004: TempleOS source vocabulary has no GPU or inference source class

Law: Book of Truth Local Access Only; Book of Truth Immediacy; cross-repo invariant.

Evidence: TempleOS sources currently end at `BOT_SOURCE_DISK`, with names for kernel, cli, irq, msr, exception, io, and disk. Current GPU IOMMU and MMIO paths record with `BOT_SOURCE_KERNEL`. holyc-inference, meanwhile, models GPU DMA, MMIO, and dispatch as first-class security events.

Impact: a future cross-repo parser cannot identify whether a Book-of-Truth row came from the GPU/inference control plane versus generic kernel activity. This is traceability drift, especially for dispatch and reset-scrub proofs.

### WARNING-005: holyc-inference defaults all hook booleans to enabled before binding them to TempleOS evidence

Law: North Star Discipline; cross-repo invariant.

Evidence: `holyc-inference/src/runtime/policy_digest.HC` initializes `g_policy_bot_dma_log_enabled`, `g_policy_bot_mmio_log_enabled`, and `g_policy_bot_dispatch_log_enabled` to `1`. The updater validates that inputs are binary, but the repo-level search found no current TempleOS-derived importer that proves these booleans from Book-of-Truth rows.

Impact: the runtime can build a policy digest that assumes all Book-of-Truth hooks are on, while the producer repo only has directly observable DMA/MMIO-ish evidence and lacks a dispatch event. This should remain fail-closed until the booleans are derived from actual local ledger evidence.

## Recommended Follow-Up

- Define a shared GPU Book-of-Truth ABI: event IDs, source IDs, payload layouts, and dispatch lifecycle rows.
- Make inference hook booleans provenance-bearing: derived from parsed local Book-of-Truth rows, not default-on globals or test fixtures.
- Either split TempleOS MMIO into a distinct Book-of-Truth payload/event or explicitly document how `BOT_DMA_OP_WRITE` over the GPU MMIO channel proves `bot_mmio_log_enabled`.
- Treat `BOTGPUBridge` as a staging queue unless it synchronously appends to the TempleOS immutable/serial/hash-chain ledger.

## Read-Only Verification

```bash
python3 audits/cross/2026-05-02-gpu-bookoftruth-hook-contract-drift.py
```

No QEMU/VM command was executed. No networking was enabled or touched.
