# Cross-Repo Audit: Key-Release Control-Plane Drift

Timestamp: 2026-04-30T04:59:35+02:00

Audit angle: cross-repo invariant check for whether TempleOS's stated `secure-local` trust/control-plane ownership matches the current holyc-inference key-release, attestation, policy-digest, and release-gate surfaces.

Repos reviewed:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `6417dc9f441cb426392503a1406f0bef9a74e17d`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554bea44c132137c590f02034c8f726`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at `a6b63b5ff2df4f644a40ced8c693a474df1888f4`

No TempleOS or holyc-inference source file was modified. No QEMU, VM, WS8 networking, networking, or package-download command was executed.

## Expected Cross-Repo Invariant

TempleOS policy says `secure-local` keeps TempleOS as the trust/control plane for policy, quarantine/promotion authority, key-release gates, and Book-of-Truth authority. holyc-inference may optimize the worker plane, but must not become the source of trust decisions.

Therefore a usable key-release path needs an executable join:

- TempleOS emits or verifies the approval decision.
- holyc-inference contributes worker evidence: attestation, policy digest, quarantine/hash/model gates.
- Sanhedrin can audit the joined proof, including Book-of-Truth locality and fail-closed behavior.

Finding count: 5 findings: 1 critical, 4 warnings.

## Findings

### CRITICAL-001: Secure-local release gate currently fails on required model trust controls

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 5: North Star Discipline
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- `bash automation/inference-secure-gate.sh` in holyc-inference exits non-zero.
- The gate reports `failed=3`:
  - `WS16-03` missing `src/model/trust_manifest.HC:ModelTrustManifestVerifySHA256Checked`
  - `WS16-04` missing `src/model/eval_gate.HC:ModelEvalPromotionGateChecked`
  - `WS16-05` missing `src/gguf/hardening_gate.HC:GGUFParserHardeningGateChecked`
- The script itself requires these three controls at `automation/inference-secure-gate.sh:59-61`.
- Current source has SHA256 helpers under different symbols (`TrustManifestSHA256HexComputeChecked`, `TrustManifestVerifyEntrySHA256Checked`) and no `src/model/eval_gate.HC` file was found by the gate.

Assessment:
This is an active release-blocking drift. The high-level Trinity policy sync gate passes, but the executable secure-local release gate fails because required model trust controls are absent or named differently from the gate contract. A `secure-local` artifact cannot be accepted as release-ready under the current executable gate.

Required remediation:
- Either implement the missing exact gate symbols/files or update the release gate and tests to the actual authoritative symbol names.
- Keep the gate fail-closed until WS16-03/04/05 are all executable and wired into the secure-local release path.

### WARNING-001: Trinity policy sync passes while the executable secure-local release gate fails

Applicable laws:
- Law 5: North Star Discipline
- Law 7: Blocker Escalation

Evidence:
- `bash automation/check-trinity-policy-sync.sh` in holyc-inference reports `status=pass`, `drift=false`, `passed=21`, `failed=0`.
- The same current holyc-inference head reports `status=fail`, `passed=6`, `failed=3` from `automation/inference-secure-gate.sh`.
- The policy sync gate checks doc patterns for attestation and digest parity at `automation/check-trinity-policy-sync.sh:116-118`, not whether the executable release gate is green.

Assessment:
The doc-level parity gate is useful, but it can produce a green "no drift" signal while the release path is red. Sanhedrin and builder loops can therefore misread policy synchronization as release readiness.

Required remediation:
- Split naming explicitly: "policy text sync" versus "secure-local executable release gate".
- Make any release-readiness report include both results, with executable release failure taking precedence.

### WARNING-002: TempleOS owns key-release authority in policy, but current audited implementation surface is inference-local

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity
- Law 11: Book of Truth Local Access Only

Evidence:
- TempleOS `MODERNIZATION/MASTER_TASKS.md:43` states TempleOS in `secure-local` remains the trust/control plane for policy, quarantine/promotion authority, key-release gate, and Book-of-Truth source of truth.
- TempleOS `MODERNIZATION/LOOP_PROMPT.md:54-56` says TempleOS owns trust-plane decisions and trust decisions must not move into throughput-only workers.
- holyc-inference `src/runtime/key_release_gate.HC:29-34` implements `InferenceKeyReleaseHandshakeVerifyChecked(...)`.
- holyc-inference `src/runtime/key_release_gate.HC:91-95` exposes `InferenceKeyReleaseStatus(...)` as the CLI helper.
- A read-only TempleOS scan for `signed approval`, `TempleOS-signed`, `key-release`, `PolicyDigest`, and `Attestation` found policy/task text, but no executable TempleOS approval producer or verifier.

Assessment:
The worker-side function is fail-closed and integer-only, but the authority boundary is inverted at the implementation surface: the function that decides release lives in holyc-inference and takes `templeos_signed_approval` as a caller-supplied boolean. Without an executable TempleOS approval artifact and a Book-of-Truth-bound sequence/hash proof, Sanhedrin cannot verify that the boolean came from the TempleOS trust plane.

Required remediation:
- Define a TempleOS-owned approval record format containing at least model id, policy digest, attestation digest, Book-of-Truth sequence, entry hash, and decision.
- Have holyc-inference verify that record rather than accepting an unbound boolean.

### WARNING-003: Worker-side policy digest state is mutable without a TempleOS proof join

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity
- Law 9: Resource Supremacy / Crash on Log Failure

Evidence:
- holyc-inference `src/runtime/policy_digest.HC:61-83` exposes `InferencePolicyRuntimeGuardsSetChecked(...)`, which mutates the IOMMU, Book-of-Truth hook, quarantine, and hash-manifest guard globals after binary validation.
- holyc-inference `src/runtime/key_release_gate.HC:29-31` accepts `policy_digest_parity_valid` as a boolean input.
- TempleOS `MODERNIZATION/MASTER_TASKS.md:45-46` requires trusted-load/key-release flows to fail closed on invalid attestation or digest mismatch.

Assessment:
The policy digest machinery is deterministic, but the final key-release gate accepts parity as a detached boolean. A worker-local policy tuple can be updated and then summarized without an audited TempleOS-side comparison record. That is weaker than the policy promise that TempleOS remains the trust plane and Book-of-Truth source of truth.

Required remediation:
- Bind `policy_digest_parity_valid` to a TempleOS-generated comparison record, not a caller-provided scalar.
- Include the TempleOS expected digest, worker digest, comparison result, and Book-of-Truth append evidence in the release proof.

### WARNING-004: Attestation evidence is emitted in holyc-inference, but TempleOS verifier work remains queued

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- holyc-inference has `src/runtime/attestation_manifest.HC`, including a structured `InferenceAttestationManifest` with profile, policy digest, trusted/quarantine counts, GPU/IOMMU, and Book-of-Truth hook fields.
- TempleOS `MODERNIZATION/MASTER_TASKS.md:276-278` still lists unchecked work for attestation evidence verifier, policy-digest handshake validation, and key-release gate.
- TempleOS `MODERNIZATION/MASTER_TASKS.md:45` already requires attestation evidence plus policy digest match for trusted-load/key-release flows.

Assessment:
The worker can emit evidence, but TempleOS has not yet completed the verifier side that would make the evidence authoritative. Until then, attestation remains a worker assertion rather than a TempleOS-controlled trust input.

Required remediation:
- Prioritize TempleOS WS14-18/19/20 as blockers before any secure-local key-release claim.
- Require Sanhedrin reports to distinguish "worker emitted evidence" from "TempleOS verified and Book-of-Truth recorded evidence".

## Non-Findings

- The reviewed holyc-inference key-release and policy-digest implementation is HolyC and integer-only.
- The policy text across TempleOS, holyc-inference, and Sanhedrin is currently synchronized according to `automation/check-trinity-policy-sync.sh`.
- No guest networking, QEMU, VM, WS8 networking, or network-dependent package operation was used for this audit.

## Evidence Commands

- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD`
- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD`
- `bash automation/check-trinity-policy-sync.sh` in holyc-inference
- `bash automation/inference-secure-gate.sh` in holyc-inference
- `rg -n "signed approval|TempleOS-signed|key-release|key release|policy digest|attestation evidence|InferenceKeyRelease|BookTruth.*Approve|Approval|PolicyDigest|Attestation" MODERNIZATION Kernel Adam Apps Compiler 0000Boot -S` in TempleOS
- `rg -n "TempleOS-signed|signed approval|key-release|key release|policy digest parity|attestation_evidence_valid|policy_digest_parity_valid|InferenceKeyRelease" src tests automation LOOP_PROMPT.md MASTER_TASKS.md -S` in holyc-inference
- `rg -n "ModelTrustManifest|TrustManifest.*SHA|ModelEvalPromotionGate|EvalPromotion|GGUFParserHardeningGate|HardeningGate" src/model src/gguf -S` in holyc-inference
