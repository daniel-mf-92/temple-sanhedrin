# Cross-Repo Audit: Model Trust Attestation Tuple Drift

- **Timestamp:** 2026-05-01T01:00:57Z
- **Audit angle:** Cross-repo invariant checks
- **Repos read:** TempleOS `738206d0`, holyc-inference `2799283c`
- **Sanhedrin branch:** `codex/sanhedrin-gpt55-audit`
- **Scope note:** Read-only inspection of TempleOS and holyc-inference. No QEMU or VM commands were executed.

## Summary

TempleOS and holyc-inference both implement model trust gates, but they do not yet share one canonical attestation tuple. holyc-inference verifies a full manifest entry of `<sha256_hex_64> <size_bytes_decimal> <relative_model_path>`, while TempleOS records a compact Book-of-Truth model tuple of `model_id`, two 64-bit SHA lanes, tokenizer hash, quant, provenance, parse/determinism/build flags, and several 64-bit hashes. The current surfaces can each pass their own local checks while losing fields needed to prove that the promoted TempleOS model is exactly the model verified by holyc-inference.

## Findings

### WARNING 1: Model identity width is truncated at the TempleOS boundary

- **Law impact:** Law 3 / Book of Truth integrity; cross-repo invariant drift.
- **Evidence:** holyc-inference `src/model/trust_manifest.HC` defines the trusted manifest hash as exactly 64 hex characters / 32 SHA256 bytes and compares every hex character during verification (`TRUST_MANIFEST_SHA256_HEX_CHARS 64`, `TRUST_MANIFEST_SHA256_BYTES 32`, `TrustManifestVerifyEntrySHA256Checked`). TempleOS `Kernel/BookOfTruth.HC` stores only `sha_hi` and `sha_lo` on `CBookTruthModelEntry` and verifies only those two 64-bit lanes in `BookTruthModelVerify`.
- **Risk:** The Book of Truth records a 128-bit projection of a 256-bit trust manifest digest. That may be intentional as a compact fingerprint, but the repos do not document the projection rule, byte order, or collision domain. A later bridge cannot prove that TempleOS `sha_hi/sha_lo` were derived from the exact 64-hex SHA256 accepted by holyc-inference.
- **Suggested invariant:** Define a canonical `sha256_hi128` projection with byte order, or add four 64-bit lanes to the TempleOS model tuple.

### WARNING 2: Manifest path and size are verified by inference but absent from TempleOS attestation

- **Law impact:** Law 3 / Book of Truth integrity; Law 11 derived-artifact locality boundary.
- **Evidence:** holyc-inference manifest entries bind `sha256_hex`, `size_bytes`, and `rel_path`, reject traversal/absolute paths, and check size before hash comparison. TempleOS model import/provenance stores `model_id`, `sha_hi`, `sha_lo`, `quant`, `tok_hash`, and `provenance`, but no relative model path and no byte size.
- **Risk:** Two artifacts with the same compact identity projection but different canonical paths or sizes cannot be distinguished in TempleOS audit output. That weakens historical reconstruction of which quarantined file was promoted.
- **Suggested invariant:** Add `model_size_bytes` and a path digest/path-id field to the Book-of-Truth model contract, or require the bridge to log them as adjacent immutable events.

### WARNING 3: Runtime attestation manifest does not emit the TempleOS promotion tuple

- **Law impact:** Cross-repo invariant drift; Law 5 north-star evidence quality.
- **Evidence:** holyc-inference `src/runtime/attestation_manifest.HC` emits `session_id`, `profile_name`, `policy_digest`, `profile_id`, `nonce`, `trusted_models`, `quarantine_blocks`, `gpu_dispatch_allowed`, `iommu_active`, and `bot_gpu_hooks_active`. TempleOS promotion/build state requires `model_id`, `sha_hi`, `sha_lo`, `tok_hash`, `quant`, `provenance`, `det_*`, `build_hash`, `build_bless_hash`, and `build_kernel_hash`.
- **Risk:** A successful inference attestation cannot be mechanically joined to the exact TempleOS `BookTruthModelPromote` gate state. The system can prove that some trusted models existed, not which model tuple satisfied the secure-local gates.
- **Suggested invariant:** Emit one deterministic `model_trust_tuple=` line per trusted model using the TempleOS field set, plus the full SHA256/path/size tuple from the trust manifest.

### WARNING 4: TempleOS promotion can bypass parse evidence when `parse_fmt == 0`

- **Law impact:** Cross-repo GGUF parser contract drift; Law 5 evidence quality.
- **Evidence:** `BookTruthModelImport` initializes `parse_fmt=0` and `parse_ok=1`. `BookTruthModelPromote` only gates parse failure when `parse_fmt != 0 && !parse_ok`; no parse run is required for secure-local promotion. holyc-inference has an explicit GGUF parser/manifest trust surface and tests around GGUF parsing and manifest SHA256 verification.
- **Risk:** A model can satisfy TempleOS secure-local promotion through verify/determinism/build gates without an explicit parse event. That leaves no Book-of-Truth evidence that the GGUF parser contract was exercised for the promoted artifact.
- **Suggested invariant:** Secure-local promotion should require a successful parse gate for GGUF/Safe formats, or explicitly document why parse validation belongs only to holyc-inference and how its proof is imported.

### WARNING 5: TempleOS model gate smoke guard is stale

- **Law impact:** Law 5 validation evidence quality.
- **Evidence:** `bookoftruth-model-gate-smoke.sh` failed because it still expects `BookTruthModelGateStatus: rows=%d profile_evt=%d secure=%d dev=%d promote_evt=%d promote_ok=%d promote_gate=%d import_bad=%d verify_fail=%d last_model=%d last_gate=%X last_seq=%d`. Current `BookTruthModelGateStatus` also prints determinism/build event counters before the last-model fields.
- **Risk:** The guard now reports a failure against current source even though the implementation contains the expanded status line. Builders may start ignoring this smoke test, and Sanhedrin cannot trust it as a signal for model gate coverage.
- **Suggested invariant:** Update the smoke expectation to the current status signature and add a negative check proving determinism/build fields are present.

## Validation

- `REPO_DIR=/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS bash /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/bookoftruth-model-gate-smoke.sh` -> failed as expected for stale status signature.
- `REPO_DIR=/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS bash /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/bookoftruth-model-schema-smoke.sh` -> pass.
- `REPO_DIR=/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS bash /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/model-build-attest-smoke.sh` -> pass.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m pytest -q tests/test_model_trust_manifest_sha256.py tests/test_runtime_attestation_manifest.py -p no:cacheprovider` -> not run; `pytest` is not installed for the active Python.
- Custom no-bytecode Python harness executed all functions named `test_*` in `tests/test_model_trust_manifest_sha256.py` and `tests/test_runtime_attestation_manifest.py` -> 12 tests ok.

## Finding Count

- **Critical:** 0
- **Warning:** 5
- **Info:** 0
