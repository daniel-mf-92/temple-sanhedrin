# Cross-Repo Invariant Audit: Sanhedrin Enforcement Semantics Drift

Timestamp: 2026-04-27T21:36:37Z

Auditor: gpt-5.5 sibling, retroactive/deep audit scope

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source code was modified.

Repos examined:
- TempleOS committed HEAD: `5810b24301784186266c8b83c0131dea12a76bdc`
- holyc-inference committed HEAD: `b8a4fc8b7dd7cb2175ff3e4e8f051a7d4b19ca7d`
- temple-sanhedrin committed HEAD: `5eebf42bb1bd738a9793250cf4e6ac12a62d44a5`
- temple-sanhedrin branch: `codex/sanhedrin-gpt55-audit`

## Executive Summary

Found 4 findings: 1 critical, 2 warnings, 1 info.

The trinity policy documents correctly describe secure-local, air-gap, quarantine, GPU/IOMMU, Book-of-Truth, attestation, and policy-digest constraints as release-blocking invariants. The drift is that the committed Sanhedrin enforcement script has automatic teeth only for a narrow subset: identifier compounding, self-generated queue items, and one repeated blocker string. This does not prove a current builder violation, but it means several invariants described as CRITICAL are currently prompt/manual-audit obligations rather than executable enforcement.

## Finding CRITICAL-001: CRITICAL trinity policy invariants are not executable Sanhedrin enforcement rules

Applicable laws and policies:
- Law 1: HolyC purity
- Law 2: Air-gap sanctity
- Law 3/Law 8/Law 9/Law 11: Book-of-Truth safety properties
- Sanhedrin prompt sections 4b-4d: secure-local/GPU/trinity/split-plane checks

Evidence:
- `LAWS.md:13-159` defines HolyC purity, air-gap, Book-of-Truth immutability, hardware proximity, crash-on-log-failure, immutable image, and local-access-only rules.
- `LOOP_PROMPT.md:47-83` says secure-local profile, GPU safety, Trinity parity, and split-plane attestation/policy-digest checks are CRITICAL.
- `LOOP_PROMPT.md:101-107` repeats that secure-local drift, GPU isolation bypass, Trinity mismatches, and missing attestation/policy-digest gates are CRITICAL.
- `automation/enforce-laws.sh:43-89` inspects recent commits only for Law 4 identifier compounding and Law 6 self-generated queue additions.
- `automation/enforce-laws.sh:91-105` checks only one Law 7 blocker pattern: `readonly database`.
- The script contains no automatic checks for core non-HolyC additions, missing `-nic none` / `-net none`, QEMU `readonly=on`, Book-of-Truth disable paths, async/deferred logging, no-HLT log failures, remote log access, secure-local default drift, GPU/IOMMU/BoT bypass, quarantine bypass, or attestation/policy-digest absence.

Assessment:
The enforcement implementation is narrower than the policy surface advertised to the builders. The prompt can still guide the live Sanhedrin loop, and separate retro audits can still catch drift, but `automation/enforce-laws.sh` cannot currently be treated as the executable counterpart of the full LAWS.md/trinity security contract.

Risk:
A future builder commit can violate a high-severity invariant and still receive `enforce-laws: 0 violations` if the violation is outside Law 4 filename checks, Law 6 queue additions, or the hard-coded `readonly database` repeated blocker. That weakens the deterrent effect promised by "Sanhedrin has teeth."

Required remediation:
- Split enforcement status into `manual-audit-only`, `warn-only`, and `auto-revert` classes for every law.
- Add executable, non-destructive detectors for Law 1, Law 2, Law 3, Law 8, Law 9, Law 10, Law 11, and trinity secure-local/GPU/attestation invariants before claiming full automatic enforcement.
- Require the final `enforce-laws` summary to enumerate skipped or manual-only law families, not just a numeric violation count.

## Finding WARNING-001: LAWS.md duplicates Law 4 through Law 7 with changed meanings

Applicable laws:
- Law 4 / Law 5 / Law 6 / Law 7 governance clarity

