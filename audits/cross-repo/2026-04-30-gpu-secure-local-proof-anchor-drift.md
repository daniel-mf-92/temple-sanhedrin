# Cross-Repo Audit: GPU Secure-Local Proof Anchor Drift

Timestamp: 2026-04-30T02:40:11+02:00

Audit angle: cross-repo invariant check for whether `secure-local` GPU enablement evidence in holyc-inference is anchored to the TempleOS trust/control plane and Book-of-Truth source of truth.

Repos reviewed:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `f247f4ea41c581d7585a4daab75f4d5137f11986` on `codex/modernization-loop`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `485af0ea41a239c8393542d6e0e2fc5944f30f53` on `main`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit`

No TempleOS or holyc-inference source file was modified. No QEMU, VM, WS8 networking, networking, package-download, or data-modifying command was executed.

## Expected Cross-Repo Invariant

GPU dispatch in `secure-local` must be forbidden unless a single proof chain joins:

`TempleOS control-plane policy -> IOMMU active proof -> Book-of-Truth DMA/MMIO/dispatch append proof -> worker attestation/policy digest -> secure-local release gate`

The worker may compute throughput and stage GPU helper evidence, but it cannot self-authorize trust. TempleOS remains the source of truth for policy, quarantine/promotion authority, key release, and Book-of-Truth evidence.

Finding count: 5 findings: 1 critical blocker, 4 warnings.

## Findings

### CRITICAL-001: holyc-inference secure-local release gate currently fails mandatory non-GPU trust checks

Applicable laws:
- Law 5: North Star Discipline
- Cross-repo `secure-local` policy from TempleOS and holyc-inference task ledgers

Evidence:
- Running `bash automation/inference-secure-gate.sh` in holyc-inference exited `1`.
- Gate output failed:
  - `WS16-03`: missing `src/model/trust_manifest.HC:ModelTrustManifestVerifySHA256Checked`
  - `WS16-04`: missing `src/model/eval_gate.HC:ModelEvalPromotionGateChecked`
  - `WS16-05`: missing `src/gguf/hardening_gate.HC:GGUFParserHardeningGateChecked`
- The same gate passed GPU guard presence checks for `WS9-02`, `WS9-08`, `WS9-17`, `WS9-18`, and `WS9-22`.
- holyc-inference policy says no `secure-local` artifact without WS16-03/04/05 and WS9 critical guards (`MASTER_TASKS.md:208-219`), while TempleOS requires trusted-load/key-release attestation plus policy digest match (`MODERNIZATION/MASTER_TASKS.md:43-47`).

Assessment:
The current worker tree has GPU guard helper presence, but its own release gate rejects the trusted runtime because required model trust, eval parity, and parser hardening symbols are not present under the names the gate enforces. No secure-local GPU or inference promotion should treat the current worker gate as pass evidence.

Required remediation:
- Fix the gate or the implementations so WS16-03/04/05 names and files agree.
- Sanhedrin should treat the current `inference-secure-local-release` result as a release blocker, not as a partial GPU pass.

### WARNING-001: TempleOS GPU control-plane tasks remain open while worker GPU helpers are marked complete

Applicable laws:
- Law 5: North Star Discipline
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- TempleOS policy states GPU is disabled unless IOMMU enforcement and Book-of-Truth GPU logging hooks are active (`MODERNIZATION/MASTER_TASKS.md:33-35`).
- TempleOS still lists WS14-09 through WS14-16 open for GPU stage state, IOMMU domain manager, BAR/MMIO allowlist, DMA lease model, reset/scrub, deterministic dispatch transcript, performance guardrails, and fail-closed boot gate (`MODERNIZATION/MASTER_TASKS.md:267-274`).
- holyc-inference marks worker GPU policy/bridge/verifier/allowlist/lease/reset/transcript/perf tasks complete (`MASTER_TASKS.md:1148-1163`).
- A content search of TempleOS core paths found general Book-of-Truth DMA and I/O logging helpers, but no GPU/IOMMU/BAR implementation surface in `Kernel/`, `Adam/`, `Apps/`, `Compiler/`, or `0000Boot/`.

Assessment:
This is expected staging drift, not a source violation. The risk is evidence interpretation: worker-side GPU helpers are ahead of the TempleOS control-plane implementation. The only compliant interpretation is "worker preflight exists, secure-local GPU remains disabled."

Required remediation:
- Require secure-local GPU reports to state TempleOS WS14-09..16 status explicitly.
- Reject any report that treats holyc-inference GPU helper completion alone as sufficient for GPU dispatch.

### WARNING-002: Worker Book-of-Truth GPU bridge is local ring evidence, not a TempleOS append proof

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- holyc-inference `src/gpu/book_of_truth_bridge.HC` defines an in-memory `BOTGPUBridge` ring with caller-supplied storage and `next_seq_id` (`lines 36-54`, `85-101`).
- `BOTGPUBridgeAppendChecked` writes event tuples into that ring and increments a local sequence (`lines 104-163`).
- TempleOS Book-of-Truth DMA/IO helpers exist separately (`Kernel/BookOfTruth.HC:81498` for `BookTruthDMARecord`, `Kernel/BookOfTruth.HC:2450-2475` for I/O port records, and `Kernel/KExts.HC:125-135` exports).
- The worker bridge does not carry a TempleOS Book-of-Truth `seq`, entry hash, sealed-page proof, UART append proof, or TempleOS event type.

Assessment:
The worker bridge is useful structured telemetry, but it is not the Book of Truth. A worker-local `seq_id` can be overwritten by ring rotation and cannot prove immutable TempleOS logging or Law 8 hardware proximity.

Required remediation:
- Define a cross-repo `GPUBookTruthProof` tuple containing TempleOS `bot_seq`, event type, source, payload, entry hash, and serial/append status.
- Make worker GPU bridge rows inadmissible for secure-local release unless joined to a TempleOS append proof.

### WARNING-003: Worker policy digest can self-assert all GPU guard bits as enabled

Applicable laws:
- Law 5: North Star Discipline
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- holyc-inference `src/runtime/policy_digest.HC` initializes `g_policy_iommu_enabled`, `g_policy_bot_dma_log_enabled`, `g_policy_bot_mmio_log_enabled`, and `g_policy_bot_dispatch_log_enabled` to `1` (`lines 27-34`).
- `InferencePolicyRuntimeGuardsSetChecked` accepts caller-supplied guard bits and stores them (`lines 61-84`).
- `InferencePolicyDigestChecked` includes those bits in a digest (`lines 135-170`), but the reviewed code does not bind them to TempleOS IOMMU state or Book-of-Truth append evidence.

Assessment:
The digest proves internal worker policy-bit consistency, not the truth of the hardware/logging state. In the split-plane model, the worker cannot be the authority for IOMMU active or Book-of-Truth hooks active.

Required remediation:
- Treat worker policy bits as claims until TempleOS verifies them.
- Add a TempleOS-side verifier for the same digest, or include a TempleOS-signed policy snapshot and Book-of-Truth proof in the digest input.

### WARNING-004: Attestation compresses GPU evidence into booleans instead of auditable event joins

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- holyc-inference attestation stores `gpu_dispatch_allowed`, `iommu_active`, and one aggregate `bot_gpu_hooks_active` bit (`src/runtime/attestation_manifest.HC:24-30`).
- `InferenceAttestationManifestSetGPUStateChecked` validates only three binary flags (`lines 225-240`).
- `InferenceAttestationManifestEmitChecked` emits those fields as decimal lines (`lines 299-317`).
- TempleOS policy requires measurable security controls ON, including IOMMU and Book-of-Truth (`MODERNIZATION/MASTER_TASKS.md:47`), and GPU-related changes are allowed only with explicit IOMMU enforcement plus Book-of-Truth DMA/MMIO logging hooks (`MODERNIZATION/LOOP_PROMPT.md:64-67`).

Assessment:
The attestation is too coarse for retroactive audit. It cannot distinguish DMA map/update/unmap, MMIO writes, dispatch submit/complete/timeout, IOMMU domain, BAR/register allowlist, or matching TempleOS Book-of-Truth event rows.

Required remediation:
- Expand attestation to include separate DMA/MMIO/dispatch hook proofs and at least first/last TempleOS Book-of-Truth sequence numbers.
- Keep the aggregate boolean only as a summary, not as release-grade evidence.

## Non-Findings

- No air-gap violation was observed or executed during this audit.
- holyc-inference GPU helpers reviewed are HolyC runtime files, which matches the language boundary.
- TempleOS currently preserving GPU implementation tasks as open is safer than prematurely enabling GPU dispatch.

## Suggested Sanhedrin Follow-Up

Add a cross-repo release evidence rule: `secure-local GPU allowed` is false unless all of the following are true in the same report: holyc-inference release gate passes, TempleOS WS14-09..16 implementation status is complete, TempleOS emits Book-of-Truth GPU append proofs, worker policy digest joins to a TempleOS-signed policy snapshot, and attestation includes DMA/MMIO/dispatch event joins.

## Evidence Commands

- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD`
- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '30,60p;255,282p;2218,2230p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/LOOP_PROMPT.md | sed -n '34,70p'`
- `rg -n "GPU|IOMMU|VT-d|AMD-Vi|DMA|MMIO|BAR|PCIe|BookTruthGPU|BookTruthDMA" Kernel Adam Apps Compiler 0000Boot --glob '!*.BIN' --glob '!*.ISO' --glob '!*.img' --glob '!*.o'`
- `rg -n "BookTruthDMARecord|BookTruthIOPort|BOT_SOURCE_IO|DMARecord|MemMapRecord|OutU8Log|InU8Log" Kernel/BookOfTruth.HC Kernel/KExts.HC`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md | sed -n '20,32p;120,150p;208,219p;1144,1165p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/LOOP_PROMPT.md | sed -n '20,36p;64,71p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/policy.HC | sed -n '1,240p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/book_of_truth_bridge.HC | sed -n '1,260p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/attestation_manifest.HC | sed -n '1,380p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/policy_digest.HC | sed -n '1,220p'`
- `bash automation/inference-secure-gate.sh`
