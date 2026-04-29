# Cross-Repo Audit: Trinity Policy Gate Provenance Drift

Timestamp: 2026-04-29T13:56:47+02:00

Audit angle: cross-repo invariant check for whether the Trinity `secure-local` policy gate proves the same TempleOS, holyc-inference, and Sanhedrin revisions that this sibling audit is reviewing.

Repos reviewed:
- TempleOS worktree: `/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55` at `98db405302b161726536c70b7b992107df785d30`
- holyc-inference worktree: `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55` at `75b7cba9efd20d1be3df66703a71e9f80077cb86`
- temple-sanhedrin worktree: `/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55` at `ac67d3e436ec5d99b3e2444277333873a699ea0b`

## Summary

No immediate Trinity policy text mismatch was found when the gate was explicitly pointed at the three sibling worktrees: `passed=21`, `failed=0`.

The drift is provenance: the committed holyc-inference `automation/check-trinity-policy-sync.sh` defaults to the current inference worktree for `LOOP_PROMPT.md`, but defaults TempleOS and Sanhedrin inputs to `~/Documents/local-codebases/...`. In this concurrent sibling setup, a passing gate can therefore prove a mixed set of revisions rather than the three heads under audit.

Finding count: 5 total, 4 warnings and 1 info.

## Finding WARNING-001: Default gate inputs mix worktree and local-codebases roots

Laws / policy touched:
- Trinity policy parity checks are treated as CRITICAL in Sanhedrin control docs.
- LAWS.md requires Sanhedrin to read commits and diffs from both builder repos before judging compliance.

Evidence:
- `holyc-inference/automation/check-trinity-policy-sync.sh:10` defaults inference policy to `${REPO_ROOT}/LOOP_PROMPT.md`.
- `holyc-inference/automation/check-trinity-policy-sync.sh:11` defaults TempleOS policy to `${HOME}/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md`.
- `holyc-inference/automation/check-trinity-policy-sync.sh:12` defaults Sanhedrin policy to `${HOME}/Documents/local-codebases/temple-sanhedrin/LOOP_PROMPT.md`.
- Default run from `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55` passed with summary paths:
  - inference doc: `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/LOOP_PROMPT.md`
  - TempleOS doc: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md`
  - Sanhedrin doc: `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-sanhedrin/LOOP_PROMPT.md`

Impact:

A passing `trinity-policy-sync` result can be stale or cross-branch when the active builders run in sibling worktrees. That weakens historical cross-repo audits because the evidence no longer proves the exact TempleOS and Sanhedrin revisions being reviewed.

Recommendation:

Require explicit `TRINITY_TEMPLE_DOC`, `TRINITY_INFERENCE_DOC`, and `TRINITY_SANHEDRIN_DOC` in worktree mode, or teach the gate to resolve sibling worktrees and emit a warning when inputs come from mixed roots.

## Finding WARNING-002: Sanhedrin parity instructions also hardcode local-codebases paths

Evidence:
- `temple-sanhedrin/LOOP_PROMPT.md:50` checks `~/Documents/local-codebases/TempleOS/...` and `~/Documents/local-codebases/holyc-inference/...`.
- `temple-sanhedrin/LOOP_PROMPT.md:61-64` loops over local-codebases TempleOS, holyc-inference, and temple-sanhedrin policy docs.
- The current user scope is explicitly the sibling worktrees under `/Users/danielmatthews-ferrero/Documents/worktrees/*-gpt55`.

Impact:

Sanhedrin can report Trinity parity from the stable local-codebases checkout while this audit branch is reviewing sibling worktree heads. That is not a live air-gap breach, but it is a historical evidence-quality weakness: the auditor may archive a pass that does not bind to the branch/commit set under review.

Recommendation:

Add a worktree-aware path block to Sanhedrin audit instructions or require each parity report to record the three resolved doc paths and corresponding git SHAs.

## Finding WARNING-003: Gate output omits git branch and commit identity

Evidence:
- `holyc-inference/automation/check-trinity-policy-sync.sh:35-40` emits summary JSON with status, drift, counts, and doc paths.
- The summary does not include `git rev-parse HEAD`, branch name, or per-doc repository root.
- The default gate run passed while proving mixed roots, and only the raw paths reveal that fact.

Impact:

The JSONL artifact is machine-readable but not fully reproducible. A later reviewer cannot tell from the gate output alone which TempleOS or Sanhedrin commit was checked, especially if `~/Documents/local-codebases` has advanced since the audit.

Recommendation:

Extend summary output with `inference_sha`, `temple_sha`, `sanhedrin_sha`, `inference_branch`, `temple_branch`, `sanhedrin_branch`, and a `mixed_roots` boolean.

## Finding WARNING-004: Gate tests do not guard default-root provenance

Evidence:
- `holyc-inference/tests/test_trinity_policy_sync_gate.py:57-79` verifies that the gate emits records and a summary, but accepts either pass or fail and does not assert that default docs come from the active sibling worktrees.
- `holyc-inference/tests/test_trinity_policy_sync_gate.py:81-199` uses synthetic override docs to test pass/fail semantics.
- No reviewed test asserts that default path resolution is branch-aware or that output includes commit identity.

Impact:

The test harness protects regex semantics, but not the provenance invariant that matters to retroactive audit. A future change could keep all tests green while continuing to prove policy parity against stale checkout paths.

Recommendation:

Add a provenance test with temporary git repos or explicit env overrides that asserts the summary carries repo roots and SHAs, then add a negative test for mixed roots.

## Finding INFO-005: Current sibling-worktree policy content is aligned when explicitly checked

Evidence:
- Explicit worktree run:
  - `TRINITY_INFERENCE_DOC=/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/LOOP_PROMPT.md`
  - `TRINITY_TEMPLE_DOC=/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/MODERNIZATION/MASTER_TASKS.md`
  - `TRINITY_SANHEDRIN_DOC=/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55/LOOP_PROMPT.md`
- Result: `{"type":"summary","gate":"trinity-policy-sync","status":"pass","drift":"false","passed":21,"failed":0,...}`
- TempleOS current docs keep `secure-local` default, `dev-local` air-gapped, quarantine/hash mandatory, attestation/policy digest match, and policy drift as a release blocker.
- holyc-inference current docs keep throughput work under policy gates and forbid bypassing attestation or policy digest parity.
- Sanhedrin current docs still treat profile/GPU drift, quarantine bypass, and missing attestation/policy-digest gates as critical.

Impact:

No source-code change or builder rollback is indicated by this audit. The required fix is to make the gate's evidence binding stronger so future passes are attributable to the audited revisions.

## Validation

Commands run:
- `bash automation/check-trinity-policy-sync.sh > /tmp/gpt55-trinity-default.jsonl`
- `TRINITY_INFERENCE_DOC=/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/LOOP_PROMPT.md TRINITY_TEMPLE_DOC=/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/MODERNIZATION/MASTER_TASKS.md TRINITY_SANHEDRIN_DOC=/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55/LOOP_PROMPT.md bash automation/check-trinity-policy-sync.sh > /tmp/gpt55-trinity-worktree.jsonl`
- `nl -ba automation/check-trinity-policy-sync.sh | sed -n '1,180p'`
- `nl -ba tests/test_trinity_policy_sync_gate.py | sed -n '1,260p'`
- `nl -ba LOOP_PROMPT.md | sed -n '35,115p'`

No TempleOS or holyc-inference source files were modified. No VM or QEMU command was executed.
