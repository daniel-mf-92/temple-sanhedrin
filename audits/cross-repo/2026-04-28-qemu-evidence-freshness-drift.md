# Cross-Repo Invariant Audit: QEMU Evidence Freshness Drift

Timestamp: 2026-04-27T22:36:37Z

Auditor: gpt-5.5 sibling, retroactive/deep audit scope

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source code was modified, and no VM/QEMU command was executed.

Repos examined:
- TempleOS committed HEAD: `fb21587ef27adc021e418987deb200bcfb2ba29b`
- holyc-inference committed HEAD: `b362d4191bc6b0ef9079b877b9e74ec620e3d097`
- temple-sanhedrin committed baseline: `8c367755c25bf634baa1a129de57ff795c38710f`
- temple-sanhedrin branch: `codex/sanhedrin-gpt55-audit`

## Executive Summary

Found 4 findings: 3 warnings, 1 info.

The inspected heads keep explicit `-nic none` in the QEMU command surfaces reviewed here, and this audit did not identify a direct Law 2 air-gap break. The drift is evidence freshness: holyc-inference committed a newer QEMU dry-run artifact after its latest air-gap audit, benchmark index, and artifact manifest, while TempleOS host dashboards remain green on their own repo-local report set. The two repos therefore have green local dashboards but no cross-repo freshness contract proving that the newest QEMU-bearing artifact was indexed, air-gap audited, and classified as non-runtime evidence.

## Finding WARNING-001: holyc-inference air-gap audit predates the newest QEMU dry-run artifact

Applicable laws:
- Law 2: Air-Gap Sanctity
- Law 5: North Star Discipline / meaningful evidence

Evidence:
- `holyc-inference/bench/results/airgap_audit_latest.json` was generated at `2026-04-27T22:10:42Z` and reports `status=pass` with `commands_checked=130`.
- `holyc-inference/bench/results/qemu_prompt_bench_latest.json` was generated later at `2026-04-27T22:19:51Z` and reports `status=pass`.
- `holyc-inference/bench/results/qemu_prompt_bench_dry_run_latest.json` was generated later again at `2026-04-27T22:27:13Z` and records a planned command containing `bench/fixtures/qemu_synthetic_bench.py`, `-nic none`, `-serial stdio`, `-display none`, `-drive file=/tmp/TempleOS.synthetic.img,format=raw,if=ide`, and `-m 256M`.
- `git log --name-only` shows `b362d419` committed the dry-run artifact, while the latest committed `airgap_audit_latest.json` came from earlier commit `ea55b6ea`.

Assessment:
The dry-run command itself preserves the explicit no-network flag. The stale evidence problem is that the committed pass report no longer covers the newest committed QEMU-bearing artifact. The project can truthfully show a passing air-gap audit and still have a later QEMU command artifact that has not been included in that audit snapshot.

Risk:
Historical dashboards can over-count `airgap_audit_latest.json: pass` as covering all current QEMU evidence, when it only covers the repository state as of its earlier generation time.

Required remediation:
- Refresh `bench/results/airgap_audit_latest.*` after committing any new artifact that contains a QEMU command.
- Add a freshness gate: fail when any supported QEMU-bearing artifact has `generated_at` later than the latest air-gap audit.
- Include dry-run artifacts explicitly in the freshness contract, even if they are not throughput evidence.

## Finding WARNING-002: dry-run artifacts are not represented in the benchmark index or manifest

Applicable laws:
- Law 5: North Star Discipline
- Law 2: Air-Gap Sanctity

Evidence:
- `bench/qemu_prompt_bench.py:625-647` builds a dry-run payload with `status="planned"`, command, prompt-suite hash, warmup count, repeat count, and planned launch totals.
- `bench/qemu_prompt_bench.py:650-658` writes `qemu_prompt_bench_dry_run_latest.json`, `.md`, and a timestamped dry-run JSON.
- `bench/bench_result_index.py:94-99` accepts file names that start with `qemu_prompt_bench` or `bench_matrix`, but `load_summaries()` only emits summaries for reports with `benchmarks` or `cells`.
- Because dry-run reports have neither `benchmarks` nor `cells`, the latest dry-run is absent from `bench_result_index_latest.json`.
- `bench_artifact_manifest.py:175-188` builds its manifest only from `bench_result_index.load_summaries()`, so the dry-run is also absent from `bench_artifact_manifest_latest.json`.

Assessment:
It is reasonable that a dry-run should not become throughput history. The missing distinction is that command-planning artifacts still need provenance and air-gap freshness visibility. Today they are neither throughput artifacts nor separately indexed planning artifacts.

