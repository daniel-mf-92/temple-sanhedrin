# Trinity Policy Gate Coverage Drift Audit

- Audit angle: cross-repo invariant checks
- Timestamp: 2026-05-02T00:54:06+02:00
- Repos inspected: `TempleOS`, `holyc-inference`, `temple-sanhedrin`
- TempleOS HEAD: `9f3abbf263982bf9344f8973a52f845f1f48d109`
- holyc-inference HEAD: `2799283c9554bea44c132137c590f02034c8f726`
- Sanhedrin audit branch: `codex/sanhedrin-gpt55-audit`
- Scope note: read-only source/doc inspection only; no TempleOS guest, QEMU, VM, network, or builder-repo write operation was executed.

## Invariant Under Audit

The Trinity policy gate is supposed to keep TempleOS, holyc-inference, and Sanhedrin aligned on the secure-local profile, dev-local guardrails, model quarantine/hash verification, GPU IOMMU + Book-of-Truth hooks, and attestation/policy-digest parity.

Relevant law anchors:
- `LAWS.md` Law 2 requires the TempleOS guest to remain air-gapped.
- `LAWS.md` Law 3 requires Book-of-Truth paths to remain immutable and non-disableable.
- `LAWS.md` Law 8 requires synchronous, hardware-proximate Book-of-Truth logging.
- `LAWS.md` Law 11 forbids remote viewing/export of Book-of-Truth contents.
- `LAWS.md` later Law 5 requires north-star discipline rather than policy-only churn.

## Evidence

