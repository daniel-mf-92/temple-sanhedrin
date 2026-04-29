# Cross-Repo Attestation + Key-Release Binding Drift Audit

Timestamp: 2026-04-29T21:37:48+02:00

Audit angle: cross-repo invariant check for whether TempleOS trust-control-plane requirements are mechanically bound to holyc-inference attestation, policy digest, and key-release evidence at the current committed heads.

Repos reviewed:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `00d1bdcd92c1af0b5c10b5ccc25cc1503f98937e`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `485af0ea41a239c8393542d6e0e2fc5944f30f53`
- temple-sanhedrin audit worktree: `/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55` at `281f22501406d6f4cc4499a1c1a5292baf332f4d`

No TempleOS or holyc-inference source file was modified. No QEMU, VM, WS8 networking, networking, or package-download command was executed.

## Summary

TempleOS policy says `secure-local` trusted-load and key release require worker attestation evidence plus policy digest match, with TempleOS remaining the trust/control plane and Book-of-Truth source of truth. holyc-inference has local HolyC emitters and gates for those concepts, but the boundary is still a caller-supplied boolean/string contract rather than a shared signed approval record or nonce-bound attestation transcript.

Finding count: 5 warnings, 0 critical.

## Evidence Reviewed

- TempleOS `MODERNIZATION/MASTER_TASKS.md:43-47` assigns policy, quarantine/promotion authority, key-release gate, and Book-of-Truth source-of-truth ownership to TempleOS and requires attestation evidence plus policy digest match for trusted-load/key-release flows.
- TempleOS `MODERNIZATION/MASTER_TASKS.md:276-278` still has WS14-18, WS14-19, and WS14-20 unchecked: worker-plane attestation verifier, policy-digest handshake validation, and key-release gate.
- holyc-inference `MASTER_TASKS.md:218-219` originally leaves WS16-11/WS16-12 unchecked, while later `MASTER_TASKS.md:1164-1165` marks IQ-1271/IQ-1272 complete for attestation emitter and key-release verifier.
- holyc-inference `src/runtime/attestation_manifest.HC:17-30` defines the worker attestation manifest fields, including `session_id`, `policy_digest_hex`, `attestation_nonce`, `iommu_active`, and `bot_gpu_hooks_active`.
- holyc-inference `src/runtime/attestation_manifest.HC:162-208` accepts caller-supplied session/profile/policy digest/nonce values and initializes mutable counts and GPU state fields.
- holyc-inference `src/runtime/attestation_manifest.HC:243-320` emits key-value lines but does not emit a signature, TempleOS approval id, Book-of-Truth sequence, or challenge binding.
- holyc-inference `src/runtime/key_release_gate.HC:29-88` grants key release when three binary inputs are true and `is_secure_default` remains true.
- holyc-inference `src/runtime/policy_digest.HC:61-83` allows local mutation of policy guard globals and `src/runtime/policy_digest.HC:86-172` computes a deterministic digest over those local guard bits.
- holyc-inference `tests/test_runtime_key_release_gate.py:27-52` mirrors the key-release gate as three booleans plus local profile state.
- holyc-inference `tests/test_runtime_attestation_manifest.py:70-82` mirrors the manifest as emitted strings; the test asserts line presence, not control-plane verification.

## Findings

### WARNING-001: Key release accepts caller-supplied proof booleans rather than a TempleOS-bound approval record

TempleOS says it owns key-release authority, and holyc-inference comments say release requires "TempleOS signed approval present." The implemented gate, however, receives `templeos_signed_approval`, `attestation_evidence_valid`, and `policy_digest_parity_valid` as three binary flags. It validates that each is 0 or 1, then sets failure bits and permits release when all are true.

Risk: a worker-side caller can structurally represent "TempleOS approved" without the runtime checking an approval id, signature, Book-of-Truth sequence, policy digest value, or nonce. This is cross-repo drift in the trust boundary, not a Law 1 or Law 2 source violation.

Recommended invariant: replace the three booleans with a shared `KeyReleaseApproval` tuple such as `{templeos_approval_id, bot_seq, session_id, nonce, policy_digest, model_id, expiry_tsc, signature/checksum}` and fail closed unless the tuple binds to the emitted attestation manifest.

