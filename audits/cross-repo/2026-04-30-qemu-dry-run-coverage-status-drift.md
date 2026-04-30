# Cross-Repo Audit: QEMU Dry-Run Coverage Status Drift

Audit timestamp: 2026-04-30T09:10:42+02:00

Scope: Cross-repo invariant check across the current heads of `templeos-gpt55` and `holyc-gpt55`. TempleOS and holyc-inference were inspected read-only. No QEMU or VM command was executed; the only reproduction run wrote derived index output under `/tmp` and did not launch QEMU.

## Invariant

Measured QEMU benchmark artifacts that are later used as comparable throughput evidence should have a matching reviewed dry-run launch plan for the same profile, model, quantization, prompt-suite hash, command hash, launch-plan hash, and environment hash. If that coverage is missing, every status surface used by CI, dashboards, or Sanhedrin should answer consistently: either the evidence is advisory everywhere, or it is a gate failure everywhere.

This matters for Laws 2, 5, and 7. The dry-run plan is part of the air-gap and provenance proof for benchmark evidence; a split-brain status makes historical audit trend conclusions depend on which artifact format was parsed.

## Summary

No direct air-gap violation was found in the inspected surfaces. The drift is a status contract mismatch: holyc-inference can persist `status: pass` while its own JUnit sidecar and fail flag treat the same dry-run coverage evidence as failing. TempleOS' QEMU command-manifest host-smoke path is stricter and currently records a clean QEMU command manifest, but the two repos do not share a single Sanhedrin-readable release-gate field for "planned-launch coverage missing."

## Findings

1. **WARNING - holyc-inference JSON status stays `pass` with 122 dry-run coverage violations.**
   Evidence: `bench/results/bench_result_index_latest.json` reports `status: pass`, `artifacts: 149`, `command_drift: 4`, `launch_plan_drift: 2`, and 122 `dry_run_coverage_violations`. A reproduction run of `python3 bench/bench_result_index.py --input bench/results --output-dir /tmp/holyc-bench-index-audit --fail-on-missing-dry-run` exited 1 but printed `status=pass` and wrote JSON with `dry_run_coverage_violations=122`. The exit code is controlled by the optional flag, while `index_status()` only fails air-gap, telemetry, commit, command-hash, launch-plan-hash, freshness, or artifact status failures.

2. **WARNING - holyc-inference JUnit and JSON disagree for the same evidence bundle.**
   Evidence: `bench/results/bench_result_index_junit_latest.xml` has `failures="3"` with failures for `command_drift`, `launch_plan_drift`, and `dry_run_coverage`, including the message `122 measured benchmark artifact(s) lack matching dry-run plans`. The JSON and Markdown top-level status remain `pass`, so CI consumers reading JUnit fail while dashboard consumers reading JSON pass.

3. **WARNING - the documented gate is opt-in, not encoded in persisted status.**
   Evidence: `bench/README.md` documents `--fail-on-missing-dry-run` for CI that should require reviewed dry-run launch plans, and `bench/bench_result_index.py` exposes that flag. The default persisted latest artifact therefore cannot by itself prove whether the project intended dry-run coverage to be mandatory for the indexed run.

4. **INFO - TempleOS QEMU command-manifest surface is clean and stricter for its own launchers.**
   Evidence: `templeos-gpt55` wires `host-smoke` to `qemu-airgap-report-strict` and `qemu-command-manifest-strict`; `qemu-command-manifest-strict` requires preferred `-nic none`. The current `MODERNIZATION/lint-reports/qemu-command-manifest-latest.json` reports `gate_failed=false`, `smoke_missing_no_network_count=0`, `smoke_preferred_no_network_count=1`, `smoke_preferred_no_network_bp=10000`, and `forbidden_network_lines=0`.

5. **WARNING - Sanhedrin has no cross-repo severity rule for dry-run coverage split-brain.**
   Evidence: holyc-inference can expose the issue as JSON pass, CLI exit 1 when the flag is supplied, and JUnit failure simultaneously. TempleOS exposes QEMU command evidence with `gate_failed`. Without a normalized cross-repo field such as `planned_launch_coverage_gate_failed`, retroactive audits can undercount Law 5 benchmark-evidence weakness or miss Law 7 blocker repeats when only one artifact format is ingested.

## Recommendations

- Make holyc-inference `bench_result_index_latest.json` carry a separate `gate_failed` or `dry_run_coverage_gate_failed` field, and include dry-run coverage in top-level `status` whenever the run was generated for release/CI gating.
- Update the README and CI examples so the canonical benchmark index command for comparable QEMU evidence includes `--fail-on-missing-dry-run`, `--fail-on-command-drift`, and `--fail-on-launch-plan-drift`.
- Teach Sanhedrin cross-repo audits to prefer normalized gate fields over prose `Status: pass`, and to count JUnit/JSON disagreement as warning-level evidence drift.

## Commands

- `python3 bench/bench_result_index.py --input bench/results --output-dir /tmp/holyc-bench-index-audit --fail-on-missing-dry-run`
- `python3 - <<'PY' ...` to summarize `bench/results/bench_result_index_junit_latest.xml`
- `python3 - <<'PY' ...` to summarize `MODERNIZATION/lint-reports/qemu-command-manifest-latest.json`
