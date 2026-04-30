# Cross-Repo Audit: Law Enforcement Surface Drift

Timestamp: 2026-04-30T04:34:16+02:00

Audit angle: cross-repo invariant check for whether TempleOS and holyc-inference enforce the same LAWS.md surfaces for identifier compounding, air-gap QEMU launch policy, HolyC purity, and `secure-local` control-plane assumptions.

Repos reviewed:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55` at `6d55f2acd2abe0b8b3a503766a65f52a69845123`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55` at `a70776642a09de7ed01eb75aaaebbdd3243f84c2`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit`

No TempleOS or holyc-inference source file was modified. No QEMU, VM, WS8 networking, networking, or package-download command was executed.

## Expected Cross-Repo Invariant

Both builder repos should expose the same enforceable law surfaces:

- The identifier-compounding ban should fail current offending commits consistently in both repos.
- QEMU air-gap policy should converge on preferred `-nic none`, with `-net none` only treated as a documented legacy fallback.
- Core runtime/source paths should remain HolyC-only, with host tools isolated outside core runtime paths.
- `secure-local` trust decisions should remain TempleOS-controlled and Book-of-Truth gated, while holyc-inference remains the worker plane.

Finding count: 4 findings: 1 critical, 3 warnings.

## Findings

### CRITICAL-001: holyc-inference latest commit fails the repository's own compound-name law gate

Applicable laws:
- Law 4: Identifier Compounding Ban
- Law 5: North Star Discipline

Evidence:
- `bash automation/check-no-compound-names.sh HEAD` in `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55` reports:
  - `VIOLATION: filename too long (44 > 40): bench/results/bench_result_index_freshness_failures_latest.csv`
  - `VIOLATION: filename has too many tokens (6 > 5): bench/results/bench_result_index_freshness_failures_latest.csv`
- `git show --name-only HEAD` shows the offending artifact was added by current commit `a70776642a09de7ed01eb75aaaebbdd3243f84c2`.
- The same gate passes in the TempleOS worktree at current HEAD.

Assessment:
The cross-repo enforcement contract is split: TempleOS current HEAD is clean under the diff-based gate, while holyc-inference current HEAD ships a current-commit violation. This is not merely historical backlog; it is the exact gate LAWS.md requires builders to run before committing.

Required remediation:
- Rename or remove the current offending holyc-inference artifact and any code paths that regenerate it under the compound name.
- Re-run `bash automation/check-no-compound-names.sh HEAD` before the next inference commit is accepted as compliant.

### WARNING-001: repo-wide compound-name debt is large enough to hide new violations

Applicable laws:
- Law 4: Identifier Compounding Ban
- Law 5: No Busywork / North Star Discipline

Evidence:
- A read-only filename scan found 1,032 over-limit filenames in TempleOS and 1,530 in holyc-inference when checking all tracked worktree files outside `.git` and `__pycache__`.
- Examples in TempleOS include long generated smoke scripts under `automation/`.
- Examples in holyc-inference include long Python test names under `tests/`.
- Both repos' `automation/check-no-compound-names.sh` only checks files touched by the selected revision, not the repo-wide backlog.

Assessment:
The diff-based gate is useful for preventing new violations, but the existing surface is so noisy that cross-repo review cannot rely on simple repo-wide scans to distinguish active regression from historical debt. This creates audit ambiguity and makes new law violations easier to miss unless Sanhedrin records whether each finding is current-commit or pre-existing.

Required remediation:
- Keep current-commit enforcement strict.
- Add a separate baseline report for pre-existing compound-name debt so new names can be classified as regression without requiring an immediate whole-repo rename.

### WARNING-002: TempleOS still reports legacy `-net none` fallback exposure while holyc-inference treats legacy `-net` as benchmark drift

Applicable laws:
- Law 2: Air-Gap Sanctity

Evidence:
- TempleOS `automation/qemu-headless.sh` chooses `-nic none` when available and falls back to `-net none` when `-nic` is absent.
- TempleOS `automation/qemu-smoke.sh` follows the same preferred/fallback pattern.
- TempleOS `MODERNIZATION/lint-reports/qemu-legacy-fallback-report-latest.md` reports `Gate: FAIL`, `Legacy fallback files: 2`, `Legacy-only files: 2`, and `QEMU launcher files using legacy -net none without preferred evidence: 2`.
- holyc-inference `bench/README.md` states benchmark artifacts should not add legacy `-net none`; the launcher injects `-nic none`, and downstream audits treat legacy `-net` flags as drift.
- holyc-inference `bench/qemu_source_audit.py` scans QEMU commands and treats non-`none` network backends/devices as violations while excluding generated result folders from source scans.

Assessment:
This is not an immediate air-gap breach: both repos reject network-capable QEMU options and explicitly disable guest networking. The drift is in policy semantics. TempleOS still carries a compatibility fallback, while holyc-inference increasingly treats legacy `-net` presence as undesirable artifact drift. Cross-repo audit results can therefore disagree on the same safe command shape.

Required remediation:
- Decide whether `-net none` is acceptable only as runtime fallback in launchers, or also acceptable as documented/generated evidence.
- Encode that same distinction in both repositories' QEMU source/audit reports.

### WARNING-003: `secure-local` policy exists in both repos, but TempleOS control-plane proof remains policy text rather than a shared executable contract

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity
- Law 9: Resource Supremacy / Crash on Log Failure

Evidence:
- TempleOS `MODERNIZATION/LOOP_PROMPT.md` defines `secure-local` as default, requires Book-of-Truth preservation for inference/model/GPU tasks, keeps TempleOS as the trust plane, and bans GPU/profile policy changes unless Trinity policy parity is preserved.
- holyc-inference `LOOP_PROMPT.md` defines `secure-local` as default, says every model remains untrusted until quarantine plus hash-manifest verification, and forbids GPU dispatch unless IOMMU plus Book-of-Truth GPU hooks are active.
- holyc-inference `src/runtime/profile.HC` implements a secure-local default profile and explicit dev-local opt-in.
- holyc-inference `src/gpu/policy.HC` denies GPU dispatch unless IOMMU and Book-of-Truth DMA/MMIO/dispatch hooks are active.

Assessment:
The written contracts are aligned and holyc-inference has runtime gates, but the cross-repo join is still implicit: the worker code accepts hook/activity flags and profile IDs, while TempleOS owns the authoritative Book-of-Truth and hardware-proximity evidence. Sanhedrin cannot yet verify one shared executable proof tuple that binds a worker-side dispatch allow decision to a specific TempleOS Book-of-Truth append/proximity record.

Required remediation:
- Define a shared `SecureLocalProof` tuple for GPU/model dispatch evidence: profile, policy digest, IOMMU status, Book-of-Truth DMA/MMIO/dispatch hook state, TempleOS log sequence, entry hash, and failure behavior.
- Treat worker-side `*_enabled` flags as insufficient unless joined to TempleOS append evidence.

## Non-Findings

- No active network-capable QEMU invocation was executed or found in the reviewed launch policy surfaces.
- holyc-inference core runtime scan found no `.c`, `.cpp`, `.rs`, `.go`, `.py`, `.js`, or `.ts` files under `src/`.
- TempleOS core scan found no source-language impurity in core paths; `0000Boot/0000Kernel.BIN.C` is a binary DOS/COM artifact despite the `.C` suffix, so it should be tracked separately from C source detections.
- The holyc-inference float scan over `.HC` sources produced comments and GGUF metadata references, not runtime tensor float operations.

## Evidence Commands

- `git -C /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55 rev-parse HEAD`
- `git -C /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55 rev-parse HEAD`
- `bash automation/check-no-compound-names.sh HEAD` in both builder worktrees
- `python3` read-only scan of filename length/token counts under both builder worktrees
- `find Kernel Adam Apps Compiler 0000Boot ...` and `find src ...` for non-HolyC source-language files in core paths
- `rg -n "\b(F32|F64|float|double)\b|\b(fadd|fsub|fmul|fdiv|fld|fstp)\b" src --glob '*.HC' -S`
- `nl -ba automation/qemu-headless.sh | sed -n '1,180p'`
- `nl -ba automation/qemu-smoke.sh | sed -n '1,140p'`
- `nl -ba MODERNIZATION/lint-reports/qemu-legacy-fallback-report-latest.md | sed -n '1,80p'`
- `nl -ba bench/README.md | sed -n '1,80p'`
- `nl -ba bench/qemu_prompt_bench.py | sed -n '1,240p'`
- `nl -ba src/runtime/profile.HC | sed -n '1,180p'`
- `nl -ba src/gpu/policy.HC | sed -n '1,220p'`
