# Cross-Repo Release-Gate Status Taxonomy Drift Audit

Audit timestamp: 2026-04-29T15:21:53+02:00

Audit angle: cross-repo invariant checks. This pass compared current TempleOS and holyc-inference host-side gate/report semantics for release evidence status, air-gap evidence, and dry-run coverage. No trinity source files were modified. No QEMU or VM command was executed.

## Scope

- TempleOS read-only checkout: `/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55`
- holyc-inference read-only checkout: `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55`
- LAWS.md focus: Law 2 air-gap evidence, Law 5 meaningful validation evidence, Law 7 blocker visibility, and Law 10 immutable/QEMU evidence where benchmark launch plans are used as release proof.

## Summary

TempleOS host reporting and holyc-inference benchmark reporting do not share one release-gate status contract. TempleOS report aggregators primarily gate on `gate_failed` plus uppercase transcript states like `PASS`, `FAIL`, `UNKNOWN`, and `LEGACY`; holyc-inference uses lowercase artifact `status` plus separate sub-status columns (`command_airgap_status`, `telemetry_status`, `commit_status`, `command_hash_status`, `freshness_status`) and allows `planned`, `unknown`, `unchecked`, and dry-run coverage violations to coexist with overall `status=pass`. This drift weakens cross-repo compliance dashboards because a single "pass" no longer means the same thing across trinity members.

## Findings

1. **WARNING - holyc-inference can publish overall pass while dry-run coverage violations exist.**
   Evidence: `bench/results/bench_result_index_latest.json` currently reports `status=pass` with 129 artifacts and 123 `dry_run_coverage_violations`. The index builder writes `dry_run_coverage_violations` into the report, but `index_status()` only fails on air-gap, telemetry, commit, command-hash, freshness, or artifact `status == "fail"` and does not include dry-run coverage. The CLI prints the dry-run violation count separately after printing `status=pass`. Source references: `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/bench_result_index.py:782`, `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/bench_result_index.py:1622`, `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/bench_result_index.py:1753`.

2. **WARNING - holyc-inference pass status includes non-terminal and unaudited sub-states.**
   Evidence: current `bench_result_index_latest.json` has 125 artifacts with `status=pass`, 4 with `status=planned`, 52 with `command_hash_status=unknown`, 4 with `commit_status=unknown`, and 129 with `freshness_status=unchecked`, while the overall status remains `pass`. The current `index_status()` treats only literal `fail` values as failing, so unknown, planned, not-qemu, and unchecked states are not release blockers by default. Source reference: `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/bench_result_index.py:782`.

3. **WARNING - TempleOS and holyc-inference classify air-gap evidence with incompatible vocabularies.**
   Evidence: TempleOS `qemu-host-log-airgap-audit.py` classifies QEMU log evidence as uppercase `FAIL`, `LEGACY`, or `PASS`; holyc-inference `bench_result_index.py` classifies command air-gap as lowercase `fail`, `pass`, or `not-qemu`. `LEGACY` and `not-qemu` are not equivalent but can both avoid an overall failure depending on the consumer. Source references: `/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/qemu-host-log-airgap-audit.py:178`, `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/bench_result_index.py:241`.

4. **WARNING - TempleOS transcript outcome gates fail unknown QEMU outcomes, but holyc-inference preserves unknown sub-status without failing overall status.**
   Evidence: TempleOS `qemu-serial-outcome-report.py` derives transcript `PASS`, `FAIL`, or `UNKNOWN` and explicitly adds a gate failure for QEMU transcripts with `UNKNOWN` status. holyc-inference current reports preserve `command_hash_status=unknown` and `commit_status=unknown` without changing overall `status=pass`. Source references: `/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/qemu-serial-outcome-report.py:195`, `/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/qemu-serial-outcome-report.py:240`, `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/bench_result_index.py:1228`.

5. **INFO - TempleOS latest-report aggregation consumes `gate_failed` and quality-gate booleans, not a common `status` field.**
   Evidence: `bookoftruth-gate-failure-index.py` collects failures from `gate_failed`, `quality_gates.failed`, and `quality_gate.failed`, and itself emits `gate_failed`; sampled current TempleOS latest JSON reports show no top-level `status` values across 55 files, with 49 `gate_failed=false` and 2 `gate_failed=true`. This is internally coherent for TempleOS, but it leaves no direct normalized field for holyc-inference's lowercase `status` contract. Source references: `/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/bookoftruth-gate-failure-index.py:74`, `/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/bookoftruth-gate-failure-index.py:199`, `/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/bookoftruth-smoke-inventory.py:249`.

## Risk

Cross-repo Sanhedrin or release dashboards that only read `status=pass` will overstate holyc-inference readiness, while dashboards that only read `gate_failed` will under-read holyc-inference reports. For Law 2 and Law 10 evidence, the risky case is a benchmark or QEMU proof that is air-gap clean but only planned, stale/unchecked, or missing a dry-run companion, yet still rolls up as pass.

## Recommendations

- Define a shared trinity gate result schema with `result` values such as `pass`, `fail`, `blocked`, `skipped`, `planned`, `unknown`, and `legacy`, plus a separate `release_blocking` boolean.
- In holyc-inference, include `dry_run_coverage_violations` in the top-level status calculation when `require_dry_run_coverage` is true.
- In TempleOS, add a normalized lowercase `result` alongside existing human-facing `Gate: PASS/FAIL` and transcript `PASS/FAIL/UNKNOWN/LEGACY`.
- In Sanhedrin, treat any unknown, unchecked, legacy, planned, or skipped status as non-pass unless a report explicitly marks it non-release-blocking with a reason.

Finding count: 5 total, 4 warnings and 1 info.
