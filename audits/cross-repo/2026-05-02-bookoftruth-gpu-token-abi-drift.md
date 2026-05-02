# Cross-Repo Audit: Book-of-Truth GPU/Token ABI Drift

- Timestamp: 2026-05-02T06:40:31+02:00
- Scope: Cross-repo invariant check, current heads only
- TempleOS repo: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS`
- TempleOS HEAD: `9f3abbf263982bf9344f8973a52f845f1f48d109` (`feat(modernization): codex iteration 20260501-111528`, committed 2026-05-01T11:26:42+02:00)
- holyc-inference repo: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`
- holyc-inference HEAD: `2799283c9554bea44c132137c590f02034c8f726` (`feat(inference): codex iteration 20260430-025722`, committed 2026-04-30T03:00:56+02:00)
- Audit angle: Does what TempleOS can record and decode in the Book of Truth match what holyc-inference assumes for GPU dispatch and per-token audit evidence?

## Executive Summary

The trinity policy says TempleOS is the secure-local control plane and Book-of-Truth source of truth, while the inference runtime is an untrusted worker plane. Current heads do not yet share a canonical Book-of-Truth ABI for GPU dispatch or token emission. holyc-inference defines local event tuples and GPU bridge event classes, but TempleOS only recognizes a fixed `BOT_EVENT_*` range, fixed source IDs through `BOT_SOURCE_DISK`, and a generic DMA payload marker (`0xD2`) that collapses GPU MMIO into DMA write payloads.

Findings: 4 warnings, 0 critical. No direct Law 1, Law 2, or Law 4 runtime violation was introduced by this audit; this is release-blocking drift if either repo tries to promote secure-local GPU/token evidence before the ABI is synchronized.

## Findings

### WARNING 1 - GPU Book-of-Truth event vocabulary is split-brain

holyc-inference defines a worker-plane GPU bridge with three first-class event types: `BOT_GPU_EVENT_DMA`, `BOT_GPU_EVENT_MMIO`, and `BOT_GPU_EVENT_DISPATCH`, plus op codes for DMA map/update/unmap, MMIO write, and dispatch submit/complete/timeout.

Evidence:
- `holyc-inference/src/gpu/book_of_truth_bridge.HC:22-34` defines `BOT_GPU_EVENT_DMA`, `BOT_GPU_EVENT_MMIO`, `BOT_GPU_EVENT_DISPATCH`, and operation constants.
- `holyc-inference/src/gpu/book_of_truth_bridge.HC:166-216` appends those events to a local `BOTGPUBridge`.
- `TempleOS/Kernel/BookOfTruth.HC:3-22` defines the canonical Book-of-Truth event IDs, ending at `BOT_EVENT_SERIAL_WATCHDOG`; there is no `BOT_EVENT_GPU`, `BOT_GPU_EVENT_*`, or dispatch event in the TempleOS ledger vocabulary.
- `rg -n "BOT_GPU|GPU_EVENT|DISPATCH|dispatch" Kernel/BookOfTruth.HC Kernel/IOMMU.HC Kernel/KExts.HC MODERNIZATION/MASTER_TASKS.md` found no TempleOS `BOT_GPU` symbols; only task text mentions dispatch.

Impact: an inference worker can produce GPU bridge records that TempleOS cannot recognize as canonical Book-of-Truth entries. That weakens Law 8 hardware-proximity evidence and the secure-local policy claim that GPU activity is Book-of-Truth-audited.

### WARNING 2 - GPU MMIO evidence is encoded differently on each side

TempleOS currently records GPU MMIO allow/deny paths through `BookTruthDMARecord(BOT_DMA_OP_WRITE, ...)`, not through a first-class GPU/MMIO event ABI. holyc-inference separately expects `BOT_GPU_EVENT_MMIO` with `BOT_GPU_MMIO_WRITE`.

Evidence:
- `TempleOS/Kernel/IOMMU.HC:245-260` records denied MMIO writes with `BookTruthDMARecord(BOT_DMA_OP_WRITE, chan, 8, dev, TRUE, TRUE, BOT_SOURCE_KERNEL)`.
- `TempleOS/Kernel/IOMMU.HC:266-270` records allowed MMIO writes with `BookTruthDMARecord(BOT_DMA_OP_WRITE, chan, 8, dev, TRUE, FALSE, BOT_SOURCE_KERNEL)`.
- `TempleOS/Kernel/BookOfTruth.HC:82426-82457` encodes DMA payloads with marker `BOT_DMA_PAYLOAD_MARKER` and fields `{op, chan, bytes, dev, flags}`.
- `holyc-inference/src/gpu/book_of_truth_bridge.HC:184-198` records MMIO as `{BOT_GPU_EVENT_MMIO, BOT_GPU_MMIO_WRITE, bar_index, reg_offset, value, width_bytes}`.

Impact: the MMIO `value` is present in the inference event tuple but not in the TempleOS DMA payload shape, while TempleOS stores `blocked/iommu` flags that the inference MMIO tuple does not. Sanhedrin cannot compare the two sides without an explicit translation contract, so secure-local GPU evidence can pass local tests while remaining non-equivalent across repos.

### WARNING 3 - Per-token inference audit tuple has no TempleOS decode target

holyc-inference has an `INFERENCE_BOT_*` token event tuple with status/digest semantics, but TempleOS has no matching source ID, event type, marker, or decode path for that six-cell tuple.

