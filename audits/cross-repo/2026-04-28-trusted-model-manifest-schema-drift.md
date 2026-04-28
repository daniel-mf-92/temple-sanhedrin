# Cross-Repo Audit: Trusted Model Manifest Schema Drift

Timestamp: 2026-04-28T06:05:18+02:00

Scope: historical cross-repo invariant check across read-only TempleOS and holyc-inference working trees. No trinity source files were modified.

TempleOS commit under audit: `5216d28 feat(modernization): codex iteration 20260428-054410`

holyc-inference commit under audit: `b8a4fc8b feat(inference): codex iteration 20260427-222113`

## Contract Under Audit

TempleOS declares `secure-local` as the trust/control plane and requires quarantine, hash verification, attestation/policy-digest parity, and fail-closed trusted dispatch. Its trusted model manifest schema is explicitly wider than hash-only verification: `model_id`, `sha256`, quant type, tokenizer hash, and provenance.

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:43` assigns quarantine/promotion authority and key-release gate ownership to TempleOS.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:45` requires attestation evidence plus policy digest match for trusted-load/key-release flows.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:51` makes quarantine/hash gate parity a Trinity invariant.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:260` requires import -> hash verify -> manifest entry -> trusted promotion.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:261` requires manifest fields `model_id`, `sha256`, quant type, tokenizer hash, and provenance.

## Findings

### WARNING 1: Inference trust manifest accepts a narrower schema than TempleOS commits to

holyc-inference `src/model/trust_manifest.HC` documents and parses only:

`<sha256_hex_64> <size_bytes_decimal> <relative_model_path>`

The committed `TrustManifestEntry` stores `sha256_hex`, `size_bytes`, and `rel_path` only. There is no stored or parsed `model_id`, quant type, tokenizer hash, or provenance field, so a manifest accepted by the inference worker cannot satisfy the TempleOS WS14-03 schema without an additional compatibility layer.

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/trust_manifest.HC:4`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/trust_manifest.HC:31`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/trust_manifest.HC:285`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/trust_manifest.HC:303`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/trust_manifest.HC:319`

Risk: a model can be hash-verified by inference while still lacking the identity/tokenizer/provenance bindings that TempleOS says are required for trusted promotion. That is drift in the secure-local trust contract, not a direct Law 1/2 violation.

### WARNING 2: Quarantine promotion is bound to path/hash/size, not tokenizer or quant identity

`src/model/quarantine.HC` verifies a manifest match for the imported path and size, computes SHA256, records the manifest entry index, hash, and profile id, then advances to verified state. It does not preserve or require tokenizer hash, quant type, provenance, or a stable model id.

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/quarantine.HC:4`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/quarantine.HC:31`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/quarantine.HC:207`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/quarantine.HC:389`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/quarantine.HC:419`

Risk: TempleOS can intend a trusted promotion keyed to model identity and tokenizer compatibility, but the worker-plane implementation only proves bytes/path/size. A tokenizer-side mismatch can invalidate deterministic eval parity while still passing this narrower quarantine verifier.

### WARNING 3: Existing tests normalize the narrower manifest as the expected contract

holyc-inference tests construct manifest fixtures with only hash, length, and path. These fixtures make the narrower worker contract sticky and do not fail when TempleOS-required fields are missing.

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_model_trust_manifest_sha256.py:175`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_model_trust_manifest_sha256.py:213`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_model_quarantine_promote.py:209`

Risk: future code can appear green while remaining incompatible with the TempleOS trusted-load schema. This is a historical drift amplifier: once tests bless the short format, later TempleOS-side schema work will need either a migration rule or a breaking parser update.

### WARNING 4: Secure-local release gate fails closed, but the gate target does not match the committed verifier symbol

`automation/inference-secure-gate.sh` requires `ModelTrustManifestVerifySHA256Checked` in `src/model/trust_manifest.HC`, but the committed verifier entrypoint is `TrustManifestVerifyPathCheckedNoPartial`. Running the gate from holyc-inference currently fails WS16-03, WS16-04, and WS16-05.

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/inference-secure-gate.sh:59`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/trust_manifest.HC:808`
- Command: `cd /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference && automation/inference-secure-gate.sh`
- Result excerpt: `WS16-03 status=fail evidence=missing:src/model/trust_manifest.HC:ModelTrustManifestVerifySHA256Checked`; summary `passed=6 failed=3`.

Risk: this is fail-closed, so it is not a release bypass. It is still a cross-repo readiness blocker because the gate checks symbol presence, not the TempleOS-required manifest schema fields.

## LAWS.md Assessment

- Law 1 HolyC Purity: no violation observed in the audited trust/quarantine runtime files; implementation is HolyC.
- Law 2 Air-Gap Sanctity: no networking path observed; no QEMU/VM command was run.
- Law 4 Integer Purity: no floating-point tensor runtime issue observed in this manifest audit.
- Law 5 North Star / No Busywork: warning-level drift. The current worker manifest contract does not fully support the trusted local model promotion semantics needed for the north-star secure-local path.
- Laws 8-11 Book of Truth / immutable image / local access: no direct violation observed in this schema audit.

## Recommended Follow-Up

- Define a shared manifest version and exact line/record grammar covering `model_id`, `sha256`, quant type, tokenizer hash, provenance, size, and relative path.
- Update holyc-inference parser/tests to reject short trusted-load manifests in `secure-local`, or explicitly mark the current three-field format as `dev-local`/legacy only.
- Update `inference-secure-gate.sh` to check both the real verifier symbol and the required schema-field enforcement, not only a symbol name.

Findings count: 4 warnings, 0 critical.
