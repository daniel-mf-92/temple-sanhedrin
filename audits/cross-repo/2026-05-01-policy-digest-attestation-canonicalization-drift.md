# Cross-Repo Audit: Policy Digest Attestation Canonicalization Drift

Timestamp: 2026-05-01T23:21:21+02:00

Scope:
- TempleOS repo: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS`
- TempleOS head: `9f3abbf263982bf9344f8973a52f845f1f48d109`
- holyc-inference repo: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`
- holyc-inference head: `2799283c9554bea44c132137c590f02034c8f726`
- Audit angle: cross-repo invariant check for policy-digest and attestation manifest canonicalization

Read-only/static audit only. No TempleOS or holyc-inference source files were modified. No QEMU, VM, WS8 networking task, socket, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, package install, remote fetch, or live liveness watcher was executed.

## Summary

holyc-inference now has a worker-side policy digest and an attestation manifest that emits `policy_digest`, `iommu_active`, and `bot_gpu_hooks_active`. TempleOS has hardware-proximate IOMMU/DMA Book-of-Truth records and status digests. The drift is that these two surfaces still do not share a canonical representation: the inference manifest accepts caller-supplied policy-digest text, the digest function returns a signed `I64`, the benchmark binding digest omits several emitted attestation fields, and TempleOS only exposes aggregate DMA/IOMMU status rather than a per-session digest tuple that can be compared to the worker manifest.

Findings: 5 warnings, 0 critical.

## Findings

### WARNING-1: `policy_digest_hex` is not validated as a canonical hex digest

Applicable laws:
- Law 5: North Star Discipline
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- holyc-inference names the manifest field `policy_digest_hex` and allocates `ATTEST_DIGEST_HEX_CHARS + 1` bytes in `src/runtime/attestation_manifest.HC:13` and `src/runtime/attestation_manifest.HC:21`.
- `InferenceAttestationManifestInitChecked` copies the caller-provided value through `AttestManifestCopySanitizedChecked` at `src/runtime/attestation_manifest.HC:192-195`.
- `AttestManifestCopySanitizedChecked` accepts letters, digits, `-`, `_`, `.`, `:`, and `/`, stops at any length up to the maximum, and does not require exactly 64 hex characters at `src/runtime/attestation_manifest.HC:83-116`.
- The Python mirror in `tests/test_runtime_attestation_manifest.py:46-65` follows the same permissive copy behavior.

Assessment:
The field name and width imply a stable 64-hex digest, but the accepted representation is arbitrary safe text of variable length. A worker can emit `policy_digest=abc`, `policy_digest=session/foo`, or a non-zero-padded value and still pass the local manifest initializer. That makes historical Sanhedrin joins ambiguous and prevents a byte-for-byte comparison with any future TempleOS policy-digest proof.

Required remediation:
- Define one canonical policy digest representation, preferably fixed-width lowercase hex for the full 64-bit or 256-bit contract.
- Enforce exact length and hex alphabet in `InferenceAttestationManifestInitChecked`.
- Add negative tests for short values, separators, non-hex letters beyond `f`, and missing zero padding.

### WARNING-2: The policy digest producer returns signed `I64`, but the manifest consumes caller-formatted text

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- `InferencePolicyDigestChecked` writes the digest to an `I64 *out_policy_digest` and `InferencePolicyDigest()` returns `I64` at `src/runtime/policy_digest.HC:86-94` and `src/runtime/policy_digest.HC:177-200`.
- The manifest stores policy digest as text supplied by the caller, not as the direct output of `InferencePolicyDigestChecked`, at `src/runtime/attestation_manifest.HC:162-195`.
- `InferenceAttestationManifestEmitChecked` emits that caller text unchanged as `policy_digest=` at `src/runtime/attestation_manifest.HC:265-267`.

Assessment:
There is no committed conversion rule from signed `I64` digest to manifest text: decimal vs hex, signed vs unsigned, uppercase vs lowercase, and zero padding are all outside the code contract. Two correct implementations can produce different manifest strings for the same digest, or the manifest can carry text unrelated to the current policy tuple.

Required remediation:
- Add a single HolyC helper such as `InferencePolicyDigestToHexChecked` and use it inside the manifest initializer/emitter path.
- Prefer passing a numeric digest into the manifest and formatting internally, so callers cannot drift from the digest producer.

### WARNING-3: The policy-digest binding digest does not bind all emitted attestation fields

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 5: North Star Discipline

Evidence:
- `InferenceAttestationManifest` emits `trusted_models`, `quarantine_blocks`, `gpu_dispatch_allowed`, `iommu_active`, and `bot_gpu_hooks_active` at `src/runtime/attestation_manifest.HC:285-316`.
- `InferencePolicyDigestBindPayload` contains only `policy_digest_q64`, `telemetry_digest_q64`, `total_ops`, `total_cycles`, `profile_id`, `attestation_nonce`, and `bound_digest_q64` at `src/runtime/attestation_manifest.HC:324-332`.
- `Q8_0DotBenchRunDefaultSuitePolicyDigestBindChecked` mixes only those payload fields at `src/runtime/attestation_manifest.HC:348-366`.

