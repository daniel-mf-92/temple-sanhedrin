# Cross-Repo Audit: Trinity Policy Sync Inference Drift

- Timestamp: 2026-05-01T22:34:14+02:00
- Scope: TempleOS `0572b6cb`, holyc-inference `a7077664`, temple-sanhedrin `codex/sanhedrin-gpt55-audit`
- Audit angle: cross-repo invariant checks
- Method: ran `automation/check-trinity-policy-sync.sh` from holyc-inference with explicit sibling worktree docs:
  - `TRINITY_INFERENCE_DOC=/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/MASTER_TASKS.md`
  - `TRINITY_TEMPLE_DOC=/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/MODERNIZATION/MASTER_TASKS.md`
  - `TRINITY_SANHEDRIN_DOC=/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55/LOOP_PROMPT.md`

## Summary

The Trinity policy sync gate failed with 18 passing checks and 3 failing checks. All failures are inference-side policy contract drift in `holyc-gpt55/MASTER_TASKS.md`; the paired TempleOS and Sanhedrin policy texts contain the stricter wording.

No QEMU/VM command was executed. No TempleOS or holyc-inference source files were modified.

## Findings

### WARNING: Inference `dev-local` guard wording is weaker than TempleOS policy

- Law: Law 2 Air-Gap Sanctity, Trinity policy parity requirement
- Evidence:
  - `holyc-gpt55/MASTER_TASKS.md:26` says `dev-local` is explicit opt-in for local experimentation only, but does not state that it must remain air-gapped or must not disable Book of Truth.
  - `templeos-gpt55/MODERNIZATION/MASTER_TASKS.md:36` explicitly says `dev-local` must remain air-gapped and must not disable Book of Truth.
  - `sanhedrin-gpt55/LOOP_PROMPT.md:52-56` directs Sanhedrin to flag profile/GPU invariant drift as CRITICAL.
- Impact: a future inference iteration could treat `dev-local` as a relaxed runtime profile and still appear consistent with inference-local docs, while TempleOS policy forbids disabling air-gap or Book-of-Truth controls in that profile.
- Recommended remediation: update inference policy wording to state that `dev-local` is explicit opt-in and still preserves air-gap plus Book-of-Truth requirements.

### WARNING: Inference attestation/policy-digest contract wording does not match gate signature

- Law: Trinity policy parity requirement; trusted-load safety under Laws 2, 3, 8, and 11
- Evidence:
  - `holyc-gpt55/MASTER_TASKS.md:29` says trust decisions remain in TempleOS via attestation + policy-digest handshake.
  - `templeos-gpt55/MODERNIZATION/MASTER_TASKS.md:45-46` requires attestation evidence plus policy digest match and fail-closed behavior.
  - `sanhedrin-gpt55/LOOP_PROMPT.md:81-83` flags trusted-load paths without attestation + policy digest parity language as CRITICAL.
  - The sync gate expects the explicit phrase `attestation/policy-digest handshake` in inference policy and did not find it.
- Impact: the concept exists in inference docs, but the canonical gate signature does not match. That makes automated parity checks fail and weakens future auditability.
- Recommended remediation: either align inference text to the canonical phrase or revise the gate to accept the current `attestation + policy-digest handshake` form consistently across the Trinity.

### WARNING: Inference policy lacks explicit Trinity drift blocker language

- Law: Trinity policy parity requirement
- Evidence:
  - `holyc-gpt55/MASTER_TASKS.md:26-30` defines secure-local, quarantine/hash, GPU, split-plane trust, and secure-on performance requirements, but does not mention Trinity drift or policy changes that create Trinity drift.
  - `templeos-gpt55/MODERNIZATION/MASTER_TASKS.md:51-54` requires synchronized policy invariants and treats policy drift as a release blocker.
  - `sanhedrin-gpt55/LOOP_PROMPT.md:105-106` treats secure-local policy drift and Trinity policy parity mismatches as CRITICAL.
- Impact: inference-side policy changes can appear locally valid without a local reminder that unmatched profile/GPU/quarantine changes must be synchronized across TempleOS and Sanhedrin.
- Recommended remediation: add an inference policy line that blocks policy changes creating Trinity drift unless matching updates or explicit blocking queue items are created.

## Gate Output

```text
summary: status=fail drift=true passed=18 failed=3
failed:
- TRI-SEC-02-INF dev-local-guard missing-pattern holyc-gpt55/MASTER_TASKS.md
- TRI-SEC-05-INF attestation-digest missing-pattern holyc-gpt55/MASTER_TASKS.md
- TRI-SEC-06-INF trinity-drift-guard missing-pattern holyc-gpt55/MASTER_TASKS.md
```

## Conclusion

This is documentation/policy drift, not evidence of a current runtime air-gap breach. The risk is that inference-local control text is less strict than TempleOS and Sanhedrin control text, so future builder iterations may satisfy local inference docs while violating Trinity policy parity.
