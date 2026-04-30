# Generated Cache Artifact Compliance Backfill

Timestamp: 2026-04-30T20:31:31+02:00

Audit angle: compliance backfill for generated/cache artifacts under Law 4 Identifier Compounding Ban and Law 5 North Star Discipline.

Scope:
- TempleOS head: `0fbfde44cc675261df1f4051a0b6d101e4f4bd9a`
- holyc-inference head: `2799283c9554bea44c132137c590f02034c8f726`
- Sanhedrin audit repo head at start: `86857b4687eada8f9b83d87432b736434335c4e5`

The TempleOS and holyc-inference repositories were inspected read-only. No trinity source code was modified. No live liveness watching, restart, QEMU/VM command, WS8 networking task, package-network action, or remote runtime action was executed.

## Summary

Both builder histories contain tracked generated Python cache artifacts, and holyc-inference also currently tracks loop logs. The current holyc-inference head fails the identifier-compounding gate because a generated `.pyc` path is long and over-tokenized. TempleOS currently passes the gate, but still has one tracked `__pycache__` artifact, which means the generated-artifact hygiene invariant is not consistently enforced across the trinity.

Findings: 4 total.

## Findings

### CRITICAL-1: holyc-inference current head violates Law 4 through a generated `.pyc`

Evidence:
- Current tracked generated/cache files in holyc-inference: 3.
- `tests/__pycache__/test_gguf_model_info_build.cpython-314-pytest-9.0.3.pyc` is tracked at head.
- `bash automation/check-no-compound-names.sh HEAD` reports:
  - `filename too long (51 > 40)`
  - `filename has too many tokens (8 > 5)`

Impact: the Law 4 Identifier Compounding Ban applies to both builder agents and has no test-cache exception. This generated file is also not durable inference runtime source or meaningful validation evidence.

### WARNING-2: holyc-inference history shows systemic cache churn, not a one-off slip

Evidence:
- Generated/cache/log path history across all refs: 1,393 commits, 1,738 unique paths, and 5,648 name-status entries.
- Status mix: 1,938 additions, 1,083 modifications, and 2,627 deletions.
- Recent additions include `bench/__pycache__/airgap_audit.cpython-314.pyc`, `bench/__pycache__/bench_result_index.cpython-314.pyc`, `bench/__pycache__/qemu_prompt_bench.cpython-314.pyc`, and many `tests/__pycache__/...pyc` artifacts.

Impact: repeated cache churn inflates commit history and can hide real source changes inside generated binary noise. It also creates a recurring Law 4 regression surface because pytest cache filenames naturally inherit long test names and dependency version tokens.

### WARNING-3: TempleOS history also tracked generated cache artifacts after the compounding-ban era

Evidence:
- Generated/cache/log path history across all refs: 35 commits, 8 unique paths, and 54 name-status entries.
- Status mix: 9 additions, 43 modifications, and 2 deletions.
- Current tracked generated/cache files in TempleOS: 1, `automation/__pycache__/bookoftruth-smoke-dashboard.cpython-314.pyc`.
- Current `bash automation/check-no-compound-names.sh HEAD` reports OK, so this is not an active Law 4 failure at head.

Impact: TempleOS currently avoids the identifier-length failure, but still carries a generated Python cache artifact. That weakens Law 5 evidence quality by preserving interpreter output rather than source/spec/test intent.

### WARNING-4: holyc-inference currently tracks loop logs as repository artifacts

Evidence:
- Current holyc-inference generated/log matches include:
  - `automation/codex-inference-loop.log`
  - `codex-inference-loop.log`
  - `tests/__pycache__/test_gguf_model_info_build.cpython-314-pytest-9.0.3.pyc`

Impact: loop logs are execution byproducts, not source-of-truth implementation or stable validation fixtures. Keeping them tracked makes repository state depend on local loop runtime noise and increases review load for future retroactive audits.

## Source Counts

| Metric | TempleOS | holyc-inference |
| --- | ---: | ---: |
| Current tracked generated/cache/log files | 1 | 3 |
| Commits touching generated/cache/log paths | 35 | 1,393 |
| Unique generated/cache/log paths in history | 8 | 1,738 |
| Historical generated/cache/log entries | 54 | 5,648 |
| Historical additions | 9 | 1,938 |
| Historical modifications | 43 | 1,083 |
| Historical deletions | 2 | 2,627 |
| Current identifier-compounding gate | PASS | FAIL |

## Recommended Remediation

- Remove tracked `__pycache__/`, `*.pyc`, and loop log artifacts from both builder repos.
- Add or verify ignore coverage for `__pycache__/`, `*.py[cod]`, `.pytest_cache/`, and loop log files.
- Make `automation/check-no-compound-names.sh HEAD` a mandatory pre-commit or pre-push gate for both builder loops.
- Add a generated-artifact smoke check that fails on tracked interpreter caches and runtime logs, separate from the identifier-length gate.

## Verification Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS ls-files '**/__pycache__/**' '*.pyc' '*.pyo' '*.o' '*.obj' '*.so' '*.dylib' '*.dll' '*.exe' '*.bin' '*.iso' '*.img' '*.qcow2' '*.tmp' '*.log'
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference ls-files '**/__pycache__/**' '*.pyc' '*.pyo' '*.o' '*.obj' '*.so' '*.dylib' '*.dll' '*.exe' '*.bin' '*.iso' '*.img' '*.qcow2' '*.tmp' '*.log'
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS --no-pager log --all --format='COMMIT %H' --name-status -- '**/__pycache__/**' '*.pyc' '*.pyo' '*.o' '*.obj' '*.so' '*.dylib' '*.dll' '*.exe' '*.bin' '*.iso' '*.img' '*.qcow2' '*.tmp' '*.log'
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference --no-pager log --all --format='COMMIT %H' --name-status -- '**/__pycache__/**' '*.pyc' '*.pyo' '*.o' '*.obj' '*.so' '*.dylib' '*.dll' '*.exe' '*.bin' '*.iso' '*.img' '*.qcow2' '*.tmp' '*.log'
bash automation/check-no-compound-names.sh HEAD
```
