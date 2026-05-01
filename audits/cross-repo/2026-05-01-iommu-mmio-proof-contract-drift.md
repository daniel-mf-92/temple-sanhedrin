# Cross-Repo Audit: IOMMU/MMIO Proof Contract Drift

Timestamp: 2026-05-01T12:45:04+02:00

Audit owner: gpt-5.5 sibling, retroactive / historical scope only.

Repos examined:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `9f3abbf263982bf9344f8973a52f845f1f48d109`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554bea44c132137c590f02034c8f726`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at pre-commit `dd942dc902347ed227e64776159610766bca131d`

Audit angle: cross-repo invariant check. TempleOS and holyc-inference were read-only. No QEMU or VM command was executed. No WS8 networking task, socket, NIC, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, package download, live liveness watcher, or current-iteration compliance loop was executed.

## Expected Invariant

TempleOS must be the authoritative trust/control plane for GPU enablement. holyc-inference may keep worker-plane helpers, but any `IOMMU active`, `MMIO allowed`, `Book-of-Truth GPU hooks active`, `policy digest parity`, or `secure-local throughput` claim needs a joinable TempleOS proof: boot-visible profile state, IOMMU/MMIO state, Book-of-Truth event sequence/hash, and fail-closed release/key decision.

Finding count: 5 warnings, 0 critical violations.

## Findings

### WARNING-001: TempleOS MMIO writes are logged as generic DMA notes, not the worker's MMIO event schema

Applicable laws:
- Law 5: North Star Discipline
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- TempleOS `IOMMUGPUMMIOWrite(...)` packs `bar` and `reg` into `chan`, uses a fixed byte width of `8`, and records both allowed and blocked MMIO writes through `BookTruthDMARecord(BOT_DMA_OP_WRITE,chan,8,dev,...)` at `Kernel/IOMMU.HC:235-273`.
- `BookTruthDMARecord(...)` appends the packed payload as `BOT_EVENT_NOTE`, not as a dedicated GPU/MMIO event type, at `Kernel/BookOfTruth.HC:82493-82522`.
- holyc-inference represents MMIO as a separate bridge class, `BOT_GPU_EVENT_MMIO` / `BOT_GPU_MMIO_WRITE`, with fields `{bar_index, reg_offset, value, width_bytes}` in `src/gpu/book_of_truth_bridge.HC:22-30` and `src/gpu/book_of_truth_bridge.HC:184-199`.

Assessment:
The two repos now both have MMIO concepts, but their evidence schemas are not joinable. TempleOS loses explicit width and direct value fields in the ledger payload, while holyc-inference's worker bridge expects those fields to exist as MMIO event arguments.

Required remediation:
- Define a TempleOS Book-of-Truth GPU/MMIO payload marker or event subtype with explicit `{dev, bar, reg, value, width, allowed, blocked}`.
- Require holyc-inference MMIO bridge rows to carry the TempleOS sequence/hash for the matching ledger append before they count as Book-of-Truth evidence.

### WARNING-002: TempleOS MMIO allowlist entries are exact registers, while holyc-inference allows register ranges and width masks

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- TempleOS `CIOMMUGPUMMIO` stores only `{dev, bar, reg, live}` and `IOMMUGPUMMIOFind(...)` matches exact `dev/bar/reg` triples at `Kernel/IOMMU.HC:15-21` and `Kernel/IOMMU.HC:65-75`.
- holyc-inference `GPUMMIOAllowEntry` stores `{bar_index, reg_start, reg_end, width_mask}` and `GPUMMIOAllowlistCheckWriteChecked(...)` validates range containment plus write width at `src/gpu/mmio_allowlist.HC:28-34` and `src/gpu/mmio_allowlist.HC:126-205`.

Assessment:
An inference worker can prove that a write is allowed by a range/width policy, while TempleOS can only prove an exact register slot exists and always logs a width of `8`. That mismatch can produce false policy parity, especially for 1/2/4-byte writes or a range entry that TempleOS has not materialized register by register.

Required remediation:
- Pick one canonical allowlist shape across repos. Prefer TempleOS-authoritative `{bar, start, end, width_mask}` records and make worker helpers verify the same tuple.
- Include the canonical allowlist digest in both TempleOS policy records and holyc-inference policy digest inputs.

### WARNING-003: IOMMU boots enabled by default before GPU stage and fail-closed boot gates exist

Applicable laws:
- Law 5: North Star Discipline
- Law 9: Resource Supremacy / Crash on Log Failure

Evidence:
- TempleOS includes `IOMMU.HC` in `Kernel/Kernel.PRJ:62` and calls `IOMMUGPUInit(TRUE);` during boot after Book-of-Truth profile boot at `Kernel/KMain.HC:145-148`.
- TempleOS task state still leaves GPU stage definition, bounded DMA lease model, reset/scrub, dispatch transcript, fail-closed boot gate, control/worker contract, attestation verifier, policy-digest handshake, and key-release gate open at `MODERNIZATION/MASTER_TASKS.md:267-278`.
- TempleOS policy says `secure-local` GPU is disabled unless IOMMU enforcement and Book-of-Truth GPU logging hooks are active, and missing/invalid attestation or digest mismatch must fail closed at `MODERNIZATION/MASTER_TASKS.md:33-47`.

Assessment:
The new boot call is a useful scaffold, not a complete secure-local GPU enablement proof. With `iommu_gpu_on=TRUE` at boot, future code could confuse "scaffold initialized" with "trusted GPU path releasable" before the explicit stage, attestation, digest, and key-release gates exist.

Required remediation:
- Keep the GPU stage externally visible as `off` or `dev-local guarded` until WS14-09 and WS14-16 through WS14-20 land.
- Require all promotion or throughput reports to distinguish `IOMMU scaffold initialized` from `secure-local GPU release allowed`.

### WARNING-004: holyc-inference release gate passes GPU symbol checks while failing model/parser prerequisites

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- Running `bash automation/inference-secure-gate.sh` in holyc-inference returned `status=fail`, with failures for missing `src/model/trust_manifest.HC:ModelTrustManifestVerifySHA256Checked`, `src/model/eval_gate.HC:ModelEvalPromotionGateChecked`, and `src/gguf/hardening_gate.HC:GGUFParserHardeningGateChecked`.
- The same gate reports GPU checks passing by string presence for `GPU_POLICY_ERR_IOMMU_GUARD`, `BOTGPUBridgeRecordMMIOWrite`, `BOT_GPU_DMA_UNMAP`, `GPUCommandVerifyDescriptorChecked`, and `GPUPolicyAllowDispatchChecked` at `automation/inference-secure-gate.sh:59-69`.

Assessment:
The worker-side GPU checks are necessary but shallow: they prove helper symbols exist, not that TempleOS has accepted the same IOMMU/MMIO policy or that secure-local artifact prerequisites are satisfied. The current gate result correctly fails overall, but its GPU sub-checks can still be overread as release readiness.

Required remediation:
- Keep `inference-secure-gate.sh` output labeled as worker readiness until it consumes TempleOS proof artifacts.
- Add explicit gate fields for TempleOS head, Book-of-Truth proof sequence/hash, IOMMU/MMIO policy digest, and profile/key-release decision.

### WARNING-005: Worker policy booleans and digest still have no TempleOS proof input

Applicable laws:
- Law 5: North Star Discipline
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- holyc-inference `GPUPolicyAllowDispatchChecked(...)` accepts caller-supplied booleans for IOMMU, DMA log, MMIO log, and dispatch log, then allows dispatch when all are true at `src/gpu/policy.HC:34-95`.
- holyc-inference policy digest defaults those same externally evidenced guard bits to `1` and mixes them into digest bits 0-3 without a TempleOS sequence/hash or policy record input at `src/runtime/policy_digest.HC:27-33` and `src/runtime/policy_digest.HC:135-168`.
- TempleOS states that the high-throughput inference runtime is untrusted worker-plane code and TempleOS remains the trust/control plane at `MODERNIZATION/MASTER_TASKS.md:41-47`.

Assessment:
The newer TempleOS IOMMU/MMIO scaffold narrows a prior implementation gap, but it does not close the source-of-truth gap. The worker still controls the booleans and digest state that claim the GPU security prerequisites are active.

Required remediation:
- Replace raw worker booleans with a TempleOS-generated proof tuple: `{profile_id, gpu_stage, iommu_domain_digest, mmio_allowlist_digest, dma_hook_seq/hash, mmio_hook_seq/hash, dispatch_hook_seq/hash, policy_seq/hash}`.
- Default externally evidenced worker policy bits to `0` until that tuple verifies.

## Non-Findings

- No HolyC purity violation was found in the inspected TempleOS IOMMU/MMIO or holyc-inference GPU policy surfaces.
- No air-gap violation was found; no QEMU/VM command was run.
- TempleOS MMIO deny-default handling is a positive step: unknown writes are rejected and Book-of-Truth records are emitted in the current scaffold.
- holyc-inference secure-local release gate correctly fails overall at the inspected head because model/hash, eval, and parser hardening prerequisites are missing.

## Read-Only Verification Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
git rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/IOMMU.HC | sed -n '1,330p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KMain.HC | sed -n '136,154p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/Kernel.PRJ | sed -n '56,66p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '1,82p;82480,82550p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '31,55p;260,280p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/policy.HC | sed -n '1,170p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/policy_digest.HC | sed -n '1,210p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/book_of_truth_bridge.HC | sed -n '1,230p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/mmio_allowlist.HC | sed -n '1,230p'
bash /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/iommu-mmio-smoke.sh
bash automation/inference-secure-gate.sh
```