Evidence:
- `holyc-inference/src/model/inference.HC:26-32` defines `INFERENCE_BOT_EVENT_TUPLE_CELLS`, `INFERENCE_BOT_PROFILE_SECURE`, `INFERENCE_BOT_PROFILE_DEV`, `INFERENCE_BOT_STATUS_BLOCKED`, `INFERENCE_BOT_STATUS_EMITTED`, and FNV-style digest constants.
- `holyc-inference/src/model/inference.HC:4779-4789` publishes a staged token event into caller-provided `event_buffer` only when the status is emitted, then returns status/count/digest.
- `TempleOS/Kernel/BookOfTruth.HC:141-147` defines source IDs only through `BOT_SOURCE_DISK` and `BOT_SOURCE_MASK_ALL`; no `BOT_SOURCE_INFERENCE` or `BOT_SOURCE_WORKER` exists.
- `TempleOS/Kernel/BookOfTruth.HC:82493-82521` has a DMA append path, but no token-event append/decode path equivalent to the inference six-cell token tuple.

Impact: the North Star requirement that "every token" be logged to the Book of Truth is not yet end-to-end. The inference runtime can calculate a deterministic token tuple, but current TempleOS cannot ingest or decode it as a local physical Book-of-Truth record.

### WARNING 4 - secure-local GPU policy is stricter in prose than in executable cross-repo evidence

Both repos state that secure-local GPU dispatch requires IOMMU and Book-of-Truth DMA/MMIO/dispatch hooks. Current executable surfaces do not prove that the three hooks map to TempleOS-recognized ledger events.

Evidence:
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:33-38` says secure-local is the default and GPU is disabled unless IOMMU enforcement and Book-of-Truth GPU logging hooks are active.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:43-47` says TempleOS is the trust/control plane and performance wins only count with IOMMU, Book of Truth, and policy gates enabled.
- `holyc-inference/src/gpu/policy.HC:34-40` accepts boolean inputs for `iommu_enabled`, `bot_dma_log_enabled`, `bot_mmio_log_enabled`, and `bot_dispatch_log_enabled`.
- `holyc-inference/src/gpu/policy.HC:82-90` denies dispatch if any Book-of-Truth hook boolean is false, but those booleans are not tied in this file to TempleOS `BookTruth*` decode/status evidence.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:267-278` still leaves GPU stage definition, DMA lease model, reset/scrub flow, dispatch transcript capture, fail-closed boot gate, attestation verifier, policy-digest handshake, and key-release gate unchecked.

Impact: the policy shape is right, but the current executable invariant is only local to holyc-inference. A worker can satisfy boolean hook arguments without proving that TempleOS can see, decode, and seal the corresponding events.

## Law Mapping

- Law 1: No foreign runtime source violation found in the scoped files; both sides are HolyC for runtime paths.
- Law 2: No networking execution or QEMU command was run during this audit.
- Law 3: No direct Book-of-Truth deletion/disable path found in the scoped evidence.
- Law 8: Drift risk. GPU and token evidence is not yet "as close to hardware as possible" across the control-plane/worker-plane boundary because worker-plane events are not canonical TempleOS ledger events.
- Law 9: Drift risk. A worker-side ring buffer returning local status is not equivalent to TempleOS fail-stop-on-log-failure behavior unless a transport and append contract forces TempleOS `BookTruthAppend` success before dispatch/token success.
- Law 11: No remote log-read path found in scoped evidence; the gap is ABI/ingestion, not remote access.

## Required Remediation Before Secure-Local Promotion

1. Define one canonical Book-of-Truth ABI for GPU DMA, MMIO, dispatch, and token emission in TempleOS first, including event IDs, source IDs, payload markers, decode/status CLIs, and fail-stop behavior.
2. Make holyc-inference emit exactly that ABI, or explicitly label its local bridge as pre-ledger staging evidence that cannot satisfy secure-local Book-of-Truth requirements.
3. Add a cross-repo Sanhedrin check that rejects `bot_*_log_enabled=1` claims unless TempleOS has matching `BookTruth*Status`/decode symbols and fixture evidence for the same event vocabulary.
4. Keep GPU dispatch and token trusted-load paths CPU-only/blocked in secure-local until the ABI and proof path are synchronized.

## Commands Run

```sh
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
rg -n "BookTruth|Book of Truth|BOT_|0x3F8|UART|serial|token.*event|profile_|InferencePolicy|Attestation|key-release|secure-local|GPU_SEC_PERF_PROFILE" src docs automation README.md MASTER_TASKS.md --glob '!automation/logs/**'
rg -n "BOT_EVENT|BOT_SOURCE|BookTruth.*Model|BookTruth.*Token|BookTruth.*GPU|BOT_.*GPU|BOT_.*MODEL|BOT_.*TOKEN|profile_|attestation|secure|IOMMU|MMIO|DMA|GPU" Kernel MODERNIZATION automation --glob '!Kernel/Kernel.MAP' --glob '!automation/*.pyc'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/book_of_truth_bridge.HC | sed -n '1,230p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/inference.HC | sed -n '4580,4965p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/policy.HC | sed -n '1,120p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/IOMMU.HC | sed -n '1,360p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '1,120p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '82420,82645p'
rg -n "BOT_GPU|GPU_EVENT|DISPATCH|dispatch" Kernel/BookOfTruth.HC Kernel/IOMMU.HC Kernel/KExts.HC MODERNIZATION/MASTER_TASKS.md
rg -n "BOT_SOURCE_|BOT_SOURCE_DISK|BOT_SOURCE_IO|BOT_SOURCE_KERNEL" Kernel/BookOfTruth.HC | head -60
```
