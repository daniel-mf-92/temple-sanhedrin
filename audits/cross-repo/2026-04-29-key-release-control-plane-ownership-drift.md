# Cross-Repo Key-Release Control-Plane Ownership Drift Audit

Timestamp: 2026-04-29T07:53:18+02:00

Audit owner: gpt-5.5 sibling, retroactive / historical scope only

Repos examined:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `75727979e5cba07e7959d4770c9abffe85be78e1`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `485af0ea41a239c8393542d6e0e2fc5944f30f53`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit`

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source code was modified. No QEMU, VM, WS8 networking, or live liveness command was executed.

## Summary

Found 5 findings: 4 warnings and 1 info.

This pass checked whether key-release authority is owned by the TempleOS control plane, as the current TempleOS policy says, or by the holyc-inference worker plane. The repos agree in docs that TempleOS owns policy, quarantine, promotion authority, and key-release decisions, but the implemented inference gate currently accepts proof booleans and decides release locally. TempleOS still lists the attestation verifier, policy-digest handshake, and key-release gate as unchecked WS14 work.

## Finding WARNING-001: Key-release decision exists in worker-plane code before TempleOS control-plane gate exists

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:43-46` says TempleOS remains the trust/control plane, key-release authority, and Book-of-Truth source of truth; trusted-load/key-release requires worker attestation evidence plus policy digest match.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:276-278` keeps WS14-18, WS14-19, and WS14-20 unchecked: attestation verifier, `InferencePolicyDigest` validation, and key-release gate are not yet completed on the TempleOS side.
- `holyc-inference/src/runtime/key_release_gate.HC:29-88` implements `InferenceKeyReleaseHandshakeVerifyChecked` and sets `out_release_allowed` from locally supplied proof flags.
- `TempleOS/MODERNIZATION/LOOP_PROMPT.md:54-56` says TempleOS owns trust decisions and they must not move into throughput-only workers.

Assessment:
The worker-plane helper is valid as a diagnostic predicate, but it is drift if treated as the release authority. Until TempleOS owns a completed WS14-18/19/20 path that verifies evidence and appends the decision to Book of Truth, the inference-side release boolean can be caller-asserted rather than TempleOS-decided.

Required remediation:
- Treat `InferenceKeyReleaseHandshakeVerifyChecked` as advisory until a TempleOS-owned release gate exists.
- Complete TempleOS WS14-18 through WS14-20 with a Book-of-Truth append for both approval and denial.
- Require trusted runs to consume a TempleOS-issued proof tuple, not a worker-local release result.

## Finding WARNING-002: "TempleOS signed approval" is represented as a one-bit caller input

Applicable laws:
- Law 3: Book of Truth Immutability

Evidence:
- `holyc-inference/src/runtime/key_release_gate.HC:29-31` accepts `templeos_signed_approval`, `attestation_evidence_valid`, and `policy_digest_parity_valid` as scalar inputs.
- `holyc-inference/src/runtime/key_release_gate.HC:49-52` only validates those inputs as binary flags.
- `holyc-inference/src/runtime/key_release_gate.HC:77-84` grants release when all failure bits are zero.
- The TempleOS search surface for key-release approval found policy/task lines, but no `BookTruthKeyRelease*`, `InferenceKeyRelease*`, signature verifier, or approval-token implementation in `Kernel/` or `MODERNIZATION/` source paths.

Assessment:
The phrase "signed approval" implies a non-forgeable TempleOS statement, but the implemented interface only sees `0` or `1`. It has no signer identity, approval digest, nonce, model identity, Book-of-Truth sequence, or hash-chain anchor. That is insufficient for cross-repo proof because the untrusted worker API can be invoked with `templeos_signed_approval=1`.

Required remediation:
- Define a TempleOS approval record with at least `{model_id, sha_hi, sha_lo, tok_hash, policy_digest, attestation_nonce, seq, entry_hash}`.
- Have the inference helper verify a structured TempleOS approval proof, or rename it as a pure local precheck.
- Add a negative test proving a bare `1` cannot unlock secure-local release.

## Finding WARNING-003: Policy-digest parity is boolean, not value-bound to TempleOS validation

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 5: North Star Discipline

Evidence:
- `holyc-inference/src/runtime/policy_digest.HC:86-172` computes a worker-side digest from profile and policy guard bits.
- `holyc-inference/src/runtime/key_release_gate.HC:29-31` accepts only `policy_digest_parity_valid`, not the local digest, expected TempleOS digest, or a signed TempleOS comparison result.
- `holyc-inference/src/model/inference.HC` token event helpers pass both `policy_digest_q64` and `expected_policy_digest_q64`, showing that exact digest-value parity is already a known local pattern.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:277` still leaves TempleOS `InferencePolicyDigest` validation unchecked.

