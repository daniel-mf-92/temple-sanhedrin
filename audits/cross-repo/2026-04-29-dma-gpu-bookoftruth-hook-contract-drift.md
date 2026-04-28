# Cross-Repo DMA/GPU Book-of-Truth Hook Contract Drift Audit

Timestamp: `2026-04-29T00:11:54+02:00`

Audit angle: cross-repo invariant check. This pass checked whether TempleOS' current DMA Book-of-Truth telemetry can satisfy holyc-inference's GPU dispatch assumptions for DMA, MMIO, and dispatch hooks.

Repositories audited:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `03f24a1a3f583ae01717a21c94c6353b0587a650`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `ce09228422dae06e86feb84925d51df88d67821b`
- Sanhedrin audit repo: `/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55` at `5521839870f412fbd31ad8df36f44cb7e0d57186`

Safety posture: read-only against TempleOS and holyc-inference. No TempleOS guest, QEMU, VM, WS8 networking task, socket, TCP/IP, UDP, TLS, DHCP, DNS, or HTTP work was executed.

## Summary

Found 5 findings: 0 critical, 5 warnings.

TempleOS has progressed beyond the older "no DMA telemetry exists" state: `BookTruthDMARecord` now packs DMA fields into a `BOT_DMA_PAYLOAD_MARKER` payload and appends them to the Book of Truth. The cross-repo drift is that this is a generic `BOT_EVENT_NOTE` / `BOT_SOURCE_IO` payload, while holyc-inference gates GPU dispatch on three separate hook claims: DMA logging, MMIO logging, and dispatch logging. Those hook claims still do not have a one-to-one TempleOS ledger contract.

## Findings

### Finding WARNING-001: TempleOS DMA records are generic NOTE events, not a canonical GPU DMA event family

Evidence:
- `TempleOS/Kernel/BookOfTruth.HC:3-22` defines canonical event IDs through `BOT_EVENT_SERIAL_WATCHDOG`; there is no `BOT_EVENT_DMA` or `BOT_EVENT_GPU_DMA`.
- `TempleOS/Kernel/BookOfTruth.HC:39` reserves `BOT_DMA_PAYLOAD_MARKER`.
- `TempleOS/Kernel/BookOfTruth.HC:79566-79593` implements `BookTruthDMARecord`, but appends with `BookTruthAppend(BOT_EVENT_NOTE, source, payload)`.
- `holyc-inference/src/gpu/book_of_truth_bridge.HC:22-24` distinguishes `BOT_GPU_EVENT_DMA`, `BOT_GPU_EVENT_MMIO`, and `BOT_GPU_EVENT_DISPATCH`.

Assessment:
TempleOS can now log DMA-shaped payloads, which is real progress, but the ledger event type remains `NOTE`. A Sanhedrin parser cannot distinguish DMA as a first-class ledger event without payload-marker inspection, and holyc-inference's GPU bridge expects DMA to be its own event class.

Required closure:
- Reserve a canonical TempleOS DMA/GPU event family or explicitly document that `BOT_EVENT_NOTE + BOT_DMA_PAYLOAD_MARKER` is the stable ABI.
- If the marker path is intentional, add a cross-repo check that maps `BOT_GPU_EVENT_DMA` to `BOT_EVENT_NOTE/BOT_DMA_PAYLOAD_MARKER` by name and value.

### Finding WARNING-002: TempleOS DMA payload schema does not encode the inference GPU lease/BAR/dispatch tuple semantics

Evidence:
- `TempleOS/Kernel/BookOfTruth.HC:79524-79529` encodes DMA as marker, op, channel, byte count, device, and flags.
- `holyc-inference/src/gpu/book_of_truth_bridge.HC:166-181` records GPU DMA as operation, lease id, physical address, byte count, and IOMMU domain.
- `holyc-inference/src/gpu/book_of_truth_bridge.HC:184-198` records MMIO writes as BAR index, register offset, value, and width.
- `holyc-inference/src/gpu/book_of_truth_bridge.HC:201-210` records dispatch with queue id, descriptor address, descriptor bytes, and fence id.

Assessment:
The TempleOS DMA payload is useful for generic DMA accounting, but it does not carry the fields holyc-inference uses to prove GPU isolation and command provenance. The missing join fields are especially important for lease ownership and descriptor/fence replay.

Required closure:
- Define a shared payload schema for GPU DMA lease id, IOMMU domain, physical range, BAR/MMIO register identity, dispatch descriptor hash, queue id, and fence id.
- Keep the schema integer-only and HolyC-owned on both sides.

### Finding WARNING-003: holyc-inference treats DMA, MMIO, and dispatch hook readiness as independent booleans, but TempleOS currently exposes only a generic DMA recorder

