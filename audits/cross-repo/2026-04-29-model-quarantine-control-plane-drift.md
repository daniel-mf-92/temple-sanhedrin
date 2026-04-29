# Cross-Repo Model Quarantine Control-Plane Drift Audit

Timestamp: 2026-04-29T07:43:20+02:00

Scope: TempleOS `75727979e5cb` and holyc-inference `485af0ea61d2`, read-only. This audit checks whether TempleOS's new Book-of-Truth model quarantine ledger matches holyc-inference's existing model quarantine, trust-manifest, quant-profile, and policy-digest assumptions.

Laws reviewed: Law 1 HolyC purity, Law 2 air-gap sanctity, Law 3 Book of Truth immutability, Law 5 north-star discipline, Law 11 local-only Book of Truth access.

## Summary

Both repos now encode the same high-level security posture: models are untrusted until quarantine plus hash/manifest verification succeeds, `secure-local` is the default, and host-side automation remains outside the HolyC core. The drift is at the contract boundary: TempleOS records a compact `model_id` plus split hash/tok-hash ledger, while holyc-inference verifies path, size, manifest entry, full SHA256 hex, profile, and promoted path. There is no shared ABI that binds a verified inference model to the TempleOS control-plane record.

Findings: 5 warnings, 0 critical.

## Evidence

- TempleOS defines the Book-of-Truth model ledger as a fixed 16-entry table with states `EMPTY`, `QUAR`, and `TRUSTED`, and event markers `0xC0` import, `0xC1` verify, and `0xC2` promote in `TempleOS/Kernel/BookOfTruth.HC:101-107` and `:138-154`.
- TempleOS exports `BookTruthModelImport`, `BookTruthModelVerify`, `BookTruthModelPromote`, and `BookTruthModelStatus` through `TempleOS/Kernel/KExts.HC:103-109`.
- TempleOS import stores `model_id`, `sha_hi`, `sha_lo`, `quant`, `tok_hash`, `provenance`, and import/verify/promote TSC fields, then emits compact marker payloads via `BOT_EVENT_NOTE` or `BOT_EVENT_VERIFY_FAIL` in `TempleOS/Kernel/BookOfTruth.HC:12389-12527`.
- holyc-inference quarantine state stores `import_rel_path`, `promoted_rel_path`, `imported_model_nbytes`, `verified_manifest_entry`, `verified_hash_hex`, and `verified_profile_id` in `holyc-inference/src/model/quarantine.HC:31-39`.
- holyc-inference uses richer stages `EMPTY`, `IMPORTED`, `VERIFIED`, and `PROMOTED`, plus explicit errors for malformed manifest, missing entry, size mismatch, hash mismatch, and profile guard in `holyc-inference/src/model/quarantine.HC:11-25`.
- holyc-inference verification requires manifest path/size match, SHA256 recomputation, and profile status before moving to `VERIFIED` in `holyc-inference/src/model/quarantine.HC:366-426`; promotion requires secure-local profile and writes `promoted_rel_path` in `:429-462`.
- holyc-inference quant/profile policy gates separately require quarantine and manifest gates to remain enabled in `holyc-inference/src/runtime/quant_profile.HC:70-91`, and policy digest bitfields include quarantine and hash-manifest flags in `holyc-inference/src/runtime/policy_digest.HC:25-31` and `:128-138`.
- The Trinity policy sync script checks only documentation patterns for quarantine/hash parity, not the concrete Book-of-Truth model ledger ABI, at `holyc-inference/automation/check-trinity-policy-sync.sh:106-110`.

## Findings

### WARNING 1 - Ledger identity does not bind to the inference manifest tuple

TempleOS records `model_id`, `sha_hi`, `sha_lo`, `quant`, `tok_hash`, and `provenance`, but holyc-inference's trusted-load decision is keyed by `candidate_rel_path`, `model_nbytes`, `manifest_entry`, and a full 64-char SHA256 hex string. The current TempleOS ledger has no model path, byte size, manifest entry index, or manifest digest field.

Impact: A TempleOS `trusted` model row cannot be independently joined to the exact holyc-inference manifest row that was verified. This weakens Law 3 auditability because the Book-of-Truth record is not yet enough to reconstruct why a specific model file was promoted.

