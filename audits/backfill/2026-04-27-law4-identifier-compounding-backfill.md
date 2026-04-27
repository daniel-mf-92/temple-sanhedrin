# Law 4 Identifier Compounding Backfill

Timestamp: 2026-04-27T14:57:36Z

Scope: compliance backfill for the later `LAWS.md` rule titled "Law 4 -- Identifier Compounding Ban" across `TempleOS` and `holyc-inference`.

Inputs:
- TempleOS repo: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS`
- holyc-inference repo: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`
- TempleOS rule-introduction commit: `5e92e74c8c1b1b92377c821a93feb24cf89adf42`
- holyc-inference rule-introduction commit: `d433483b80a0d1beb4e7598503d42fe51d643b1e`

Method:
- Read-only git history scan; no trinity source files were modified.
- Checked the same measurable limits encoded by `automation/check-no-compound-names.sh`: basename without extension longer than 40 chars, basename with more than 5 hyphen/underscore tokens, and added function-like identifiers in `.HC`, `.sh`, and `.py` longer than 40 chars.
- The textual rule also forbids "existing-name + suffix" chained helpers. That clause is not implemented by the current checker and was not scored mechanically here.

## Executive Summary

Finding count: 8

Backfill score, pre-rule history only:

| Repo | Pre-rule commits | Violating commits | Clean commits | Commit compliance score | Mechanical violations |
|---|---:|---:|---:|---:|---:|
| TempleOS | 1,948 | 1,371 | 577 | 29.6% | 4,255 |
| holyc-inference | 2,358 | 1,816 | 542 | 23.0% | 33,722 |
| Combined | 4,306 | 3,187 | 1,119 | 26.0% | 37,977 |

Post-rule snapshot:

| Repo | Rule commit clean? | Post-rule commits scanned | Post-rule violating commits | Post-rule compliance score | Post-rule violations |
|---|---:|---:|---:|---:|---:|
| TempleOS | No | 6 | 3 | 50.0% | 6 |
| holyc-inference | Yes | 7 | 5 | 28.6% | 36 |

## Findings

1. CRITICAL: TempleOS pre-rule history was already dominated by identifier-compounding violations. 1,371 of 1,948 commits violated the measurable rule subset, with 4,255 total mechanical hits.

2. CRITICAL: holyc-inference pre-rule history was more saturated than TempleOS. 1,816 of 2,358 commits violated the measurable rule subset, with 33,722 total mechanical hits.

3. CRITICAL: TempleOS introduced the compounding ban in a commit that itself violated the ban. Commit `5e92e74c8c1b1b92377c821a93feb24cf89adf42` added or modified `automation/sched-lifecycle-invariant-window-code-cq-depth-check.sh` and `.deprecated.bak`, producing 4 filename length/token violations.

4. CRITICAL: TempleOS continued to introduce measurable violations after the ban. Post-rule violating commits were `a938842f704f63437dd5c92dd5f850d744c5a07f`, `a4548151871cc54104179dafdd7d889d9c3cec1e32`, and `c6b70f17ede58ab3ba5906941a655c4fb8a26002`.

5. CRITICAL: holyc-inference continued to introduce measurable violations after the ban. Post-rule violating commits were `9e836f893b7f486cea81f4f609ca54ba4dee2d0b`, `9d34b45341497be3f8258388c44adf536026d15c`, `a2e460b02962faac6b2876ac156078ecb0c69db2`, `12d6fe3b7a105ef22ccd980a21bac66252d7f92e`, and `973bf85029efe85cc35890897e3f9faf5eb5b4b4`.

6. WARNING: The biggest TempleOS pre-rule outliers show runaway chained helper naming. Maximum filename length was 203 chars in `automation/sched-lifecycle-invariant-suite-mask-clamp-status-coverage-window-live-digest-status-window-trend-queue-depth-suite-qemu-compile-batch-queue-depth-suite-smoke-queue-depth-suite-smoke-queue-depth-v2-smoke.sh`; maximum token count was 34 in another `sched-lifecycle...queue-depth...` automation script; maximum identifier length was 148 chars in `Kernel/KExts.HC`.

7. WARNING: The biggest holyc-inference pre-rule outliers show repeated suffix accretion in GPU security/perf audit work. Maximum filename length was 252 chars, maximum filename token count was 39, and maximum identifier length was 363 chars across GPU security/perf fast-path audit tests and helpers.

8. WARNING: The current checker has a backfill blind spot. It tests changed paths against the current worktree with `[[ -f "$f" ]]`, so a historical commit can be missed if the path no longer exists at HEAD; it also does not implement the "existing-name + suffix" clause. The mechanical scores above avoid that first blind spot by parsing git history directly, but the enforcement script still needs hardening.

## Violation Distribution

TempleOS pre-rule:
- Filename length: 1,285
- Filename token count: 1,295
- Identifier length: 1,675
- Top files by hit count: `Kernel/BookOfTruth.HC` 717, `Kernel/KExts.HC` 426, `Kernel/Sched.HC` 271, `Kernel/BookOfTruthSerialCore.HC` 253

holyc-inference pre-rule:
- Filename length: 3,632
- Filename token count: 3,801
- Identifier length: 26,289
- Top files by hit count: `src/gpu/security_perf_matrix.HC` 1,087, `src/model/attention.HC` 655, `tests/test_gguf_tensor_data_base.py` 435, `src/tokenizer/bpe.HC` 318

## Post-Rule Examples

TempleOS:
- `a938842f704f63437dd5c92dd5f850d744c5a07f`: `automation/sched-lifecycle-invariant-digest-window-rows-clamp-status-digest-pair-window-tail-helper-smoke.sh` is 94 chars and 14 tokens.
- `c6b70f17ede58ab3ba5906941a655c4fb8a26002`: `Kernel/Sched.HC` added `SchedLifecycleInvariantDigestWindowRowsClampStatusDigestPairWindowTailDigest` at 76 chars.

holyc-inference:
- `9e836f893b7f486cea81f4f609ca54ba4dee2d0b`: `src/gpu/security_perf_matrix.HC` added a GPU security/perf identifier up to 252 chars.
- `9d34b45341497be3f8258388c44adf536026d15c`: committed `tests/__pycache__/test_gpu_security_perf_fast_path_switch_batch_audit_q64_iq1782.cpython-314-pytest-9.0.3.pyc`, 87 chars and 14 tokens.
- `12d6fe3b7a105ef22ccd980a21bac66252d7f92e`: `src/model/inference.HC` added `InferenceBookOfTruthTokenEventEmitChecked`, 41 chars.

## Recommendation

Treat the identifier-compounding ban as a high-value law with a large historical backlog, not as a narrow recent regression. Harden `automation/check-no-compound-names.sh` to evaluate commit contents instead of HEAD worktree files, ignore generated caches such as `__pycache__`, and add a deterministic heuristic for suffix accretion before relying on it for future enforcement or retroactive scoring.
