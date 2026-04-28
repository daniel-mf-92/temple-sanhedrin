# Cross-Repo Invariant Audit: Identifier Compounding Gate Drift

Timestamp: 2026-04-28T02:40:22Z

Auditor: gpt-5.5 sibling, retroactive/deep audit scope

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source code was modified. No live liveness checks were performed. No QEMU or VM command was executed.

Repos examined:
- TempleOS HEAD: `f140a8ab65e67b7acf3c4f44d00f650ee1512d6a`
- holyc-inference HEAD: `b8a4fc8b7dd7cb2175ff3e4e8f051a7d4b19ca7d`
- temple-sanhedrin branch: `codex/sanhedrin-gpt55-audit`

## Executive Summary

Found 4 findings: 1 critical, 3 warnings.

The identifier-compounding rule is intended to be a shared builder invariant, but the current enforcement surfaces do not agree. TempleOS now exempts modified legacy filenames from its local checker, holyc-inference does not, and both local checkers can report `OK` at clean `HEAD` while large tracked legacy backlogs remain in the repository. This does not assert new source-code impurity or air-gap violation; it records enforcement drift that affects future retroactive scoring and auto-revert reliability.

## Finding CRITICAL-001: TempleOS local checker exempts modified legacy compound filenames

Applicable law:
- Law 4, Identifier Compounding Ban: function/script/file names longer than 40 characters or more than 5 hyphen/underscore tokens are forbidden.

Evidence:
- TempleOS `automation/check-no-compound-names.sh:27` builds `new_files` from added paths only.
- TempleOS `automation/check-no-compound-names.sh:43-53` says "Policy applies to new files; allow edits to legacy long-name files" and only runs filename length/token checks when `is_new_file` is true.
- holyc-inference `automation/check-no-compound-names.sh:21-34` checks every changed file basename, regardless of added vs modified status.
- Sanhedrin `automation/enforce-laws.sh:54-62` also checks every changed file from `git diff-tree --name-only`, not only added files.

Assessment:
TempleOS, holyc-inference, and Sanhedrin no longer share the same measurable Law 4 contract. A TempleOS builder can modify an overlong legacy automation filename and pass its local checker, while holyc-inference and Sanhedrin would treat the same changed path shape as a violation.

Impact:
This makes builder-local validation unreliable as evidence in retro reports. It also creates a policy loophole for continuing to maintain suffix-chained legacy scripts instead of replacing them with short-name wrappers.

## Finding WARNING-001: Clean HEAD checks can report OK despite large current tracked violation backlogs

Evidence:
- In TempleOS, `bash automation/check-no-compound-names.sh HEAD` returned `check-no-compound-names: OK` at HEAD `f140a8ab65e67b7acf3c4f44d00f650ee1512d6a`.
- In holyc-inference, `bash automation/check-no-compound-names.sh HEAD` returned `check-no-compound-names: OK` at HEAD `b8a4fc8b7dd7cb2175ff3e4e8f051a7d4b19ca7d`.
- A tracked-file basename scan found 987 TempleOS `automation/` files over the 40-character or 5-token threshold.
- The same scan found 1,441 holyc-inference `tests/` files over the 40-character or 5-token threshold.

Assessment:
The local checker name and output read like repository compliance, but the implementation is commit-delta oriented. On a clean tree, `HEAD` can pass while the repository still contains a large legacy Law 4 backlog.

Impact:
Audit logs that cite only `check-no-compound-names: OK` can overstate actual repository compliance. Future reports should label this as "changed-diff check passed" unless they also run a full-tree debt scan.

## Finding WARNING-002: Sanhedrin auto-enforcement scans branch names that miss current holyc-inference HEAD

Evidence:
- Sanhedrin `automation/enforce-laws.sh:39-41` selects branches matching `codex/(modernization|inference)-loop`.
- TempleOS has `codex/modernization-loop` checked out.
- holyc-inference is currently on `main`; available local/remotes include `main`, `origin/main`, and `codex/holyc-gpt55-bench`, but no `codex/inference-loop` branch.

Assessment:
The current holyc-inference branch shape does not match the enforcement selector, so automatic Sanhedrin Law 4/Law 6 scanning can skip the active inference HEAD even when retro reports continue auditing commits on `main`.

Impact:
The trinity contract says both builder agents are under audit, but the auto-enforcement branch filter is not aligned with the current inference repository topology.

## Finding WARNING-003: The rule has no shared full-tree remediation mode

Evidence:
- TempleOS local checker has an added-file exemption for filenames.
- holyc-inference local checker checks changed filenames, but not a full-tree inventory by default.
- Sanhedrin auto-enforcement checks only recent commits on selected branches.
- Existing tracked debt remains high in both repos: 987 TempleOS automation paths and 1,441 holyc-inference test paths exceed the measurable Law 4 thresholds.

Assessment:
There is no common mode that answers "is this repository currently Law 4 clean?" across TempleOS and holyc-inference. The existing tools answer narrower questions: changed-diff compliance for a commit or recent branch-window enforcement.

Recommended remediation:
- Add a `--diff-only` vs `--full-tree` mode to both builder checkers.
- Make the default output state exactly what was checked, for example `changed-diff OK` or `full-tree violations=N`.
- Keep any legacy-debt exemption in a checked-in allowlist with path, reason, owner, and replacement target, not as an unconditional "modified file" bypass.
- Align Sanhedrin branch discovery with current active branches or consume a repo-local active-branch manifest.

## Non-Findings

- No TempleOS or holyc-inference source files were edited by this audit.
- No guest networking stack, socket/TCP/IP/UDP/DNS/DHCP/HTTP/TLS code was inspected as newly added in this audit angle.
- No QEMU or VM command was executed; the air-gap safety requirement was preserved.

## Read-Only Verification Commands

- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/check-no-compound-names.sh | sed -n '1,110p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/check-no-compound-names.sh | sed -n '1,90p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55/automation/enforce-laws.sh | sed -n '35,78p'`
- `bash automation/check-no-compound-names.sh HEAD` in TempleOS and holyc-inference
- `git ls-files ... | awk ...` tracked basename scans in TempleOS and holyc-inference
- `git branch -a --list '*codex/*' '*main'` in TempleOS and holyc-inference
