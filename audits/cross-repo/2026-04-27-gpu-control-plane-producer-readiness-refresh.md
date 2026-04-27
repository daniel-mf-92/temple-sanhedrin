# Cross-Repo Invariant Audit: GPU Control-Plane Producer Readiness Refresh

Timestamp: 2026-04-27T17:24:45Z

Auditor: gpt-5.5 sibling, retroactive/deep audit scope

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source code was modified.

Repos examined:
- TempleOS: `12fa74055c4388ff14426a89537d0a21a1124d2c`
- holyc-inference: `6f5e1f5b4e1b200b81d0e0f0a3b31c03073f7c6a`
- temple-sanhedrin: branch `codex/sanhedrin-gpt55-audit`

## Executive Summary

Found 4 findings: 2 critical, 2 warnings.

The previous GPU Book-of-Truth drift audit documented that inference-side bounded rings/transcripts are weaker than TempleOS WS13 Book-of-Truth semantics. This refresh checks current HEADs for the next integration question: can TempleOS currently produce the proofs that holyc-inference GPU/key gates require?

Answer: not yet. holyc-inference has moved ahead with GPU dispatch, attestation, and key-release guard surfaces, while TempleOS still lists the matching GPU/IOMMU/approval producers as future work and its kernel Book-of-Truth event/source vocabulary has no GPU or inference producer ABI.

## Finding CRITICAL-001: Inference GPU dispatch gate requires BoT GPU hooks that TempleOS cannot currently produce

Applicable laws:
- Law 3: Book of Truth immutability
- Law 8: Book of Truth immediacy and hardware proximity
- Law 9: crash on log failure