### WARNING-002: Attestation nonce is recorded but not challenged or freshness-bound by TempleOS

The attestation manifest stores and emits `nonce`, but TempleOS current source/policy search shows only open WS14 tasks for verifier/handshake/key release, not a current nonce challenge producer or replay cache. The nonce is accepted from the caller during manifest init and can be any non-negative integer.

Risk: historical or synthetic attestations can be replayed as fresh evidence if downstream tooling only checks that a nonce field exists. For secure-local, TempleOS should originate or approve the challenge and record acceptance/rejection in Book of Truth.

Recommended invariant: TempleOS should generate or seal an attestation challenge row, and holyc-inference should include that challenge id and nonce in the manifest and policy digest binding. Sanhedrin should treat nonce-without-challenge as incomplete evidence.

### WARNING-003: Policy digest proves local worker guard bits, not TempleOS authorization of those bits

holyc-inference policy digest covers local guard bits for IOMMU, Book-of-Truth DMA/MMIO/dispatch hooks, quarantine, hash manifest, and profile state. Those bits can be set through `InferencePolicyRuntimeGuardsSetChecked` and then digested. TempleOS policy requires digest parity before trusted dispatch, but the current TempleOS side still has the policy-digest validation task open.

Risk: a digest can be deterministic and internally consistent while still proving only a worker-local tuple. Without a TempleOS-verified expected digest or allowed policy epoch, parity can collapse into "the worker agrees with itself."

Recommended invariant: define a TempleOS policy epoch/digest allowlist and require the worker digest to include that epoch plus the attestation challenge. A policy digest should be invalid for key release unless TempleOS has recorded the expected value.

### WARNING-004: GPU hook state is compressed before crossing the control-plane boundary

The attestation manifest emits a single `bot_gpu_hooks_active` bit, while the policy digest tracks separate DMA, MMIO, and dispatch hook bits. TempleOS policy requires IOMMU plus Book-of-Truth GPU logging hooks before GPU dispatch is trusted.

Risk: a manifest can say `bot_gpu_hooks_active=1` without preserving which hook family was active or how it maps to the three digest bits. This is weak evidence for Law 5/North Star secure-on performance claims and for Law 8/Law 11 review of Book-of-Truth GPU evidence surfaces.

Recommended invariant: the attestation manifest should emit discrete `bot_dma_log`, `bot_mmio_log`, and `bot_dispatch_log` fields, and the key-release tuple should bind the same three bits by value.

### WARNING-005: Completion status is asymmetric between repos

holyc-inference marks the attestation emitter and key-release verifier complete at IQ-1271/IQ-1272, but TempleOS still lists the corresponding verifier, digest handshake, and key-release gate as unchecked WS14-18/19/20 work. That means the worker plane can report completion before the control plane can verify or reject the evidence.

Risk: local worker tests can pass and ledger progress can look complete while the trinity trust contract remains unfinished. The immediate remediation is not to revert the worker helpers; it is to classify them as worker-side scaffolding until the TempleOS verifier and Book-of-Truth approval rows exist.

Recommended invariant: Sanhedrin should not count WS16-11/12-style worker completion as secure-local release readiness unless TempleOS WS14-18/19/20 or their successors are implemented and a cross-repo fixture proves the shared tuple.

## Non-Findings

- No air-gap violation was found in this audit. No QEMU/VM command was executed, and the reviewed source changes do not add networking.
- The inspected holyc-inference runtime files are HolyC and integer-only for the audited paths.
- The current worker gates are fail-closed for malformed binary flags; the drift is evidence provenance and cross-repo binding, not local boolean validation.

## Suggested Sanhedrin Follow-Up

Add a cross-repo fixture named around `AttestationKeyReleaseRecord` with one success case and at least four rejection cases: stale nonce, policy digest mismatch, missing TempleOS approval id, and GPU hook bit mismatch. The fixture should be generated from static text only and must not launch QEMU.

## Validation Commands

- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD`
- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '26,55p;250,282p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/attestation_manifest.HC | sed -n '1,340p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/key_release_gate.HC | sed -n '1,280p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/policy_digest.HC | sed -n '1,260p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_runtime_key_release_gate.py | sed -n '1,260p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_runtime_attestation_manifest.py | sed -n '1,280p'`
