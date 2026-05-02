# Cross-Repo Identifier Contract Drift

Audit timestamp: 2026-05-02T03:43:48+02:00

Audit angle: cross-repo invariant check. This pass compared the checked-in HolyC naming surface in `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` and `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` against the shared LAWS.md identifier-compounding contract. It was read-only for both sibling repos. No TempleOS or holyc-inference source was modified. No live liveness watching, process restart, QEMU/VM command, networking command, or WS8 networking task was executed. The TempleOS guest air-gap was not touched.

Analyzer: `audits/cross/2026-05-02-identifier-contract-drift.py`

## Summary

TempleOS and holyc-inference do not currently share a stable identifier contract. TempleOS `HEAD` passes its delta-oriented `automation/check-no-compound-names.sh HEAD`, but a corpus scan still finds hundreds of checked-in core HolyC functions longer than 40 characters. holyc-inference has the stronger immediate failure: its same-named checker fails at `HEAD` because the latest inference commit tracked a generated `tests/__pycache__/*.pyc` file with a 51-character filename, while its `src/` corpus contains 1,508 HolyC function definitions over the LAWS.md length ceiling.

Finding count: 4 warnings.

## Scope

| Repo | HEAD | Source files scanned | Function defs scanned | Bad source filenames | Bad function names | Checker status |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| TempleOS core | `9f3abbf263982bf9344f8973a52f845f1f48d109` | 316 | 4,585 | 0 | 568 | rc=0 |
| holyc-inference `src/` | `2799283c9554bea44c132137c590f02034c8f726` | 55 | 2,734 | 0 | 1,508 | rc=1 |

Core TempleOS scan prefixes: `Kernel`, `Adam`, `Apps`, `Compiler`, `0000Boot`. Inference scan prefix: `src`. The analyzer intentionally did not execute or compile either repo.

## Findings

### WARNING-001: holyc-inference HEAD fails the shared compound-name checker on a tracked pycache artifact

Law: Identifier Compounding Ban.

Evidence:

- `git diff-tree --no-commit-id --name-status -r HEAD` in holyc-inference shows `A tests/__pycache__/test_gguf_model_info_build.cpython-314-pytest-9.0.3.pyc`.
- `git ls-files tests/__pycache__/test_gguf_model_info_build.cpython-314-pytest-9.0.3.pyc` confirms the pycache artifact is tracked.
- `automation/check-no-compound-names.sh HEAD` in holyc-inference reports filename length `51 > 40` and token count `8 > 5`.

Impact: the inference repo currently assumes generated Python bytecode artifacts can enter history, while the shared Sanhedrin contract forbids that name shape. Even though `tests/` may use Python, generated cache binaries are not a useful validation artifact and create an immediate checker failure.

### WARNING-002: holyc-inference runtime source has large historical identifier debt beyond the LAWS.md ceiling

Law: Identifier Compounding Ban; Law 5, No Busywork.

Evidence:

- The read-only analyzer found 1,508 function definitions in `holyc-inference/src/**/*.HC` with names longer than 40 characters.
- Longest examples include `GPUSecurityPerfFastPathSwitchSecureLocalOverheadBudgetCrossGateSnapshotDigestQ64CheckedCommitOnlyPreflightOnlyParityCommitOnlyPreflightOnlyParityCommitOnlyPreflightOnlyParityCommitOnlyPreflightOnlyParityCommitOnlyPreflightOnlyParityCommitOnlyPreflightOnlyParityCommitOnlyPreflightOnlyParityCommitOnlyPreflightOnlyParityCommitOnlyPreflightOnlyParityCommitOnly` at `src/gpu/security_perf_matrix.HC:36315` and similarly compounded `GPUSecurityPerfMatrixSummary...` variants.

Impact: the inference runtime is drifting away from the same maintainability envelope the TempleOS modernization loop is supposed to enforce. The repeated `CommitOnly`, `PreflightOnly`, and `Parity` suffix chains also match the anti-pattern named by the law, so future work can keep cloning wrappers instead of stabilizing a smaller API.

### WARNING-003: TempleOS passes the checker while checked-in core HolyC still exceeds the same law

Law: Identifier Compounding Ban.

Evidence:

- `automation/check-no-compound-names.sh HEAD` in TempleOS returns `check-no-compound-names: OK`.
- The broader corpus scan found 568 checked-in core HolyC function definitions over 40 characters.
- Examples include `SchedLifecycleInvariantWindowCompareDigestClampStatusAnomalyTailThresholdSweepDigestMatrixShapeBandDigestTailBySourceCoverageStatusDigestClampStatus` at `Kernel/Sched.HC:28175` and `BookTruthSerialLivenessFailStopSuiteBatchLiveAuditTrendSweepWindowCompareDigestDriftTailResetProofWindowDigestReplayWindowLivenessProof` at `Kernel/BookOfTruth.HC:914`.

Impact: the two repos can both be "passing" recent-delta enforcement while still containing incompatible long-name surfaces. This weakens cross-repo assumptions about what HolyC APIs should look like and leaves historical debt invisible unless a full-corpus audit is run.

### WARNING-004: Checker semantics diverge between the repos

Law: Identifier Compounding Ban; Sanhedrin Enforcement.

Evidence:

- TempleOS checker applies filename checks only to added files and identifier checks only to added diff lines; it explicitly allows edits to legacy long-name files.
- holyc-inference checker checks filenames in the target commit, but its identifier extraction runs `git diff "$REV" -- "$f"`; with `REV=HEAD`, this inspects working-tree changes against HEAD rather than the commit's added lines, so it can miss long identifiers already introduced by that commit.
- The two scripts share a name and headline policy but not equivalent semantics.

Impact: Sanhedrin cannot treat `automation/check-no-compound-names.sh HEAD` as a uniform cross-repo invariant. A green TempleOS result, a red holyc-inference result, and the full-corpus counts are measuring different surfaces.

## Recommended Follow-Up

- Normalize checker semantics across both repos: separate `commit delta` checks from explicit `full corpus` backfill checks.
- Add `.gitignore` coverage or CI rejection for `__pycache__/` and `*.pyc` in holyc-inference.
- Track the long-name corpus as debt instead of silently treating legacy names as compliant.

## Read-Only Verification

```bash
python3 audits/cross/2026-05-02-identifier-contract-drift.py
```

No QEMU/VM command was executed. No networking was enabled or touched.
