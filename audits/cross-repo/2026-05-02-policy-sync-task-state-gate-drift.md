# Cross-Repo Policy Sync Task-State Gate Drift

Audit angle: cross-repo invariant check. This pass compared current TempleOS `HEAD` (`9f3abbf263982bf9344f8973a52f845f1f48d109`) and current holyc-inference `HEAD` (`2799283c9554bea44c132137c590f02034c8f726`) against the Trinity policy sync gate and LAWS.md. It was read-only for both sibling repos. No TempleOS or holyc-inference source was modified. No live liveness watching, process restart, QEMU/VM command, networking command, or WS8 networking task was executed. The TempleOS guest air-gap was not touched.

## Summary

`holyc-inference/automation/check-trinity-policy-sync.sh` passes all 21 doc-pattern checks, but that success is narrower than the secure-local trust invariant it appears to represent. TempleOS still lists its control-plane attestation verifier, `InferencePolicyDigest` validation, and key-release gate as unchecked WS14 tasks, while holyc-inference already has worker-side digest, attestation, key-release, and secure-on performance helpers. The drift is not a confirmed Law 1 or Law 2 breach; it is a warning that policy sync can go green while implementation/task-state still says trusted dispatch must remain fail-closed.

## Evidence Snapshot

| Check | Result |
| --- | ---: |
| Trinity policy sync script exit code | 0 |
| Trinity policy sync checks passed | 21 |
| Trinity policy sync checks failed | 0 |
| TempleOS WS14-18 attestation verifier | unchecked |
| TempleOS WS14-19 policy-digest validation | unchecked |
| TempleOS WS14-20 key-release gate | unchecked |
| holyc-inference policy digest emitter | implemented |
| holyc-inference attestation emitter | implemented |
| holyc-inference key-release verifier | implemented |

## Findings

### WARNING-001: Policy sync gate is doc-presence/regex only, not task-state aware

Law: Law 5, North Star Discipline; cross-repo invariant.

Evidence: Running `bash automation/check-trinity-policy-sync.sh` in `holyc-inference` exited `0` and emitted `passed:21, failed:0`. The gate checks `LOOP_PROMPT.md`, `TempleOS/MODERNIZATION/MASTER_TASKS.md`, and `temple-sanhedrin/LOOP_PROMPT.md` for policy strings such as `secure-local`, quarantine/hash, IOMMU/Book-of-Truth, and attestation/policy-digest parity. It does not inspect whether the corresponding TempleOS WS14 implementation rows are complete.

Impact: The Trinity gate can report `drift:false` even when the control-plane implementation state still says trusted dispatch/key release is incomplete. That can make audit summaries overstate readiness.

### WARNING-002: TempleOS still marks the control-plane trust gates open

Law: cross-repo invariant; Law 5.

Evidence: `TempleOS/MODERNIZATION/MASTER_TASKS.md` states that TempleOS owns the trust/control plane and that trusted-load/key-release flows require worker attestation evidence plus policy digest match. The same file still has WS14-18 "Add attestation evidence verifier for worker plane", WS14-19 "Add policy-digest handshake (`InferencePolicyDigest`) validation before trusted dispatch", and WS14-20 "Add key-release gate" unchecked.

Impact: Until those TempleOS rows are complete, inference-side helpers are advisory worker-plane predicates. They should not be treated as TempleOS approval, trusted dispatch authorization, or key release.

### WARNING-003: holyc-inference has worker-side emitters/verifiers that can look release-complete out of context

Law: cross-repo invariant; Law 5.

Evidence: `holyc-inference/src/runtime/policy_digest.HC` implements `InferencePolicyDigest` with default-on guard globals for IOMMU, Book-of-Truth DMA/MMIO/dispatch logs, quarantine, and hash-manifest gates. `holyc-inference/src/runtime/attestation_manifest.HC` emits session/profile/policy/GPU state lines. `holyc-inference/src/runtime/key_release_gate.HC` implements `InferenceKeyReleaseHandshakeVerifyChecked`, requiring TempleOS signed approval, valid attestation, and policy digest parity.

Impact: These are useful worker-plane checks, but without a TempleOS-produced proof tuple, source ledger sequence/hash, or completed TempleOS verifier, a green worker helper can be mistaken for the sovereign control-plane decision that the policy text assigns to TempleOS.

### WARNING-004: Current sync gate can pass without proving TempleOS source support for `InferencePolicyDigest`

Law: cross-repo invariant; Law 8/11 as trust-evidence constraints.

Evidence: A TempleOS source search for `InferencePolicyDigest`, `policy digest`, `policy-digest`, `attestation`, and `key-release` in `Kernel/`, `MODERNIZATION/`, and `automation/` found policy/docs and build-attestation model-gate smoke coverage, but no completed TempleOS runtime verifier for the inference policy digest handshake. The script nevertheless passes because it only verifies policy wording.

Impact: Trusted-dispatch evidence remains non-executable on the TempleOS side. For secure-local claims, the absence of a TempleOS verifier should be treated as fail-closed or CPU-only fallback, matching the policy wording.

### WARNING-005: Sanhedrin pass/fail wording should distinguish policy parity from release readiness

Law: Sanhedrin enforcement semantics; Law 5.

Evidence: Sanhedrin `LOOP_PROMPT.md` says to treat Trinity policy parity mismatches and missing attestation/policy-digest gates as CRITICAL. The existing holyc-inference sync gate reports a single summary of `status:"pass"` and `drift:"false"` for document parity, but does not emit a separate status for implementation/task-state readiness.

Impact: Future automation can consume the gate as a release signal instead of a document-parity signal. The safer contract is two-stage: docs synchronized, then source/task-state gates proven before secure-local trusted dispatch/key release can count.

## Recommended Closure

- Extend `check-trinity-policy-sync.sh` or add a Sanhedrin-owned companion gate that fails or warns when TempleOS WS14-18/19/20 remain unchecked.
- Require a TempleOS-originated proof tuple for trusted dispatch/key release: profile, attestation verifier result, policy digest comparison, Book-of-Truth sequence/hash, and fail-closed action.
- Rename the current gate output or summary detail to make clear it proves document parity only.
- Keep holyc-inference helpers as worker-plane predicates until TempleOS control-plane verification is implemented and Book-of-Truth anchored.

## Commands Run

```sh
git rev-parse HEAD
bash automation/check-trinity-policy-sync.sh
rg -n "InferencePolicyDigest|policy digest|policy-digest|attestation|Attestation|KeyRelease|key release|key-release" Kernel MODERNIZATION/MASTER_TASKS.md MODERNIZATION/LOOP_PROMPT.md MODERNIZATION/AGENT_HOLYC_MODERN_OS_GUIDE.md automation -g '!automation/logs/**'
rg -n "InferencePolicyDigest|PolicyDigest|Attestation|attestation|KeyRelease|key release|policy_digest|policy digest|policy-digest" src tests MASTER_TASKS.md LOOP_PROMPT.md
```
