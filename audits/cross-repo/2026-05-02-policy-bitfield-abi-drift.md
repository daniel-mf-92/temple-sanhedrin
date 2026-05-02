# Cross-Repo Audit: Policy Bitfield ABI Drift

- Timestamp: 2026-05-02T10:05:25+02:00
- Audit angle: cross-repo invariant check
- TempleOS repo: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS`
- TempleOS HEAD: `9f3abbf263982bf9344f8973a52f845f1f48d109` (`feat(modernization): codex iteration 20260501-111528`, committed 2026-05-01T11:26:42+02:00)
- holyc-inference repo: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`
- holyc-inference HEAD: `2799283c9554bea44c132137c590f02034c8f726` (`feat(inference): codex iteration 20260430-025722`, committed 2026-04-30T03:00:56+02:00)

## Summary

The repos agree on profile IDs (`secure-local=1`, `dev-local=2`) but not on the policy evidence ABI built around them. TempleOS encodes Book-of-Truth policy payloads as violation/remediation evidence for OS controls, while holyc-inference encodes runtime worker guard booleans into an `InferencePolicyDigest`. Both are useful, but they are not interchangeable and there is no observed adapter tying the worker digest to a TempleOS `BookTruthPolicyCheck` payload, source, sequence, hash, or fail-closed decision.

Finding count: 5 warnings, 0 critical. This audit was read-only for TempleOS and holyc-inference. No QEMU/VM command, networking command, WS8 networking task, or source modification was executed.

## Findings

### WARNING 1 - Shared profile IDs mask incompatible policy bit meanings

Evidence:
- TempleOS defines `BOT_PROFILE_SECURE_LOCAL=1` and `BOT_PROFILE_DEV_LOCAL=2`, then defines policy violation bits as `WX_HALT=1`, `TAMPER_HALT=2`, `SERIAL_MIRROR=4`, `IO_LOG=8`, `DISK_LOG=16`, and `WX_MODE=32` in `Kernel/BookOfTruth.HC:112-119`.
- holyc-inference defines the same profile IDs in `src/runtime/policy_digest.HC:14-15`, but uses policy bits for `iommu`, `bot_dma_log`, `bot_mmio_log`, `bot_dispatch_log`, `quarantine`, `hash_manifest`, `secure-default`, and `active secure-local` in `src/runtime/policy_digest.HC:135-147`.

Impact: any cross-repo consumer that treats `policy_bits` as a common ABI will misread the same bit positions. For example, bit 2 is TempleOS serial mirroring but inference MMIO logging.

Recommended closure: publish a versioned Trinity policy tuple that labels the producer (`TempleOS.BookTruthPolicyCheck` vs `InferencePolicyDigest`) and forbids raw bitfield comparison across producers.

### WARNING 2 - Inference digest does not include TempleOS Book-of-Truth policy state

Evidence:
- TempleOS `BookTruthPolicyCheck` builds a payload with marker `BOT_POLICY_PAYLOAD_MARKER`, profile, pre-violation mask, post-violation mask, fix count, enforce flag, secure-mode flag, and source in `Kernel/BookOfTruth.HC:13269-13330`.
- holyc-inference `InferencePolicyDigestChecked` mixes profile ID, secure-default flag, worker guard booleans, profile constants, and the worker policy bitfield in `src/runtime/policy_digest.HC:151-166`.
- The inference digest path has no input for the TempleOS policy payload, `BookTruthAppend` result, source ID, ledger sequence, or entry hash.

Impact: a matching inference policy digest can prove worker-side guard consistency, but it cannot prove TempleOS policy enforcement or Book-of-Truth anchoring. Treating it as TempleOS approval would weaken Laws 8 and 9.

Recommended closure: require a separate TempleOS-originated proof tuple for trusted dispatch/key release: policy payload, append status, sequence/hash, and fail-closed result.

### WARNING 3 - TempleOS policy check repairs local controls; inference policy setter can relax worker flags

Evidence:
- In secure-local mode, `BookTruthPolicyCheck(enforce=TRUE)` repairs disabled TempleOS controls by setting halt-on-WX, tamper halt, serial mirror, IO log, disk log, and WX mode back to enabled before emitting policy evidence in `Kernel/BookOfTruth.HC:13280-13303`.
- `InferencePolicyRuntimeGuardsSetChecked` accepts any binary values for IOMMU, Book-of-Truth DMA/MMIO/dispatch logging, quarantine, and hash-manifest gates, then stores them directly in globals in `src/runtime/policy_digest.HC:61-83`.

Impact: the TempleOS policy function is enforcement-oriented, while the inference setter is state-setting-oriented. A future integration that only checks "binary and digestable" worker flags may allow relaxed worker state to remain set instead of mirroring TempleOS repair/fail-closed semantics.

Recommended closure: define secure-local worker guard setters as fail-closed or TempleOS-authorized only; do not let a local worker setter become the authority for downgrading secure-local controls.

### WARNING 4 - Model promotion gates and worker quarantine gates are not the same proof

Evidence:
- TempleOS model promotion requires quarantine state, schema verification, parse status, deterministic replay in secure-local, and build/kernel integrity in secure-local before switching to `BOT_MODEL_STATE_TRUSTED` in `Kernel/BookOfTruth.HC:13740-13819`.
- holyc-inference policy digest only includes `quarantine_gate_enabled` and `hash_manifest_gate_enabled` as booleans in `src/runtime/policy_digest.HC:86-172`.

Impact: inference can truthfully report that quarantine/hash gates are enabled without proving that TempleOS has promoted the specific model under its Book-of-Truth model gate. This is an invariant drift, not a runtime violation by itself.

Recommended closure: bind inference attestation to a TempleOS model ID, promotion event marker, and `BookTruthModelGateStatus`-compatible result before allowing `trusted` or key-release wording.

### WARNING 5 - Policy evidence has no single versioned schema boundary

Evidence:
- TempleOS policy payloads are marker-based (`0xBE`) inside the Book of Truth, with the payload layout embedded in `BookTruthPolicyCheck` and decoded by `BookTruthPolicyStatus`.
- holyc-inference defines `INFERENCE_POLICY_DIGEST_VERSION=1` for digest domain separation, but that version is local to the worker digest and does not version the Trinity ABI shared with TempleOS.

Impact: both sides can evolve their local policy layouts while keeping tests green, because no cross-repo schema version asserts which fields must exist, how they map, or what proof source is authoritative.

Recommended closure: add a small cross-repo schema document or Sanhedrin check that enumerates `TrinityPolicyEvidenceV1` fields and rejects unversioned policy handshakes.

## Commands Run

```sh
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS log -1 --format='%h %cI %s'
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference log -1 --format='%h %cI %s'
rg -n "BOT_POLICY_V_|BOT_PROFILE_|BOT_POLICY_PAYLOAD_MARKER|BookTruthPolicyCheck|BookTruthProfileSet|BOT_MODEL_GATE_|BOT_MODEL_FMT_|BOT_MODEL_MARK_" /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC
rg -n "INFERENCE_POLICY_|policy_bits|g_policy_|bot_.*log|profile_id|secure_default|INFERENCE_POLICY_PROFILE" /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/policy_digest.HC /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/attestation_manifest.HC /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/policy.HC
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '112,140p;13221,13333p;13454,13820p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/policy_digest.HC | sed -n '1,180p'
```
