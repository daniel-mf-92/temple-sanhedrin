# Cross-Repo Invariant Audit: Trinity Policy Gate Coverage Drift

Timestamp: 2026-04-28T03:46:50Z

Auditor: gpt-5.5 sibling, retroactive/deep audit scope

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source code was modified, and no VM/QEMU command was executed.

Repos examined:
- TempleOS committed HEAD: `08b7cbb5ecc9decc30cb29932a2161dcca0627b5`
- holyc-inference committed HEAD: `b8a4fc8b7dd7cb2175ff3e4e8f051a7d4b19ca7d`
- temple-sanhedrin audit branch baseline: `7a37e4dc1d1c626debd0edb57ef8cfdaf16e6958`
- temple-sanhedrin main control-doc HEAD used by holyc default gate path: `bb880726b206122870d133df09cc463ff6c72be7`
- temple-sanhedrin branch: `codex/sanhedrin-gpt55-audit`

## Executive Summary

Found 5 findings: 4 warnings, 1 info.

The Trinity policy signatures are currently present and the holyc-inference `trinity-policy-sync` checker passes when run directly. The drift is coverage and integration: the only machine-readable Trinity parity gate lives in holyc-inference, scans a partial set of controlling docs, is not included in holyc-inference's secure-local release gate, and has no TempleOS-side equivalent. This means profile/GPU/quarantine policy can still drift between control docs or release paths while the nearest release gates remain green.

## Finding WARNING-001: Trinity parity checker is not part of the holyc secure-local release gate

Applicable laws:
- Law 5: North Star Discipline
- Sanhedrin secure-local / Trinity parity policy in `LOOP_PROMPT.md`

Evidence:
- `holyc-inference/automation/check-trinity-policy-sync.sh:8-12` defines the `trinity-policy-sync` gate and its three doc paths.
- `holyc-inference/automation/inference-secure-gate.sh:59-69` checks trusted manifest, eval gate, GGUF hardening, GPU policy, Book-of-Truth bridge, command verification, and the existence of `automation/inference-secure-gate.sh`.
- `holyc-inference/automation/inference-secure-gate.sh:71-77` emits pass/fail solely from those WS16/WS9 checks; it does not invoke or require `automation/check-trinity-policy-sync.sh`.
- `holyc-inference/MASTER_TASKS.md:1158` marks IQ-1265 done for the Trinity policy checker, while `MASTER_TASKS.md:1152` separately marks IQ-1258 done for the secure-local release gate.

Assessment:
The parity checker exists but is not a release blocker for the holyc secure-local gate. A secure-local release gate pass can therefore omit the cross-repo policy parity check that the docs describe as critical.

Risk:
GPU/quarantine/profile changes could pass the local secure gate while Trinity policy drift is only detectable by a separately run script.

Required remediation:
- Make `automation/inference-secure-gate.sh` invoke `automation/check-trinity-policy-sync.sh` or consume its summary JSONL.
- Add a release-gate result field for `trinity_policy_sync=pass|fail`.
- Keep the standalone checker for diagnostics, but make secure-local release impossible when parity fails.

## Finding WARNING-002: TempleOS has policy parity doctrine but no equivalent machine-readable gate

Applicable laws:
- Law 5: North Star Discipline
- Sanhedrin Trinity parity policy