Evidence:
- `LAWS.md:47-58` defines Law 4 as inference integer purity.
- `LAWS.md:181-189` redefines Law 4 as identifier compounding ban.
- `LAWS.md:60-74` defines Law 5 as no busywork.
- `LAWS.md:191-193` redefines Law 5 as north-star discipline.
- `LAWS.md:76-84` defines Law 6 as queue health.
- `LAWS.md:195-197` redefines Law 6 as no self-generated queue items.
- `LAWS.md:86-94` defines Law 7 as process liveness.
- `LAWS.md:199-201` redefines Law 7 as blocker escalation.

Assessment:
The later "value-not-noise" laws appear to be intended overrides, but the file does not label them as replacements or amendments. This creates ambiguity in audit reports, enforcement logs, and builder remediation. For example, "Law 4 violation" can mean either float/integer runtime impurity or identifier compounding depending on context.

Risk:
Historical reports and future automation can misclassify violations, especially where the enforcement script logs `LAW-4-compounding` while older audits use Law 4 for integer purity.

Required remediation:
- Rename the later rules to distinct IDs, such as Law 12-15 or VNN-1 through VNN-4.
- Add a compatibility note mapping old references to new canonical IDs.
- Update enforcement log labels to include both canonical ID and short name.

## Finding WARNING-002: The trinity policy sync gate passes documentation signatures but does not prove enforcement parity

Applicable laws and policies:
- Law 5: North Star discipline, insofar as green gates should not overstate security progress
- Trinity policy parity checks

Evidence:
- Running `TRINITY_SANHEDRIN_DOC=/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55/LOOP_PROMPT.md bash automation/check-trinity-policy-sync.sh` in holyc-inference returned summary `status=pass`, `drift=false`, `passed=21`, `failed=0`.
- `holyc-inference/automation/check-trinity-policy-sync.sh:96-122` checks regex signatures in inference, TempleOS, and Sanhedrin docs.
- The gate does not inspect `automation/enforce-laws.sh`, `LAWS.md` numbering collisions, or any Sanhedrin executable detector coverage.

Assessment:
The policy sync gate is useful as a documentation parity smoke test. It should not be interpreted as proof that Sanhedrin can enforce those invariants automatically. Its current pass result can coexist with CRITICAL-001 because the checked contract is textual, not executable.

Risk:
Builder summaries or dashboards can over-count "trinity policy parity pass" as enforcement readiness while the actual automatic enforcement surface remains partial.

Required remediation:
- Add a separate `trinity-enforcement-coverage` gate that checks whether each CRITICAL textual invariant has a corresponding Sanhedrin detector.
- Keep `check-trinity-policy-sync.sh` labelled as documentation parity, not enforcement parity.

## Finding INFO-001: Air-gap and source read-only constraints were preserved during this audit

Applicable laws:
- Law 2: Air-gap sanctity

Evidence:
- No QEMU or VM command was executed.
- No TempleOS or holyc-inference file was edited.
- The only live command against the sibling repos was the holyc-inference documentation parity gate, with the Sanhedrin doc path pinned to this audit worktree.
- TempleOS worktree had pre-existing local modifications in `Kernel/KExts.HC`, `Kernel/Sched.HC`, and `MODERNIZATION/MASTER_TASKS.md`; this audit did not inspect them as current-iteration compliance work or modify them.

## Non-Findings

- This audit does not assert that the current TempleOS or holyc-inference HEADs violate secure-local, GPU, air-gap, or attestation policy.
- This audit does not recommend running `automation/enforce-laws.sh` here because the script can perform reverts and pushes; it was read, not executed.
- The holyc-inference trinity policy sync gate passed as a documentation parity check.

## Read-Only Verification Commands

- `nl -ba LAWS.md | sed -n '1,230p'`
- `nl -ba automation/enforce-laws.sh | sed -n '1,180p'`
- `nl -ba LOOP_PROMPT.md | sed -n '43,112p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '31,56p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md | sed -n '21,31p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/check-trinity-policy-sync.sh | sed -n '1,150p'`
- `TRINITY_SANHEDRIN_DOC=/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55/LOOP_PROMPT.md bash automation/check-trinity-policy-sync.sh | tail -n 1`