Recommended invariant: Define one shared model identity tuple, for example `model_id`, `rel_path_hash`, `model_nbytes`, `manifest_entry`, `sha256_hi`, `sha256_lo`, `tokenizer_hash`, and `quant_id`, and require both repos to emit or verify that tuple exactly.

### WARNING 2 - State machines are similar but not isomorphic

TempleOS uses `QUAR -> TRUSTED`; holyc-inference uses `IMPORTED -> VERIFIED -> PROMOTED`. TempleOS represents verification as `verify_tsc != 0` on a quarantined row, while holyc-inference represents verification as an explicit stage with `verified_manifest_entry`, `verified_hash_hex`, and `verified_profile_id`.

Impact: Cross-repo audit tooling cannot tell whether `TRUSTED` means "manifest verified and promoted to a trusted path" or only "Book-of-Truth promote was called after a matching split hash." This is a Law 5 warning because successful-looking progress can mask an incomplete trusted-load contract.

Recommended invariant: Publish a shared state mapping. Minimum acceptable mapping: `QUAR/IMPORTED`, `VERIFIED`, `TRUSTED/PROMOTED`, plus a rule that promotion is impossible unless the exact verified manifest tuple is present.

### WARNING 3 - Failure reason vocabulary is lossy at the Book-of-Truth boundary

holyc-inference distinguishes `ENTRY_NOT_FOUND`, `SIZE_MISMATCH`, `HASH_MISMATCH`, `PROFILE_GUARD`, malformed manifests, and bad state. TempleOS model verification/promote emits only a compact marker plus an ok bit through `BOT_EVENT_NOTE` or `BOT_EVENT_VERIFY_FAIL`.

Impact: A failed trusted-load attempt can lose the actionable reason once reduced to the Book-of-Truth payload. That makes retroactive Law 3 and Law 5 review weaker: the ledger can prove a failure happened, but not whether it was a manifest, size, hash, profile, or state-machine failure.

Recommended invariant: Reserve bits or a second payload field for shared quarantine failure reasons, and align them to holyc-inference's `QUARANTINE_ERR_*` domain.

### WARNING 4 - Control-plane authority is not mechanically enforced across repos

The policy docs say TempleOS is the trust/control plane, but holyc-inference still contains a standalone `ModelQuarantinePromoteChecked` path that makes the promote decision from its own `InferenceProfileStatusChecked` and writes `promoted_rel_path`. No inspected inference path calls `BookTruthModelImport`, `BookTruthModelVerify`, or `BookTruthModelPromote`, and the TempleOS APIs do not consume the inference quarantine state.

Impact: The repos can both pass their local tests while diverging on who authorizes a trusted model. This is not a current source-language or air-gap violation, but it is a cross-repo Law 5 warning because the north-star "TempleOS control plane plus HolyC inference worker" remains unproven.

Recommended invariant: Treat holyc-inference quarantine as a worker-side preflight only; require TempleOS Book-of-Truth promotion to be the final authority, or explicitly rename the inference promotion stage to avoid claiming control-plane authority.

### WARNING 5 - Existing parity gate checks documentation, not executable ABI compatibility

`check-trinity-policy-sync.sh` verifies that docs mention quarantine/hash requirements, but it does not compare constants, stages, failure reasons, event markers, or model identity fields between the two repos. TempleOS's new smoke test similarly greps for functions and strings rather than validating a fixture against holyc-inference's manifest semantics.

Impact: Contract drift can land without tripping the current parity gate. A future change could rename, reorder, or reinterpret model states while the docs still pass.

Recommended invariant: Add a read-only fixture contract test in Sanhedrin or host automation that parses one canonical quarantine fixture and asserts identical state, reason, hash, size, and promotion fields across TempleOS and holyc-inference surfaces.

## Non-Findings

- No networking code or QEMU execution was observed or performed by this audit.
- No TempleOS or holyc-inference source files were modified.
- The inspected implementation code is HolyC in core runtime paths; host-side bash/Python remains in allowed automation/tests paths.
- The latest TempleOS model-quarantine smoke script does not run QEMU and therefore does not create a `-nic none` compliance issue.

## Follow-Up

Open a Trinity policy issue for a shared `ModelTrustRecord` ABI before either repo wires trusted-load execution into a real forward-pass path. The acceptance fixture should include success, hash mismatch, size mismatch, profile guard, and missing-manifest-entry cases, with both repos preserving the same reason code in local status and Book-of-Truth evidence.