Assessment:
The key-release gate weakens the stronger digest-value pattern already used elsewhere in inference. A boolean parity flag loses the proof payload Sanhedrin needs to replay or inspect drift, and TempleOS has not yet implemented the corresponding verifier.

Required remediation:
- Change the cross-repo contract from `policy_digest_parity_valid` to an auditable tuple: `{worker_digest, temple_expected_digest, comparison_status, temple_seq, temple_entry_hash}`.
- Keep the inference boolean only as a derived result from that tuple.
- Add Sanhedrin parsing that rejects key-release reports without digest values and TempleOS ledger anchors.

## Finding WARNING-004: Key-release is not bound to TempleOS model quarantine identity

Applicable laws:
- Law 3: Book of Truth Immutability

Evidence:
- `TempleOS/Kernel/BookOfTruth.HC:12389-12437` records model import with `model_id`, `sha_hi`, `sha_lo`, `quant`, `tok_hash`, and provenance.
- `TempleOS/Kernel/BookOfTruth.HC:12439-12475` verifies imported model identity by comparing `sha_hi`, `sha_lo`, and `tok_hash`.
- `TempleOS/Kernel/BookOfTruth.HC:12478-12527` promotes only a verified quarantined model, and emits success or verify-fail events.
- `holyc-inference/src/runtime/key_release_gate.HC:29-34` has no model identity, hash, tokenizer hash, quant type, provenance, or TempleOS quarantine slot input.

Assessment:
TempleOS now has a concrete model-quarantine identity surface, but key-release does not bind to it. A release proof should identify the exact trusted model that TempleOS imported, verified, and promoted; otherwise a valid generic key-release status can be replayed against the wrong model/session.

Required remediation:
- Include TempleOS model identity in the key-release proof tuple.
- Require the TempleOS gate to deny release unless the model is in `BOT_MODEL_STATE_TRUSTED` with matching hash/tokenizer fields.
- Emit a Book-of-Truth denial when the inference request omits or mismatches model identity.

## Finding INFO-001: Current trinity policy-sync gate passed, but it is doc-pattern coverage only

Applicable laws:
- Law 5: North Star Discipline
- Law 7: Blocker Escalation

Evidence:
- `bash automation/check-trinity-policy-sync.sh` in holyc-inference exited 0 with 21 checks passed and drift reported false.
- `holyc-inference/automation/check-trinity-policy-sync.sh:100-122` checks regexes in LOOP_PROMPT and MASTER_TASKS policy docs.
- The same run did not inspect TempleOS `Kernel/` source for implemented key-release/verifier functions or unchecked WS14 task state.

Assessment:
The sync gate is useful for policy-document drift, but it cannot catch the implementation-level ownership gap found here. It should not be used as evidence that key-release enforcement is complete.

Required remediation:
- Add a source-level or task-state check for TempleOS WS14-18/19/20 before reporting key-release parity as release-ready.
- Add a Sanhedrin check that flags worker-side key-release APIs that accept bare proof booleans without a TempleOS proof tuple.

## Non-Findings

- No TempleOS or holyc-inference source file was edited.
- No QEMU or VM command was run.
- No networking stack, NIC driver, socket, TCP/IP, UDP, TLS, DHCP, DNS, HTTP, or WS8 networking task was executed.
- The drift is about trust-plane ownership and proof shape, not a guest air-gap breach.

## Read-Only Verification Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS status --short --branch
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference status --short --branch
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '30,60p;250,282p;4196,4204p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '12300,12560p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/key_release_gate.HC | sed -n '1,120p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/policy_digest.HC | sed -n '1,210p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/attestation_manifest.HC | sed -n '1,120p;150,235p;260,330p'
bash /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/check-trinity-policy-sync.sh
rg -n "KeyRelease|key release|signed approval|attestation evidence verifier|policy-digest handshake|InferenceKeyRelease|InferencePolicyDigest|BookTruth.*Policy|BookTruth.*Attest|approval" /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation -g '*.HC' -g '*.HH' -g '*.md' -g '*.sh'
rg -n "templeos_signed_approval|policy_digest_parity_valid|attestation_evidence_valid|InferenceKeyReleaseStatus|InferenceKeyReleaseHandshakeVerifyChecked|policy_digest_q64|attestation_nonce|model_id|sha|tok_hash" /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests -g '*.HC' -g '*.py'
```
