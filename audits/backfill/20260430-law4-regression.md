# Law 4 Regression Backfill Continuation

Timestamp: 2026-04-30T12:20:05+02:00

Scope: compliance backfill continuation for the appended `LAWS.md` rule titled "Law 4 -- Identifier Compounding Ban", extending the previous `2026-04-29-law4-post-backfill-regression-update.md` baselines to current committed heads.

Inputs:
- TempleOS repo: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS`
- holyc-inference repo: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`
- TempleOS baseline from prior backfill: `d84df3da3e8c241f43882f76493e1ae5a2f03b9e`
- TempleOS HEAD scanned: `2e3b9750875e609cbe8495e03fb26087e78ee5f1`
- holyc-inference baseline from prior backfill: `485af0ea41a239c8393542d6e0e2fc5944f30f53`
- holyc-inference HEAD scanned: `2799283c9554bea44c132137c590f02034c8f726`

Method:
- Read-only git history scan; no TempleOS or holyc-inference files were modified.
- No QEMU or VM command was executed.
- TempleOS had uncommitted live work in its worktree, so this audit ignored the worktree and scanned only committed revisions in `d84df3da..HEAD`.
- For each commit in scope, scanned added/modified paths plus added function-like identifiers in `.HC`, `.sh`, and `.py` diffs.
- Measured the mechanical Law 4 limits: basename without extension longer than 40 characters, basename with more than 5 hyphen/underscore tokens, and added function-like identifiers longer than 40 characters.
- Deleted files were ignored because this continuation scores introduced or modified surface area.

## Executive Summary

Finding count: 3

| Repo | Commits scanned | Violating commits | Clean commits | Compliance score | Mechanical violations |
| --- | ---: | ---: | ---: | ---: | ---: |
| TempleOS | 9 | 0 | 9 | 100.0% | 0 |
| holyc-inference | 1 | 1 | 0 | 0.0% | 3 |
| Combined | 10 | 1 | 9 | 90.0% | 3 |

Violation type totals:

| Repo | Filename length | Filename tokens | Identifier length |
| --- | ---: | ---: | ---: |
| TempleOS | 0 | 0 | 0 |
| holyc-inference | 1 | 1 | 1 |
| Combined | 1 | 1 | 1 |

## Findings

### 1. WARNING: holyc-inference committed a generated cache artifact that violates Law 4 filename limits

Commit `2799283c9554bea44c132137c590f02034c8f726` (`feat(inference): codex iteration 20260430-025722`, committed 2026-04-30T03:00:56+02:00) added `tests/__pycache__/test_gguf_model_info_build.cpython-314-pytest-9.0.3.pyc`.

Evidence:
- Basename without extension: `test_gguf_model_info_build.cpython-314-pytest-9.0.3`
- Length: 51 characters; limit: 40
- Hyphen/underscore token count: 8; limit: 5
- `git show --name-status 2799283c...` reports this path as added.

Impact: the artifact is host-side Python bytecode, not HolyC runtime code, but it is a committed generated file and a direct mechanical Law 4 regression. It also makes the repo's own `automation/check-no-compound-names.sh HEAD` fail at current head.

### 2. WARNING: holyc-inference added an over-limit Python test identifier

The same commit added `tests/test_gguf_model_info_build.py` with `def test_source_contains_ws2_05_entrypoint_and_guards()`.

Evidence:
- Identifier: `test_source_contains_ws2_05_entrypoint_and_guards`
- Length: 49 characters; limit: 40
- File: `tests/test_gguf_model_info_build.py`

Impact: this is host-side test code, so it is not an integer-runtime purity violation. It is still a direct Law 4 naming regression and follows the same pattern as the prior holyc-inference finding in `485af0ea`, where Python tests exceeded the 40-character identifier limit.

### 3. INFO: TempleOS remained clean across the continuation window

The 9 TempleOS commits from `d84df3da3e8c241f43882f76493e1ae5a2f03b9e..2e3b9750875e609cbe8495e03fb26087e78ee5f1` introduced no measurable Law 4 filename or identifier violations under this scan.

Evidence commits:
- `e4543e10` through `2e3b9750`, committed from 2026-04-30T00:38:09+02:00 through 2026-04-30T08:06:50+02:00.

Impact: TempleOS has now stayed clean across two consecutive post-backfill Law 4 continuation windows in the committed history, despite earlier historical saturation.

## Evidence Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-list --reverse d84df3da3e8c241f43882f76493e1ae5a2f03b9e..HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-list --reverse 485af0ea41a239c8393542d6e0e2fc5944f30f53..HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference show --name-status --oneline 2799283c9554bea44c132137c590f02034c8f726
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference diff 2799283c9554bea44c132137c590f02034c8f726^ 2799283c9554bea44c132137c590f02034c8f726 -- tests/test_gguf_model_info_build.py
```