Assessment:
The bound digest can prove benchmark telemetry was joined to a policy digest/profile/nonce tuple, but it does not protect the other manifest claims. `iommu_active`, `bot_gpu_hooks_active`, `gpu_dispatch_allowed`, `trusted_models`, and `quarantine_blocks` can vary without changing `bound_digest_q64`.

Required remediation:
- Include every security-relevant manifest field in the bound digest, or split the current benchmark binding from a separate `attestation_manifest_digest`.
- Add a regression vector proving that flipping `iommu_active` or `bot_gpu_hooks_active` changes the bound attestation digest.

### WARNING-4: TempleOS DMA/IOMMU evidence is aggregate-window status, not a per-session attestation tuple

Applicable laws:
- Law 8: Book of Truth Immediacy & Hardware Proximity
- Law 11: Book of Truth Local Access Only

Evidence:
- TempleOS logs IOMMU/GPU allow, deny, map, unmap, and MMIO outcomes with `BookTruthDMARecord(...)` calls in `Kernel/IOMMU.HC:118-199` and `Kernel/IOMMU.HC:248-269`.
- `BookTruthDMAStatus` aggregates recent rows into totals and a digest over `rows_in`, `rows`, operation counts, `iommu_on`, `blocked`, decode failures, first/last sequence, last payload, and verify state at `Kernel/BookOfTruth.HC:82552-82631`.
- holyc-inference emits per-session fields `nonce`, `gpu_dispatch_allowed`, `iommu_active`, and `bot_gpu_hooks_active` at `src/runtime/attestation_manifest.HC:278-316`.

Assessment:
The TempleOS side has useful local evidence, but the status digest is window-relative and does not include the inference session nonce, profile ID, worker policy digest, or bound digest. It cannot be mechanically compared with one inference attestation manifest without host-side convention about which window and which sequence range belong to the session.

Required remediation:
- Add a TempleOS-owned session attestation event that includes `{session_nonce, profile_id, worker_policy_digest, iommu_state, hook_mask, first_seq, last_seq, ledger_digest}`.
- Treat current `BookTruthDMAStatus` output as supporting local telemetry, not the canonical proof consumed by holyc-inference.

### WARNING-5: IOMMU enable/disable transitions are mutable console state without a Book-of-Truth transition event

Applicable laws:
- Law 8: Book of Truth Immediacy & Hardware Proximity
- Law 9: Resource Supremacy / Crash on Log Failure

Evidence:
- `IOMMUGPUSet(Bool on=TRUE)` mutates `iommu_gpu_on` and prints `IOMMUGPUSet: on=%d deny_default=%d` at `Kernel/IOMMU.HC:289-292`.
- `IOMMUGPUStatus` later prints current state and counters at `Kernel/IOMMU.HC:295-310`.
- `IOMMUGPUSet` does not call `BookTruthDMARecord`, `BookTruthAppend`, or another Book-of-Truth transition append in the audited source.
- holyc-inference defaults `g_policy_iommu_enabled = 1` and mixes the IOMMU bit into the policy digest at `src/runtime/policy_digest.HC:27-33` and `src/runtime/policy_digest.HC:135-168`.

Assessment:
If the TempleOS IOMMU state changes, the durable ledger sees later DMA outcomes but not the transition itself. A worker-side manifest can claim `iommu_active=1` while TempleOS has no session-bound transition proof showing that the state was enabled before the relevant dispatch and stayed enabled through the session.

Required remediation:
- Ledger every IOMMU policy transition synchronously with the old state, new state, reason, source, and current Book-of-Truth sequence.
- Include the latest IOMMU transition sequence in the per-session attestation tuple.

## Non-Findings

- No HolyC purity violation was found in the audited core files.
- No networking source, WS8 execution, or VM/QEMU command was used during this audit.
- TempleOS current source records many DMA/IOMMU outcomes in Book-of-Truth paths; the issue is canonical session binding, not absence of all hardware evidence.
- holyc-inference current source keeps the audited digest and manifest logic integer-only.

## Verification Commands

```bash
date -Iseconds
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
rg -n "policy_digest_hex|ATTEST_DIGEST_HEX_CHARS|policy_digest|bound_digest|Q8_0DotBenchRunDefaultSuitePolicyDigestBindChecked|InferencePolicyDigest\\(|InferencePolicyDigestChecked" src/runtime/attestation_manifest.HC src/runtime/policy_digest.HC tests/test_runtime_attestation_manifest.py tests/test_runtime_q8_0_dot_bench_policy_digest_bind_checked.py
rg -n "IOMMUGPUSet|IOMMUGPUStatus|BookTruthDMAStatus|BookTruthDMARecord\\(|BookTruthDMAPayloadDecode|BookTruthHashWord\\(digest,iommu|BookTruthHashWord\\(digest,blocked" Kernel/IOMMU.HC Kernel/BookOfTruth.HC Kernel/KExts.HC
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/attestation_manifest.HC | sed -n '1,380p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/policy_digest.HC | sed -n '1,230p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/IOMMU.HC | sed -n '1,330p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '82545,82635p'
```