Risk:
A future dry-run command regression could be committed as `planned` evidence without appearing in the benchmark index or manifest. That weakens the audit trail for planned QEMU invocations.

Required remediation:
- Add a separate artifact type such as `qemu_prompt_dry_run` to the index/manifest, with `measured_runs=0`, `status=planned`, and `north_star_eligible=false`.
- Keep dry-run rows out of throughput medians, but include their command air-gap and immutable-image checks in artifact manifests.

## Finding WARNING-003: TempleOS host dashboard has no cross-repo freshness input

Applicable laws:
- Law 5: North Star Discipline
- Law 2: Air-Gap Sanctity, insofar as cross-repo QEMU evidence is shared

Evidence:
- `TempleOS/MODERNIZATION/lint-reports/host-regression-dashboard-latest.json` reports `gate_failed=false`, `report_count=10`, `passing_count=10`, and `failing_count=0`.
- That dashboard includes TempleOS-local report rows such as QEMU air-gap evidence, host dependency report, host automation inventory, and host Makefile inventory.
- The same dashboard has no row for holyc-inference benchmark air-gap freshness, dry-run planning artifacts, benchmark index freshness, or artifact manifest freshness.
- `TempleOS/MODERNIZATION/lint-reports/host-makefile-inventory-latest.json` reports `gate_failed=false` and `qemu_recipe_line_count=0`, which is useful for Makefile wiring but cannot validate holyc-inference QEMU benchmark artifacts.

Assessment:
The TempleOS dashboard is scoped to TempleOS host reports, so this is not a TempleOS dashboard bug by itself. The cross-repo invariant gap is that both repos can be locally green while no artifact asserts "the latest inference QEMU command evidence is fresh relative to the latest air-gap audit and is non-runtime/non-north-star evidence."

Risk:
Sanhedrin trend reports can present a green trinity posture by joining repo-local statuses, while the newest QEMU-bearing artifact in the inference repo is outside the latest committed audit/index/manifest snapshots.

Required remediation:
- Add a Sanhedrin-level cross-repo freshness report that compares generated timestamps for QEMU-bearing artifacts, air-gap audits, indexes, manifests, and TempleOS host dashboards.
- Treat a newer unaudited QEMU-bearing artifact as `STALE_EVIDENCE`, not as a Law 2 breach, unless the command itself violates no-network policy.

## Finding INFO-001: Reviewed QEMU command surfaces still preserve explicit no-network evidence

Applicable laws:
- Law 2: Air-Gap Sanctity

Evidence:
- `bench/qemu_prompt_bench.py:202-216` constructs commands with `-nic none`, `-serial stdio`, `-display none`, and a drive argument.
- `bench/qemu_prompt_bench.py:170-199` rejects non-`none` `-nic` and `-net` arguments, rejects `-netdev`, and rejects common virtual NIC device arguments.
- `tests/test_qemu_prompt_bench.py:16-24` asserts `build_command()` forces `["qemu-system-x86_64", "-nic", "none"]`.
- `TempleOS/automation/qemu-holyc-load-test.sh:122-131` includes `-nic none` in its QEMU arg array and calls `qemu_airgap_require_disabled_network` before launch.

Assessment:
No guest networking enablement was found in the inspected surfaces. The issue is stale and incomplete evidence classification, not an observed air-gap breach.

## Non-Findings

- No QEMU or VM command was executed during this audit.
- No WS8 networking task was executed.
- No TempleOS or holyc-inference source file was edited.
- The dry-run artifact is host-side planning output; it does not prove guest execution and should not be counted as north-star runtime evidence.
- The inspected dry-run and benchmark commands include `-nic none`; this audit does not flag them as Law 2 command violations.

## Read-Only Verification Commands

- `git -C /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55 rev-parse HEAD`
- `git -C /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55 rev-parse HEAD`
- `python3 - <<'PY' ...` timestamp extraction for holyc-inference benchmark result JSON files
- `git -C /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55 log --oneline --name-only -- bench/results/airgap_audit_latest.json bench/results/qemu_prompt_bench_dry_run_latest.json bench/results/bench_result_index_latest.json bench/results/bench_artifact_manifest_latest.json`
- `nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/qemu_prompt_bench.py | sed -n '620,840p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/bench_result_index.py | sed -n '82,190p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/bench_artifact_manifest.py | sed -n '175,235p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/tests/test_qemu_prompt_bench.py | sed -n '1,160p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/qemu-holyc-load-test.sh | sed -n '118,160p'`
