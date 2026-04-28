# Cross-Repo Audit: Attestation and Key-Release Trust-Plane Drift

Timestamp: 2026-04-28T11:09:06+02:00

Scope: historical cross-repo invariant check across read-only TempleOS and holyc-inference working trees. No trinity source files were modified.

TempleOS commit under audit: `e868ba65878b282ff5b2d2464b6bd95cb56e6c76 feat(modernization): codex iteration 20260428-084920`

holyc-inference commit under audit: `ce09228422dae06e86feb84925d51df88d67821b feat(inference): codex iteration 20260428-085506`

## Contract Under Audit

TempleOS declares `secure-local` as the trust/control plane. The inference runtime is an untrusted worker plane, and trusted-load/key-release flows require worker attestation plus policy digest match, with missing/invalid evidence failing closed.

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:43` assigns policy, quarantine/promotion authority, key-release gate, and Book-of-Truth source of truth to TempleOS.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:45` requires attestation evidence plus policy digest match from the worker plane.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:46` requires fail-closed reject/CPU-only fallback on missing or invalid attestation/digest.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/LOOP_PROMPT.md:54` says TempleOS owns model trust gates and key-release decisions.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/LOOP_PROMPT.md:56` forbids moving attestation validation, policy-digest checks, or key release into throughput-only workers.

## Findings

### WARNING 1: Key-release verification lives in the worker repo before TempleOS has the trust-plane verifier

holyc-inference marks `IQ-1272` complete and implements `InferenceKeyReleaseHandshakeVerifyChecked` in `src/runtime/key_release_gate.HC`. The function decides `out_release_allowed` from TempleOS approval, attestation validity, policy parity, and profile state. TempleOS still has WS14-18, WS14-19, and WS14-20 unchecked for the attestation verifier, policy-digest handshake validation, and key-release gate.

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:1165`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/key_release_gate.HC:29`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/key_release_gate.HC:82`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:276`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:278`

Risk: the worker has a key-release decision surface before the TempleOS sovereign verifier/key-release implementation exists. It is fail-closed in isolation, so this is not a direct bypass, but it inverts the intended ownership boundary and can normalize worker-plane release decisions.

### WARNING 2: Attestation evidence is an emitter-only KV bundle, not a TempleOS-verifiable proof

holyc-inference `InferenceAttestationManifest` emits line-oriented fields such as `session_id`, `policy_digest`, `nonce`, trust counts, and GPU/IOMMU flags. The emitter does not include a signature, TempleOS challenge binding, Book-of-Truth sequence binding, or verifier-facing schema version. TempleOS still has the worker-plane attestation verifier unchecked.

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/attestation_manifest.HC:17`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/attestation_manifest.HC:243`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/attestation_manifest.HC:253`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/attestation_manifest.HC:265`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/attestation_manifest.HC:278`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:276`

Risk: a worker can emit plausible attestation text without a committed TempleOS validation contract. That weakens the "evidence + digest match" invariant because the evidence shape is defined by the untrusted plane first.

### WARNING 3: Secure-on performance matrix can assert attestation and digest hardening without evidence linkage

`automation/perf-matrix.sh` writes synthetic fallback hardening strings containing `attestation=on`, `policy_digest=on`, and `audit_hooks=on` whenever the host benchmark binary is absent. The real-run path only checks for those substrings in binary output; it does not require an attestation manifest, policy digest value, nonce, or TempleOS verifier result.

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/perf-matrix.sh:48`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/perf-matrix.sh:58`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/perf-matrix.sh:75`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:47`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/LOOP_PROMPT.md:57`

Risk: secure-on throughput evidence can pass by string convention rather than by a verifier-backed attestation/digest artifact. This is Law 5/North Star drift because performance wins only count with security controls enabled and evidenced.

### WARNING 4: Trinity sync gate checks documentation regexes, not the implemented attestation/key-release contract

`automation/check-trinity-policy-sync.sh` checks for policy phrases across the three docs, including attestation/policy-digest language, but it does not check that TempleOS has a verifier implementation or that holyc-inference emits a verifier-compatible signed/challenged artifact.

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/check-trinity-policy-sync.sh:116`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/check-trinity-policy-sync.sh:117`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/check-trinity-policy-sync.sh:118`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:54`

Risk: the docs can appear synchronized while implementation remains split: worker-side emitter/verifier stubs exist, but TempleOS-side trust-plane verification is still pending.

### INFO 5: The audited runtime code remains HolyC-only and air-gap neutral

The inspected holyc-inference runtime files are HolyC, and this audit did not observe added networking or QEMU execution. No Law 1, Law 2, or Law 4 critical violation is raised from this specific attestation/key-release drift check.

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/attestation_manifest.HC:1`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/key_release_gate.HC:1`

## LAWS.md Assessment

- Law 1 HolyC Purity: no violation observed in the audited runtime files.
- Law 2 Air-Gap Sanctity: no networking path observed; no QEMU/VM command was run.
- Law 4 Integer Purity: no floating-point tensor runtime issue observed in this audit.
- Law 5 North Star / No Busywork: warning-level drift. Attestation/key-release evidence is progressing, but the implementation order and evidence gates are misaligned with the TempleOS sovereign trust-plane contract.
- Laws 8-11 Book of Truth / immutable image / local access: no direct violation observed, but the attestation format should eventually bind to Book-of-Truth-local evidence before being considered trusted.

## Recommended Follow-Up

- Add a TempleOS-owned verifier contract before treating worker `InferenceKeyReleaseStatus` as trusted release evidence.
- Version the attestation manifest and bind it to a TempleOS challenge, expected policy digest, and local Book-of-Truth sequence/hash evidence.
- Change secure-on performance gates to require concrete attestation and digest artifacts, not only `hardening=` substrings.
- Extend Trinity sync checks beyond doc regexes to assert TempleOS verifier presence and worker artifact compatibility.

Findings count: 4 warnings, 1 info, 0 critical.
