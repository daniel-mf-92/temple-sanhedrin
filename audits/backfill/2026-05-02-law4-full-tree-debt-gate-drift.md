# Law 4 Full-Tree Debt vs Gate Drift

Timestamp: 2026-05-02T05:57:55+02:00

Audit angle: compliance backfill continuation for the appended `LAWS.md` rule titled "Law 4 -- Identifier Compounding Ban", focused on the mismatch between current full-tree debt and the per-commit gate that builders cite as compliance evidence.

Repos reviewed:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `9f3abbf263982bf9344f8973a52f845f1f48d109`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554bea44c132137c590f02034c8f726`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit`

No TempleOS or holyc-inference source file was modified. No live liveness watching, process restart, QEMU command, VM command, WS8 networking task, networking command, package-manager command, or remote-service action was executed.

## Method

- Read `LAWS.md` and the two repos' `automation/check-no-compound-names.sh` implementations.
- Ran the committed identifier-compounding gate at each current head.
- Ran a read-only `git ls-files` full-tree scan for tracked basenames whose stem is longer than 40 chars or has more than 5 hyphen/underscore-separated tokens.
- Separately checked core-path language purity with tracked files only.
- Ignored untracked TempleOS `automation/shared.img.tmp.36266` for scoring because this audit is committed-history/backfill scoped.

## Summary

Finding count: 4 findings: 1 critical, 3 warnings.

| Repo | Head gate result | Tracked over-limit files | Dominant area | Longest tracked basename |
| --- | --- | ---: | --- | ---: |
| TempleOS | `check-no-compound-names: OK` | 1,028 | `automation/` | 206 chars |
| holyc-inference | fails on tracked `__pycache__/*.pyc` | 1,443 | `tests/` | 255 chars |

Core-path foreign-language scan result:

| Repo | Tracked non-HolyC implementation files in core paths |
| --- | ---: |
| TempleOS | 0 |
| holyc-inference | 0 |

## Findings

### CRITICAL-001: holyc-inference current head still fails the exact Law 4 gate

`bash automation/check-no-compound-names.sh HEAD` in holyc-inference exits non-zero at current head `2799283c9554bea44c132137c590f02034c8f726`:

```text
VIOLATION: filename too long (51 > 40): tests/__pycache__/test_gguf_model_info_build.cpython-314-pytest-9.0.3.pyc
VIOLATION: filename has too many tokens (8 > 5): tests/__pycache__/test_gguf_model_info_build.cpython-314-pytest-9.0.3.pyc
```

The offending `.pyc` is tracked by git and was added by the current commit. This remains an active Law 4 failure, not only historical backlog. It also keeps generated interpreter cache output inside the inference repository's committed evidence surface.

Required remediation:
- Remove tracked `tests/__pycache__/test_gguf_model_info_build.cpython-314-pytest-9.0.3.pyc`.
- Ensure `__pycache__/` and `*.pyc` are ignored.
- Re-run `bash automation/check-no-compound-names.sh HEAD` before accepting the inference head as compliant.

### WARNING-001: TempleOS gate passes while 1,028 tracked filenames exceed the written Law 4 limits

TempleOS `bash automation/check-no-compound-names.sh HEAD` reports OK at `9f3abbf263982bf9344f8973a52f845f1f48d109`, but a tracked full-tree scan finds 1,028 filenames over the same measurable limits. The debt is concentrated in `automation/`, with the longest basename at 206 chars and the highest token count at 34.

Representative tracked paths:

```text
automation/sched-lifecycle-invariant-suite-mask-clamp-status-coverage-window-live-digest-status-window-trend-queue-depth-suite-qemu-compile-batch-queue-depth-suite-smoke-queue-depth-suite-smoke-queue-depth-v2-smoke.sh
automation/sched-lifecycle-invariant-suite-mask-clamp-status-top-window-digest-live-queue-depth-suite-qemu-compile-batch-smoke-v2-queue-depth-smoke-queue-depth-v2-suite-smoke-queue-depth-v2-smoke-queue-depth-smoke.sh
```

Assessment: current-commit gating is useful, but audit reports that cite only `check-no-compound-names: OK` should not be worded as whole-repo Law 4 compliance. They prove the current diff passed the checker, not that the repository satisfies the written filename rule.

### WARNING-002: the two repos now enforce different Law 4 scopes

TempleOS' checker only applies filename length/token checks to newly added files and explicitly allows edits to legacy long-name files. holyc-inference checks all files touched by the selected commit, including tracked generated artifacts. Both scripts are named as the same LAWS.md detection mechanism, but they no longer mean the same thing.

Impact: Sanhedrin can produce split verdicts for equivalent evidence:
- TempleOS can edit a legacy over-limit automation script and still pass.
- holyc-inference can fail on a touched over-limit file even when the code change is otherwise host-side test evidence.

Required remediation:
- Define two labels in audit reports: `diff gate passed` and `full-tree debt clean`.
- Either align the scripts or document that TempleOS uses a "new-file-only plus added-identifier" gate while holyc-inference uses a "changed-file" gate.

### WARNING-003: holyc-inference full-tree debt remains too large for current gate output to be self-explanatory

The holyc-inference tracked full-tree scan finds 1,443 over-limit filenames, dominated by `tests/`. The longest tracked basename is 255 chars with 39 hyphen/underscore tokens:

```text
tests/test_gpu_security_perf_fast_path_switch_batch_audit_q64_checked_commit_only_preflight_only_parity_commit_only_preflight_only_parity_commit_only_preflight_only_parity_commit_only_preflight_only_parity_commit_only_preflight_only_parity_commit_only_iq1757.py
```

Law 1 allows Python validation scripts under `tests/`, but Law 4's Identifier Compounding Ban has no `tests/` filename exception. Until a baseline debt file exists, every future Law 4 audit has to rediscover whether a long test name is legacy debt or a new regression.

Required remediation:
- Add a committed baseline allowlist/report for pre-existing over-limit filenames, with repo, path, first-seen commit, and owner workstream.
- Keep new filename violations at zero after the baseline date.
- Prefer short test filenames plus detailed in-file test names over suffix-accreted filenames.

## Non-Findings

- No tracked non-HolyC implementation files were found under TempleOS core paths or holyc-inference `src/`.
- No QEMU or VM command was executed. The air-gap policy was not exercised, and no WS8 networking work was performed.
- The TempleOS current commit's changed files pass its repository-local diff gate; this report is about the difference between that gate and the written full-tree law.

## Evidence Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
bash automation/check-no-compound-names.sh HEAD
git ls-files | awk -F/ '{name=$NF; tmp=name; n=gsub(/[-_]/,"&",tmp)+1; if (length(name)>40 || n>5) print length(name) " " n " " $0}'
git ls-files | rg '(^|/)(src|Kernel|Adam|Apps|Compiler|0000Boot)/.*\.(c|cpp|rs|go|py|js|ts)$|(^|/)(src|Kernel|Adam|Apps|Compiler|0000Boot)/(Makefile|CMakeLists\.txt|Cargo\.toml)$'
sed -n '1,220p' automation/check-no-compound-names.sh
git show --name-status --oneline 2799283c9554bea44c132137c590f02034c8f726
```