Evidence:
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:49-54` says Trinity policy invariants must stay synchronized and policy drift is a release blocker.
- `TempleOS/MODERNIZATION/LOOP_PROMPT.md:43-50` instructs TempleOS agents to preserve parity across TempleOS, holyc-inference, and temple-sanhedrin policy docs.
- `TempleOS/MODERNIZATION/LOOP_PROMPT.md:64-67` forbids guest networking, Book-of-Truth bypass, model quarantine bypass, GPU changes without IOMMU/Book-of-Truth hooks, and Trinity drift.
- `TempleOS/automation/enforce-templeos-airgap.sh:38-68` checks dependency manifests, non-HolyC core implementation files, networking tokens, and QEMU no-network flags in changed files.
- A read-only search for `check-trinity-policy-sync.sh` under TempleOS returned no committed TempleOS-side equivalent.

Assessment:
TempleOS documents the same Trinity policy contract but currently enforces only a narrower HolyC/air-gap changed-file gate. The machine-readable parity gate is owned by holyc-inference, not by the TempleOS trust/control plane that the docs say is sovereign.

Risk:
TempleOS-side profile or GPU policy edits can remain locally compliant with air-gap/HolyC checks while drifting from inference or Sanhedrin policy text.

Required remediation:
- Add a short TempleOS-side Trinity parity gate, or vendor a shared Sanhedrin-owned checker invoked from TempleOS validation.
- Cover at least `TempleOS/MODERNIZATION/MASTER_TASKS.md`, `TempleOS/MODERNIZATION/LOOP_PROMPT.md`, `holyc-inference/MASTER_TASKS.md`, `holyc-inference/LOOP_PROMPT.md`, and `temple-sanhedrin/LOOP_PROMPT.md`.
- Keep the output machine-readable and fail closed on missing docs or missing invariant signatures.

## Finding WARNING-003: holyc Trinity checker scans a partial and asymmetric doc set

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- `holyc-inference/automation/check-trinity-policy-sync.sh:10-12` defaults to `holyc-inference/LOOP_PROMPT.md`, `TempleOS/MODERNIZATION/MASTER_TASKS.md`, and `temple-sanhedrin/LOOP_PROMPT.md`.
- `holyc-inference/LOOP_PROMPT.md:27-30` says policy must be synchronized with `TempleOS/MODERNIZATION/MASTER_TASKS.md` and `temple-sanhedrin/LOOP_PROMPT.md`.
- `TempleOS/MODERNIZATION/LOOP_PROMPT.md:46-49` says changes must update or block across `TempleOS/MODERNIZATION/MASTER_TASKS.md`, `holyc-inference/MASTER_TASKS.md`, and `temple-sanhedrin/LOOP_PROMPT.md`.
- `holyc-inference/tests/test_trinity_policy_sync_gate.py:46-54` asserts the checker has environment overrides and selected check IDs, but does not assert that `holyc-inference/MASTER_TASKS.md` or `TempleOS/MODERNIZATION/LOOP_PROMPT.md` are scanned by default.

Assessment:
The checker is useful, but its default doc set is asymmetric. It checks holyc's loop prompt but not holyc's master task plan; it checks TempleOS's master task plan but not TempleOS's loop prompt. Both omitted files are controlling docs for agents.

Risk:
A policy clause can drift in `holyc-inference/MASTER_TASKS.md` or `TempleOS/MODERNIZATION/LOOP_PROMPT.md` while the current checker still reports `drift=false`.

Required remediation:
- Expand the default scan set or split checks by doc class: `loop_prompt`, `master_tasks`, and `laws`.
- Add test coverage asserting that all default controlling docs are included.
- Emit the scanned document list in a stable JSON array, not only as three scalar summary fields.

## Finding WARNING-004: Sanhedrin control path in holyc checker follows local main, not this audit branch

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- `holyc-inference/automation/check-trinity-policy-sync.sh:12` defaults `SANHEDRIN_DOC` to `${HOME}/Documents/local-codebases/temple-sanhedrin/LOOP_PROMPT.md`.
- The local default Sanhedrin repo exists at `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-sanhedrin` on branch `main`.
- This audit is being committed to `/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55` on branch `codex/sanhedrin-gpt55-audit`.

Assessment:
This is expected for the live builder gate, but it is a coverage caveat for retroactive audit branches. A Sanhedrin policy refinement can exist on the gpt-5.5 audit branch without being visible to the holyc parity gate until merged to the local main Sanhedrin worktree.

Risk:
Historical audit findings can recommend policy changes that appear complete in the audit branch but are invisible to the builder-side parity checker.

Required remediation:
- Document the canonical Sanhedrin doc source for builder gates versus audit branches.
- When audit-branch policy refinements are intended to affect builders, merge or mirror them before treating Trinity parity as enforced.
- Optionally make the checker print the Sanhedrin repo branch and commit alongside the doc path.

## Finding INFO-001: Current direct Trinity parity check passes with the committed policy signatures

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- Direct read-only run of `INFERENCE_GATE_ROOT=/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/check-trinity-policy-sync.sh` emitted `status=pass`, `drift=false`, `passed=21`, `failed=0`.
- The same checker also passed when `TRINITY_SANHEDRIN_DOC` was explicitly pointed at `/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55/LOOP_PROMPT.md`.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:51-54`, `holyc-inference/LOOP_PROMPT.md:21-36`, and `temple-sanhedrin/LOOP_PROMPT.md:47-83` contain the expected secure-local, dev-local, quarantine/hash, IOMMU/Book-of-Truth, attestation/policy-digest, and Trinity drift signatures.

Assessment:
This audit does not identify a current substantive policy mismatch in the checked signatures. It identifies that the enforcement shape is weaker than the cross-repo doctrine claims.

## Non-Findings

- No TempleOS guest networking stack, NIC driver, socket, TCP/IP, UDP, TLS, DHCP, DNS, HTTP, or remote runtime service was found or executed by this audit.
- No WS8 networking task was executed.
- No TempleOS or holyc-inference source file was modified.
- No QEMU or VM command was run; therefore no VM launch arguments were needed beyond this report's read-only evidence review.

## Read-Only Verification Commands

- `git -C /Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55 rev-parse HEAD`
- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD`
- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD`
- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/temple-sanhedrin rev-parse HEAD`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/check-trinity-policy-sync.sh | sed -n '1,140p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/inference-secure-gate.sh | sed -n '1,140p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_trinity_policy_sync_gate.py | sed -n '1,220p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/enforce-templeos-airgap.sh | sed -n '1,120p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/LOOP_PROMPT.md | sed -n '40,70p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '40,58p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/LOOP_PROMPT.md | sed -n '1,90p'`
- `rg -n "check-trinity-policy-sync|trinity-policy-sync|inference-secure-gate|north-star-e2e|check-no-compound" -S .github automation Makefile package.json pyproject.toml`
- `find /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS -path '*/check-trinity-policy-sync.sh' -print`