Evidence:
- `holyc-inference/src/gpu/policy.HC:4-8` says dispatch is denied unless IOMMU and Book-of-Truth DMA/MMIO/dispatch hooks are all active.
- `holyc-inference/src/gpu/policy.HC:34-40` takes `iommu_enabled`, `bot_dma_log_enabled`, `bot_mmio_log_enabled`, and `bot_dispatch_log_enabled` as the gate inputs.
- `holyc-inference/src/gpu/policy.HC:76-90` fails closed when IOMMU or any BoT hook flag is missing, then allows dispatch only after all four prerequisites are true.
- `TempleOS/Kernel/BookOfTruth.HC:3-22` defines `BOT_EVENT_*` only through `BOT_EVENT_SERIAL_WATCHDOG`; no GPU, DMA-map, MMIO-write, dispatch-submit, dispatch-complete, or dispatch-timeout event exists.
- `TempleOS/Kernel/BookOfTruth.HC:79-86` defines sources through `BOT_SOURCE_DISK`; no GPU, inference worker, accelerator, or device-source identity exists.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:267-274` still lists WS14-09 through WS14-16 as unchecked future tasks for GPU stage definition, IOMMU domain manager, MMIO allowlist, DMA lease model, reset/scrub, dispatch transcript capture, perf guardrails, and fail-closed CPU-only boot gate.

Assessment:
The inference runtime now has a strict GPU admission contract, but the TempleOS control plane lacks the producer vocabulary and implementation needed to truthfully set the BoT hook booleans. Wiring those booleans to anything other than a synchronous TempleOS WS13 append path would recreate the earlier drift.

Required remediation:
- Add TempleOS-side `BOT_EVENT_GPU_*` and `BOT_SOURCE_*` ABI entries for DMA, MMIO, and dispatch lifecycle events before any secure-local GPU dispatch is enabled.
- Define the exact payload layout for each GPU event and require direct `BookTruthAppend`/UART semantics, not a worker-plane mirror.
- Keep holyc-inference GPU dispatch disabled until those producers exist and Sanhedrin can check parity.

## Finding CRITICAL-002: Inference key release requires TempleOS signed approval, but TempleOS has no matching approval primitive

Applicable laws:
- Law 3: Book of Truth immutability
- Law 8: Book of Truth immediacy and hardware proximity
- Law 11: Book of Truth local access only

Evidence:
- `holyc-inference/src/runtime/key_release_gate.HC:4-10` states release requires TempleOS signed approval, valid attestation evidence, and policy digest parity.
- `holyc-inference/src/runtime/key_release_gate.HC:29-34` models `templeos_signed_approval` as a first-class verifier input.
- `holyc-inference/src/runtime/key_release_gate.HC:71-84` sets failure bit 0 when signed approval is missing and releases only when all failure bits are zero.
- A read-only scan of `TempleOS/Kernel` and `TempleOS/MODERNIZATION` found approval references in docs and compatibility templates, but no kernel producer for signed runtime approval tied to Book-of-Truth rows, local console presence, or immutable-image state.

Assessment:
The key-release gate is well-shaped as an inference-side verifier, but the required TempleOS proof source does not exist at current HEAD. A future integration could pass a boolean from automation or worker state and falsely satisfy "TempleOS signed approval" without a local, auditable TempleOS control-plane act.

Required remediation:
- Define a TempleOS approval primitive that records local approval in the Book of Truth and binds it to policy digest, session id, and immutable-image state.
- Ensure the approval path has no remote API/export dependency and cannot be produced by holyc-inference itself.
- Add a Sanhedrin invariant that rejects key release unless the approval proof is TempleOS-originated.

## Finding WARNING-001: Attestation manifest already exposes GPU/IOMMU/BoT fields before TempleOS can authoritatively populate them

Applicable laws:
- Law 5: North Star discipline
- Law 8: Book of Truth immediacy and hardware proximity

Evidence:
- `holyc-inference/src/runtime/attestation_manifest.HC:17-30` includes `gpu_dispatch_allowed`, `iommu_active`, and `bot_gpu_hooks_active` as attestation fields.
- TempleOS current kernel Book-of-Truth source/event vocabulary has no GPU source or GPU event ABI.
- TempleOS modernization docs acknowledge the intended control-plane rules: `MODERNIZATION/LOOP_PROMPT.md:57` requires performance with `secure-local` plus Book-of-Truth plus IOMMU, and `MODERNIZATION/LOOP_PROMPT.md:65-66` requires GPU-related changes only with explicit IOMMU enforcement and Book-of-Truth DMA/MMIO logging hooks.

Assessment:
The manifest fields are useful placeholders, but they are ahead of the control-plane producer. They should be treated as unset/false until TempleOS can provide the corresponding facts.

Required remediation:
- Document `bot_gpu_hooks_active=0` as mandatory until TempleOS GPU BoT append ABI exists.
- Add a manifest verifier rule that rejects `bot_gpu_hooks_active=1` unless it is backed by TempleOS event/source IDs and recent local Book-of-Truth rows.

## Finding WARNING-002: TempleOS docs require cross-trinity GPU parity, but current repos do not expose a concrete parity contract

Applicable laws:
- Law 5: North Star discipline
- Law 6: queue health, insofar as queue items must trace to real WS tasks

Evidence:
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:52-53` says GPU enablement must have matching enforcement tasks in holyc-inference and matching Sanhedrin critical checks, and policy changes must patch all three policy docs or create explicit blocking items.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:267-274` lists the TempleOS GPU producer tasks as future work.
- holyc-inference already has concrete HolyC files for GPU policy, Book-of-Truth bridge, DMA leases, MMIO allowlist, dispatch transcript, and security/performance matrix under `src/gpu/`.

Assessment:
The high-level parity rule exists, but there is no single shared ABI/spec document that both repos can implement against. That makes future Sanhedrin enforcement depend on scattered names and boolean conventions instead of a durable contract.

Required remediation:
- Create a shared cross-repo GPU control-plane ABI note covering event IDs, payload fields, source identities, approval proof shape, and failure behavior.
- Sanhedrin should check that holyc-inference booleans cannot be considered true unless TempleOS exposes the matching event ABI.

## Non-Findings

- No QEMU or VM command was executed during this audit.
- No networking stack or network task was touched.
- The inspected holyc-inference GPU/runtime files are HolyC and integer-oriented; this audit flags producer/consumer contract drift, not a language-purity violation.

## Read-Only Verification Commands

- `nl -ba TempleOS/Kernel/BookOfTruth.HC | sed -n '1,120p'`
- `nl -ba holyc-inference/src/gpu/policy.HC | sed -n '1,110p'`
- `nl -ba holyc-inference/src/gpu/book_of_truth_bridge.HC | sed -n '1,160p'`
- `nl -ba holyc-inference/src/runtime/key_release_gate.HC | sed -n '1,130p'`
- `nl -ba holyc-inference/src/runtime/attestation_manifest.HC | sed -n '1,70p'`
- `rg -n "GPU|DMA|MMIO|IOMMU|signed approval|signed_approval|approval" TempleOS/Kernel TempleOS/MODERNIZATION`
- `rg -n "BOT_GPU|BOT_EVENT_GPU|BOT_SOURCE_GPU|BOT_EVENT_DMA|BOT_EVENT_MMIO|BOT_EVENT_DISPATCH|BOT_SOURCE_INFERENCE" TempleOS/Kernel/BookOfTruth.HC TempleOS/Kernel/KernelA.HH`
