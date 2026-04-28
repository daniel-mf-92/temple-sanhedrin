# Cross-Repo Audit: Artifact Manifest Gate Drift

- Timestamp: 2026-04-28T09:39:55Z
- Scope: TempleOS `codex/templeos-gpt55-testharness` at `0d40d6efa67d`; holyc-inference `codex/holyc-gpt55-bench` at `9ce68b73415f`
- Audit angle: cross-repo invariant checks
- Laws implicated: Law 2, Law 5, Law 7, Law 10
- Safety posture: read-only audit; no QEMU or VM commands executed; TempleOS guest air-gap unchanged

## Invariant Under Review

Both builder repos now produce "latest" host-side evidence artifacts that Sanhedrin and humans use as proof of progress. The invariant should be:

1. Latest evidence has a complete inventory.
2. Latest evidence exposes stale, mismatched, or drifted artifacts as failing gates when used as release or progress proof.
3. Machine-readable status, Markdown status, and JUnit status agree.
4. Benchmark evidence that relies on QEMU command provenance keeps air-gap command drift visible as a gate, not just as passive metadata.

## Evidence Read

- TempleOS `automation/host-report-artifact-index.py` defines `EXPECTED_REPORT_STEMS` and checks JSON/Markdown pairs, JSON validity, `generated_at`, zero-byte files, orphan latest stems, future timestamps, stale timestamps when enabled, report gate failures, and Markdown/JSON gate mismatches.
- TempleOS `MODERNIZATION/lint-reports/host-report-artifact-index-latest.json` records 23 expected reports, 23 paired reports, `gate_failed=false`, and `max_age_hours=0`.
- TempleOS `Makefile` wires `host-reports` through all current report generators, then `host-report-artifact-index` and `host-regression-dashboard`; `host-reports-strict` reruns the aggregate dashboard with strict skew/dependency checks.
- holyc-inference `bench/bench_artifact_manifest.py` builds a benchmark artifact manifest from `bench_result_index` summaries and supports `--fail-on-stale-commit`, `--max-artifact-age-hours`, and `--fail-on-stale-artifact`, but those conditions are optional.
- holyc-inference `bench/results/bench_artifact_manifest_latest.json` records `status=pass` while all 6 latest artifacts have `current_commit_match=false` and `freshness_status=unchecked`.
- holyc-inference `bench/results/bench_result_index_latest.json` records `status=pass` while all 61 indexed artifacts have `current_commit_match=false`, all 61 have `freshness_status=unchecked`, and 1 command-drift key is present.
- holyc-inference `bench/results/bench_result_index_junit_latest.xml` records `failures="1"` for that command drift while the JSON and Markdown top-level status remain pass.
- holyc-inference has no root `Makefile`; bench gate invocation is documented in `bench/README.md` and exercised in tests such as `bench/perf_ci_smoke.py`, but there is no committed aggregate target equivalent to TempleOS `host-reports-strict`.

## Findings

### WARNING 1: holyc-inference latest benchmark manifest can pass with stale commit evidence

`bench_artifact_manifest_latest.json` has 6 latest artifacts and `status=pass`, but every latest artifact has `current_commit_match=false`. The stale-commit condition is detectable and even has a CLI flag, but the persisted manifest status does not treat it as a failure unless the invocation asks for `--fail-on-stale-commit`.

Why it matters: Sanhedrin or humans reading only `status=pass` can accept benchmark proof from older commits as current proof.

### WARNING 2: holyc-inference latest benchmark freshness is unchecked by default

Both `bench_artifact_manifest_latest.json` and `bench_result_index_latest.json` record `freshness_status=unchecked` for every artifact read in this audit. TempleOS also has optional freshness in the pair index (`max_age_hours=0`), but its strict aggregate target has explicit skew/dependency checks; holyc-inference's committed latest artifacts do not show an equivalent enforced freshness posture.

Why it matters: historical benchmark evidence can look current even after many iterations unless the stricter flags are consistently used.

### WARNING 3: holyc-inference benchmark result index has contradictory pass/fail surfaces

`bench_result_index_latest.json` reports `status=pass` and `bench_result_index_latest.md` reports `Status: pass`, while `bench_result_index_junit_latest.xml` reports `failures="1"` for command drift. That creates two different answers for the same evidence bundle.

Why it matters: CI systems reading JUnit see a failure, while scripts reading JSON/Markdown see a pass. This weakens Law 5 progress evidence and makes historical drift harder to audit.

### WARNING 4: command drift is detected but not reflected in the JSON top-level status

The holyc-inference result index detected command drift for `ci-airgap-smoke/synthetic-smoke/Q4_0/68fc621f9f3916e73aa05b83ba0fa8da9f3cffad22a1c29f5acf8980d8dd743a`, with two command hashes across five sources. The JSON top-level `status` still reports pass.

Why it matters: QEMU benchmark command drift is relevant to Law 2 and Law 10 because command provenance is where no-network and immutable-image evidence live. Drift should not be easy to miss when the artifact advertises itself as passing.

### WARNING 5: TempleOS has a fixed report-pair inventory; holyc-inference benchmark artifacts do not have an equivalent expected latest set

TempleOS hardcodes 23 expected report stems in `automation/host-report-artifact-index.py` and fails missing JSON/Markdown pairs. holyc-inference's benchmark manifest indexes discovered benchmark summaries and selects latest artifacts by key, but this audit did not find a comparable fixed expected set for benchmark/eval latest artifacts.

Why it matters: missing holyc-inference latest artifact classes can silently disappear from the manifest if no source summary is present, whereas TempleOS fails missing expected report pairs.

## Recommended Follow-Up

- Make holyc-inference JSON/Markdown/JUnit status semantics agree for command drift.
- Consider making stale-commit and freshness failures part of persisted holyc-inference manifest status, not only optional CLI exit behavior.
- Add a fixed expected latest-artifact inventory for holyc-inference benchmark/eval evidence, mirroring the TempleOS report-pair index concept.
- If optional flags remain intentional, document which invocation is authoritative for Sanhedrin and release proof.

## Finding Count

- 5 warnings
- 0 critical findings