TempleOS:
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:34-47` defines `secure-local` as default, `dev-local` as explicit opt-in, mandatory quarantine/hash verification, GPU disabled unless IOMMU and Book-of-Truth hooks are active, and fail-closed attestation/policy-digest handling.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:50-55` says policy invariants must stay synchronized across all three loops and treats policy drift as a release blocker.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:260-278` marks model quarantine/profile tasks complete while leaving GPU stage, DMA lease, reset/scrub, dispatch transcript, fail-closed boot gate, attestation verifier, policy-digest handshake, and key-release gate tasks open.
- `TempleOS/Kernel/BookOfTruth.HC:112-113` defines `BOT_PROFILE_SECURE_LOCAL` as `1` and `BOT_PROFILE_DEV_LOCAL` as `2`.
- `TempleOS/Kernel/BookOfTruth.HC:736` initializes `bot_profile_mode` to `BOT_PROFILE_SECURE_LOCAL`.
- `TempleOS/Kernel/IOMMU.HC:96-308` provides GPU IOMMU/MMIO allow/deny functions and emits Book-of-Truth DMA records on map/allow/MMIO paths.

holyc-inference:
- `holyc-inference/MASTER_TASKS.md:20-27` states that every model must pass quarantine/hash-manifest verification, GPU acceleration is forbidden unless IOMMU and Book-of-Truth GPU telemetry are active, and trust decisions remain in the TempleOS control plane via attestation + policy-digest handshake.
- `holyc-inference/MASTER_TASKS.md:112-142` lists GPU partition tasks, including mandatory IOMMU, Book-of-Truth hooks, fail-closed runtime gate, attestation record, and secure profile policy gate.
- `holyc-inference/MASTER_TASKS.md:171-183` lists secure-local deployment profile tasks, including policy digest, Trinity drift gate, attestation evidence, and key-release handshake.
- `holyc-inference/src/model/inference.HC:27-30` defines inference-side profile/status constants: secure `1`, dev `2`, blocked `0`, emitted `1`.
- `holyc-inference/src/model/inference.HC:3371-3515` implements a per-token Book-of-Truth emission gate that emits only when profile is secure and policy digest matches.
- `holyc-inference/automation/check-trinity-policy-sync.sh:10-12` defaults to `LOOP_PROMPT.md` for inference, `TempleOS/MODERNIZATION/MASTER_TASKS.md` for TempleOS, and `temple-sanhedrin/LOOP_PROMPT.md` for Sanhedrin.
- Running `bash automation/check-trinity-policy-sync.sh` in `holyc-inference` returned `rc=0` with 21 passing checks and 0 failures.
- `holyc-inference/automation/inference-secure-gate.sh:57-69` checks for selected enforcement symbols in inference files, but it does not inspect TempleOS source or Sanhedrin rules.

Sanhedrin:
- `temple-sanhedrin/LOOP_PROMPT.md:58-70` says Trinity policy parity should inspect `TempleOS/MODERNIZATION/MASTER_TASKS.md`, `holyc-inference/MASTER_TASKS.md`, and `temple-sanhedrin/LOOP_PROMPT.md`.
- `temple-sanhedrin/LOOP_PROMPT.md:73-83` requires split-plane trust checks and flags missing attestation/policy-digest gates as critical.
- `temple-sanhedrin/LOOP_PROMPT.md:105-107` treats secure-local drift, Trinity policy parity mismatches, and missing attestation/policy-digest gates as critical.

## Findings

### 1. WARNING: The inference Trinity gate checks the wrong inference source of truth

`holyc-inference/automation/check-trinity-policy-sync.sh` uses `holyc-inference/LOOP_PROMPT.md` as the inference policy document, while Sanhedrin's own parity procedure names `holyc-inference/MASTER_TASKS.md`. This means the gate can pass even if the inference roadmap, queue state, or secure-local task text in `MASTER_TASKS.md` drifts away from TempleOS and Sanhedrin.

Impact:
- A policy edit in `MASTER_TASKS.md` can bypass the automated Trinity gate if `LOOP_PROMPT.md` still contains the right keywords.
- The gate does not validate whether the open/complete secure-local tasks match TempleOS WS14/WS13 status.

Recommendation:
- Make `check-trinity-policy-sync.sh` inspect both `holyc-inference/MASTER_TASKS.md` and `holyc-inference/LOOP_PROMPT.md`, or switch the default inference doc to `MASTER_TASKS.md` and add separate prompt-policy checks.

### 2. WARNING: Sanhedrin checks pass by matching negative audit-condition prose

The Sanhedrin-side checks in `check-trinity-policy-sync.sh` pass because `temple-sanhedrin/LOOP_PROMPT.md` contains phrases like "default profile is not `secure-local`" and "trusted model load path can bypass quarantine/hash verification" as violation examples. Those are useful instructions, but they are negative audit-condition strings, not normative policy declarations.

Impact:
- A wording-only rewrite of Sanhedrin's audit conditions can fail the gate even when policy remains unchanged.
- A document could satisfy the regex by mentioning a bad condition rather than stating the positive invariant.

Recommendation:
- Add positive Sanhedrin policy anchors, for example `secure-local default invariant`, `quarantine/hash required invariant`, and `attestation/policy-digest required invariant`, then match those anchors instead of violation examples.

### 3. WARNING: The passing Trinity gate does not bind policy text to executable enforcement across repos

The Trinity gate returned `rc=0` with 21 passes, but most checks are regex scans over policy documents. The separate inference secure-local release gate checks inference symbols only; it does not verify TempleOS Book-of-Truth profile state, TempleOS model promotion gates, TempleOS IOMMU/MMIO enforcement, or Sanhedrin law coverage.

Impact:
- Cross-repo policy parity can look green while the executable control-plane/runtime contract remains unproven.
- A secure-local release could rely on inference-local symbol presence without proving TempleOS is still the sovereign control plane.

Recommendation:
- Add a cross-repo executable evidence gate that checks TempleOS symbols such as `BOT_PROFILE_SECURE_LOCAL`, `BookTruthPolicyCheck`, `BookTruthModelPromote`, and `IOMMUGPUMMIOWrite` alongside inference symbols such as `BotTokenEmitChecked` and `GPUPolicyAllowDispatchChecked`.

### 4. WARNING: Profile numeric IDs currently match by convention, not by a shared ABI contract

TempleOS defines secure/dev profiles as `1/2` in `Kernel/BookOfTruth.HC`; holyc-inference independently defines secure/dev profiles as `1/2` in `src/model/inference.HC`. That is currently aligned, but the repos do not expose a shared ABI/version record or parity test for these constants.

Impact:
- A future renumbering in one repo would silently invert or reject profile meanings in the other.
- Token or GPU event evidence could be interpreted under the wrong profile without an explicit schema/version mismatch.

Recommendation:
- Define a shared profile ABI table in both repos, including profile IDs, status IDs, schema version, and expected policy digest field width. Add a Sanhedrin parity check for exact numeric equality.

### 5. WARNING: Per-token inference evidence is not yet bound to TempleOS Book-of-Truth sequence/model gates

Inference token events include `{session_id, step_index, token_id, logit_q16, policy_digest_q64, profile_mode}` and emit only when secure-local and policy digest match. TempleOS model and profile gates track profile events, model imports/verifications/promotions, and gate masks. There is no shared event tuple requiring a TempleOS Book-of-Truth sequence number, model ID/hash, promotion gate mask, or key-release authorization to accompany each token event.

Impact:
- A token event can prove inference-local policy-digest parity without proving which TempleOS model promotion or Book-of-Truth sequence authorized it.
- Later secure-local replay may have to infer trust binding across separate streams rather than validate one canonical tuple.

Recommendation:
- Require token evidence to include or reference `bot_seq`, `model_id`, trusted model hash, promotion gate mask, and key-release/attestation status. Treat bare token evidence as dev-local until that binding exists.

## Summary

Findings: 5 total.

- Critical: 0
- Warning: 5

No evidence in this audit showed guest networking enablement or a direct secure-local bypass. The main risk is coverage drift: the policy sync gate is green, but it is mostly text-presence based and does not yet verify the executable cross-repo trust contract.
