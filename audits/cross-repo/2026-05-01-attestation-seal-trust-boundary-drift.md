# Cross-Repo Audit: Attestation Seal Trust Boundary Drift

Timestamp: 2026-05-01T21:10:00+02:00

Scope: current-head cross-repo invariant check between TempleOS Book-of-Truth seal/tamper surfaces and holyc-inference trusted-model / attestation manifest surfaces.

Repos:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `9f3abbf2`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c`

Laws considered: Law 1 HolyC Purity, Law 3 Book of Truth Immutability, Law 4 Integer Purity, Law 8 Book of Truth Immediacy, Law 9 Crash on Log Failure, Law 11 Local Access Only.

## Summary

No immediate cross-repo source-code violation was found. Both audited implementation surfaces are HolyC-only in core paths, and no networking path was observed in this audit slice.

The drift is contractual: holyc-inference now emits secure-local trust and attestation claims, while TempleOS exposes Book-of-Truth seal/tamper state only as local CLI status strings and internal counters. There is no shared ABI that lets TempleOS verify, bind, or reject inference attestation claims before they are treated as Book-of-Truth-adjacent evidence.

Findings: 5 warnings.

## Findings

### WARNING 1: Attestation manifest claims have no TempleOS verifier contract

Evidence:
- holyc-inference defines `InferenceAttestationManifest` with `policy_digest_hex`, `trusted_model_count`, `quarantine_block_count`, `gpu_dispatch_allowed`, `iommu_active`, and `bot_gpu_hooks_active` fields in `src/runtime/attestation_manifest.HC:17`.
- holyc-inference emits these fields as text key/value lines in `InferenceAttestationManifestEmitChecked` at `src/runtime/attestation_manifest.HC:243`.
- TempleOS current-head search for `attestation_manifest`, `policy_digest`, `trusted_models`, `quarantine_blocks`, and `bot_gpu_hooks_active` in `Kernel/`, `Adam/`, `Apps/`, and `automation/` returns no matching verifier or importer.

Risk:
- A downstream report can present inference attestation lines that sound Book-of-Truth-authoritative, but TempleOS has no canonical parser, digest binding, event type, or rejection rule for those fields.

Relevant laws:
- Law 3 and Law 8, because Book-of-Truth-adjacent claims must not become unverifiable post-hoc text.
- Law 11, because any future export/import path must stay local-only.

Recommendation:
- Define a fixed HolyC attestation event tuple accepted by TempleOS, including field order, widths, digest algorithm, and failure semantics. Treat free-form text attestation as host-side diagnostics only.

### WARNING 2: `bot_gpu_hooks_active` is self-asserted by inference, not proven by TempleOS

Evidence:
- holyc-inference stores `bot_gpu_hooks_active` as a manifest field in `src/runtime/attestation_manifest.HC:28`.
- holyc-inference emits `bot_gpu_hooks_active=<0|1>` in `src/runtime/attestation_manifest.HC:313`.
- TempleOS Book-of-Truth seal/tamper surfaces expose `BookTruthSealStatus`, `BookTruthSealAudit`, `BookTruthTamperPolicySet`, and `BookTruthTamperPolicyStatus`, but there is no TempleOS-side binding from those counters to a GPU hook attestation bit.

Risk:
- The inference repo can report `bot_gpu_hooks_active=1` without a TempleOS-sourced proof that GPU MMIO, IOMMU, dispatch, or tamper hooks were active for the same session.

Relevant laws:
- Law 8 and Law 9, because hardware-proximate Book-of-Truth claims must originate near the protected operation and must fail closed if the log path is unavailable.

Recommendation:
- Replace the boolean with a TempleOS-issued proof tuple, for example `{boot_seq, session_nonce, hook_mask, iommu_state, seal_fault_count, booktruth_digest}`, emitted synchronously from the TempleOS hook path.

### WARNING 3: Trust manifest SHA256 is not bound to a Book-of-Truth seal digest

Evidence:
- holyc-inference trust manifests use `<sha256_hex_64> <size_bytes_decimal> <relative_model_path>` in `src/model/trust_manifest.HC:4`.
- The parser validates 64 hex characters and normalizes the hash in `src/model/trust_manifest.HC:285`.
- TempleOS `BookTruthSealStatus` computes a local `BookTruthHashWord` digest over seal-mode counters, capacity, and map indexes at `Kernel/BookOfTruth.HC:2981`, but that digest does not include model path, model size, SHA256, policy digest, or inference session nonce.

Risk:
- Model trust can be correct inside holyc-inference while the TempleOS Book-of-Truth state cannot independently identify which model artifact was trusted during a session.

Relevant laws:
- Law 3, Law 8, and Law 10. Immutable OS image and immutable log guarantees do not automatically extend to model artifacts unless the artifact identity is sealed or synchronously recorded.

Recommendation:
- Add a cross-repo invariant requiring model SHA256, size, relative path, policy digest, and session nonce to be included in the first Book-of-Truth inference-session record.

### WARNING 4: Tamper fail-stop policy can be represented as mutable runtime state

Evidence:
- TempleOS exposes `BookTruthTamperPolicySet(Bool halt_on_sealed=TRUE)` at `Kernel/BookOfTruth.HC:3117`.
- The implementation directly assigns `bot_tamper_halt_on_sealed=halt_on_sealed` at `Kernel/BookOfTruth.HC:3122`.
- `BookTruthTamperFault` only panics on sealed-page fault when `halt_on_sealed` is true at `Kernel/BookOfTruth.HC:3113`.

Risk:
- This audit does not prove the policy is currently disabled. It does show a mutable API surface that can represent `halt_on_sealed=FALSE`, which is difficult to reconcile with Law 9's "OS dies before the log dies" requirement if used outside a narrowly constrained diagnostic mode.

Relevant laws:
- Law 9 directly.

Recommendation:
- If this knob must remain for diagnostics, document it as test-only and ensure production boot cannot call it with false. The attestation tuple should include the fail-stop policy state and reject secure-local inference when false.

### WARNING 5: Seal status is local text, while inference attestation is structured text with no shared status taxonomy

Evidence:
- TempleOS prints `BookTruthSealStatus: enabled=%d wx_mode=%d sealed=%d seal_faults=%d map_ok=%d map_set=%d cap=%d first=%d last=%d digest=%X` at `Kernel/BookOfTruth.HC:2991`.
- TempleOS prints `BookTruthTamperPolicyStatus: halt_on_sealed=%d tamper_total=%d continue_total=%d seal_faults=%d` at `Kernel/BookOfTruth.HC:3137`.
- holyc-inference emits separate key/value lines such as `policy_digest`, `trusted_models`, `quarantine_blocks`, `gpu_dispatch_allowed`, `iommu_active`, and `bot_gpu_hooks_active` at `src/runtime/attestation_manifest.HC:265` through `src/runtime/attestation_manifest.HC:316`.

Risk:
- Both repos produce parseable status text, but the schemas are unrelated. Historical audits and host automation can join them by convention, but there is no authoritative cross-repo field map defining what "secure-local inference with Book-of-Truth hooks active" means.

Relevant laws:
- Law 8 and Law 11. Loose host-side joins invite stale or non-local interpretation of Book-of-Truth state.

Recommendation:
- Create a short cross-repo ABI document with field names, integer widths, digest order, freshness rules, and local-only handling restrictions. Until then, mark combined reports as "correlated host diagnostics", not Book-of-Truth proof.

## Checks Performed

- Read holyc-inference attestation manifest emitter and trusted model manifest parser.
- Read TempleOS Book-of-Truth seal status, seal audit, tamper fault, and tamper policy surfaces.
- Searched TempleOS for matching attestation/trust-manifest parser fields.
- No QEMU or VM command was executed.
- No TempleOS or holyc-inference source files were modified.