Evidence:
- `holyc-inference/src/gpu/policy.HC:34-40` accepts `bot_dma_log_enabled`, `bot_mmio_log_enabled`, and `bot_dispatch_log_enabled` independently.
- `holyc-inference/src/gpu/policy.HC:82-90` denies dispatch unless all three hook booleans are true.
- `holyc-inference/src/gpu/security_perf_matrix.HC:408-467` allows rows from the combined `book_of_truth_gpu_hooks` boolean.
- `TempleOS/Kernel/BookOfTruth.HC:79566-79603` provides DMA record/decode/status support, but this reviewed path does not provide equivalent MMIO or dispatch append contracts.

Assessment:
The inference policy is fail-closed locally, but it cannot be proven from current TempleOS ledger APIs that all three required hook classes are active. A true DMA recorder does not imply true MMIO and dispatch ledger coverage.

Required closure:
- Split TempleOS producer readiness into three explicit proof surfaces: DMA append proof, MMIO append proof, and dispatch append proof.
- Reject `book_of_truth_gpu_hooks=1` unless all three proof surfaces are present and decode against TempleOS constants.

### Finding WARNING-004: Source taxonomy still collapses DMA/GPU provenance into `BOT_SOURCE_IO`

Evidence:
- `TempleOS/Kernel/BookOfTruth.HC:92-99` defines sources only as kernel, CLI, IRQ, MSR, exception, IO, and disk.
- `TempleOS/Kernel/BookOfTruth.HC:79566-79568` defaults `BookTruthDMARecord` to `BOT_SOURCE_IO`.
- `holyc-inference/src/gpu/book_of_truth_bridge.HC:9-12` treats GPU DMA lifecycle, MMIO writes, and dispatch submissions as security-critical GPU event classes.

Assessment:
`BOT_SOURCE_IO` is too broad to prove GPU-specific producer health. Source-level reports can show IO activity while hiding whether the activity was generic port/DMA logging, GPU DMA lease logging, MMIO writes, or command dispatch evidence.

Required closure:
- Add a GPU source, a DMA source, or a documented source-subclassification payload contract.
- Extend source-mask and source-status smoke fixtures so GPU evidence cannot pass under generic IO without an explicit mapping.

### Finding WARNING-005: Runtime policy digest defaults can still claim hook readiness without TempleOS ledger identity

Evidence:
- `holyc-inference/src/runtime/policy_digest.HC:29-31` defaults DMA, MMIO, and dispatch Book-of-Truth hook flags to enabled.
- `holyc-inference/src/runtime/policy_digest.HC:141-143` serializes those hook flags into policy bits.
- `TempleOS/Kernel/BookOfTruth.HC:110-119` defines canonical ledger entries as sequence, TSC, event type, source, payload, previous hash, and entry hash.
- The reviewed inference hook bits carry no TempleOS sequence, event type, source, payload marker, previous hash, or entry hash.

Assessment:
The policy digest can represent hook readiness, but it is not yet bound to a TempleOS ledger identity. This is weaker than the Book-of-Truth invariant because a digest bit can be true without proving any immutable append occurred.

Required closure:
- Replace bare hook booleans in trusted GPU evidence with append-proof tuples: `{event_type, source, payload_marker, seq, entry_hash, serial_liveness_ok}`.
- Default GPU hook bits off unless supplied by a TempleOS-generated proof bundle.

## Non-Findings

- No air-gap breach was found or induced.
- No WS8 networking task was executed.
- No QEMU or VM command was run.
- No source files in TempleOS or holyc-inference were modified.
- The new TempleOS DMA payload path is HolyC and remains inside the local Book-of-Truth surface; the finding is schema drift, not a Law 1 violation.

## Read-Only Verification Commands

```bash
sed -n '1,240p' LAWS.md
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS status --short --branch
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference status --short --branch
git -C /Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55 rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '1,120p;79520,79710p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/book_of_truth_bridge.HC | sed -n '1,210p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/policy.HC | sed -n '1,130p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/security_perf_matrix.HC | sed -n '400,520p'
rg -n "BOT_EVENT_DMA|BOT_EVENT_GPU|BOT_EVENT_MMIO|BOT_EVENT_DISPATCH|BOT_SOURCE_GPU|BookTruthDMARecord|BOT_DMA_PAYLOAD_MARKER|BOT_EVENT_NOTE" /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC
rg -n "BOT_GPU_EVENT|BOTGPUBridgeRecord|GPUPolicyAllowDispatchChecked|book_of_truth_gpu_hooks|bot_dma_log_enabled|bot_mmio_log_enabled|bot_dispatch_log_enabled" /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime -g '*.HC'
```
