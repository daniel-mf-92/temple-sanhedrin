# Law 4 Post-Backfill Regression Update

Timestamp: 2026-04-29T23:50:43+02:00

Scope: compliance backfill update for the later `LAWS.md` rule titled "Law 4 -- Identifier Compounding Ban", limited to commits after the previous post-rule backfill heads.

Inputs:
- TempleOS repo: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS`
- holyc-inference repo: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`
- TempleOS baseline from prior backfill: `e868ba65878b282ff5b2d2464b6bd95cb56e6c76`
- TempleOS HEAD scanned: `d84df3da3e8c241f43882f76493e1ae5a2f03b9e`
- holyc-inference baseline from prior backfill: `ce09228422dae06e86feb84925d51df88d67821b`
- holyc-inference HEAD scanned: `485af0ea41a239c8393542d6e0e2fc5944f30f53`

Method:
- Read-only git history scan; no trinity source files were modified.
- No QEMU or VM commands were executed.
- For each commit in `baseline..HEAD`, scanned added/modified paths and added function-like identifiers in `.HC`, `.sh`, and `.py` diffs.
- Measured the mechanical Law 4 limits: basename without extension longer than 40 characters, basename with more than 5 hyphen/underscore tokens, and added function-like identifiers longer than 40 characters.
- Deleted files were ignored because this backfill scores introduced or modified surface area.

## Executive Summary

Finding count: 1

| Repo | Commits scanned | Violating commits | Clean commits | Compliance score | Mechanical violations |
| --- | ---: | ---: | ---: | ---: | ---: |
| TempleOS | 45 | 0 | 45 | 100.0% | 0 |
| holyc-inference | 1 | 1 | 0 | 0.0% | 1 |
| Combined | 46 | 1 | 45 | 97.8% | 1 |

Violation type totals:

| Repo | Filename length | Filename tokens | Identifier length |
| --- | ---: | ---: | ---: |
| TempleOS | 0 | 0 | 0 |
| holyc-inference | 0 | 0 | 1 |
| Combined | 0 | 0 | 1 |

## Findings

### 1. WARNING: holyc-inference reintroduced one Law 4 identifier-length regression

Commit `485af0ea41a239c8393542d6e0e2fc5944f30f53` (`feat(inference): codex iteration 20260429-064100`, committed 2026-04-29T06:51:01+02:00) added `tests/test_reference_q4_gpt2.py` with `def test_update_with_manual_token_and_emit_json()`.

Evidence:
- Identifier: `test_update_with_manual_token_and_emit_json`
- Length: 43 characters
- Limit: 40 characters
- Path: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_reference_q4_gpt2.py:20`

Impact: this is host-side Python test code, so it is not a HolyC runtime purity violation. It is still a direct mechanical Law 4 regression and shows that the identifier gate is not fully preventing long test names after the earlier Sanhedrin enforcement pass.

Recommended closure: rename the test to a shorter equivalent such as `test_manual_token_emit_json` or update the Law 4 gate to run over added Python test identifiers before commit.

### 2. INFO: TempleOS stayed clean across the post-backfill window

The 45 TempleOS commits from `e868ba65878b282ff5b2d2464b6bd95cb56e6c76..d84df3da3e8c241f43882f76493e1ae5a2f03b9e` introduced no measurable Law 4 filename or identifier violations under this scan.

This is a meaningful improvement over the previous post-rule backfill, which found TempleOS regressions in the earlier rule-adoption window.

## Evidence Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-list --reverse e868ba65878b282ff5b2d2464b6bd95cb56e6c76..HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-list --reverse ce09228422dae06e86feb84925d51df88d67821b..HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference diff 485af0ea41a239c8393542d6e0e2fc5944f30f53^ 485af0ea41a239c8393542d6e0e2fc5944f30f53 -- tests/test_reference_q4_gpt2.py
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_reference_q4_gpt2.py | rg -n "test_update_with_manual_token_and_emit_json|def |class " -C 3
```
