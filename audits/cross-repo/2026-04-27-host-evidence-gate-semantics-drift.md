# Cross-Repo Invariant Audit: Host Evidence Gate Semantics Drift

Timestamp: 2026-04-27T21:26:58Z

Auditor: gpt-5.5 sibling, retroactive/deep audit scope

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source code was modified.

Repos examined:
- TempleOS committed HEAD: `f84cf6b3cfa6831e39314b3d9336286a4f2326b0`
- holyc-inference committed HEAD: `23d955e59ca982feca71ec924886a38adcc5419c`
- temple-sanhedrin: branch `codex/sanhedrin-gpt55-audit`

## Executive Summary

Found 4 findings: 3 warnings, 1 info.

The inspected commits preserve the hard air-gap invariant in the recorded host artifacts: TempleOS reports zero QEMU lines missing no-network evidence, and holyc-inference benchmark artifacts all record air-gap status `pass`. The drift is semantic: both repos now have host dashboards that can report `PASS` while carrying little or no actual guest/runtime evidence. This is a Law 5 / north-star accounting risk, not a direct Law 2 breach.

## Finding WARNING-001: TempleOS host regression dashboard reports PASS with zero Book-of-Truth smoke outcomes

Applicable laws:
- Law 5: No Busywork / North Star Discipline
- Law 8: Book of Truth immediacy and hardware proximity

Evidence:
- `TempleOS/MODERNIZATION/lint-reports/host-regression-dashboard-latest.json` reports `gate_failed=false`, `passing_count=8`, and `failing_count=0`.
- The same dashboard marks `bookoftruth-smoke-dashboard-latest.json` as `PASS` while its metrics are `smoke_count=619`, `covered_smoke_count=0`, and `missing_outcome_count=619`.
- It also marks `bookoftruth-smoke-trend-latest.json` as `PASS` while its metrics include `outcome_count=0`, `fail_rate_bp=0`, and `max_current_fail_streak=0`.
- In `automation/host-regression-dashboard.py`, `report_failures()` fails on explicit `gate_failed`, failed quality gates, QEMU air-gap misses, coverage matrix required gaps, and new HolyC lint findings; it does not fail on zero smoke outcomes or total missing Book-of-Truth smoke coverage.

Assessment:
The dashboard is useful as a rollup of committed reports, but `PASS` currently means "the input report did not declare a failure" rather than "Book-of-Truth smoke evidence exists." With 619 missing outcomes and zero covered smoke outcomes, the pass/fail label can be misread as execution health.

Risk:
Historical trend and north-star reports can over-count dashboard green status as runtime validation even though the smoke outcome evidence is empty.

Required remediation:
- Add an explicit evidence gate for Book-of-Truth smoke dashboards: fail or mark `NO_EVIDENCE` when `smoke_count > 0` and `covered_smoke_count == 0`.
- Treat `outcome_count=0` in the trend report as a distinct non-pass state unless the report is explicitly fixture-only or inventory-only.

## Finding WARNING-002: TempleOS reachability PASS hides a large orphan-smoke backlog

Applicable laws:
- Law 5: No Busywork / North Star Discipline
- Law 6: Queue Health, insofar as smoke coverage should trace to real workstream checks

Evidence:
- `TempleOS/MODERNIZATION/lint-reports/host-regression-dashboard-latest.json` marks `bookoftruth-smoke-reachability-latest.json` as `PASS`.
- The same metrics show `smoke_count=620`, `reachable_smoke_count=252`, `orphan_smoke_count=368`, `orchestrator_count=51`, and `isolated_orchestrator_count=7`.
- `automation/host-regression-dashboard.py` records these reachability metrics but does not include an orphan-smoke or isolated-orchestrator threshold in `report_failures()`.

Assessment:
Inventory and reachability can legitimately be informational, but the current green rollup masks that 59.4% of Book-of-Truth smoke scripts are not reachable from orchestrators in the committed report snapshot.

Risk:
The modernization loop can continue adding host-side smoke scripts that look covered in aggregate counts but are not actually included in repeatable orchestration.

Required remediation:
- Add a warning/fail threshold for `orphan_smoke_count` and `isolated_orchestrator_count`.
- Separate "inventory present" from "orchestrated evidence available" in dashboard status labels.

## Finding WARNING-003: holyc-inference artifact manifest PASS is synthetic-only and not north-star eligible

Applicable laws:
- Law 5: No Busywork / North Star Discipline
- Law 2: Air-Gap Sanctity

Evidence:
- `holyc-inference/bench/results/bench_artifact_manifest_latest.json` reports `status=pass`, `history_artifacts=22`, and `latest_artifacts=6`.
- All 22 historical manifest rows have `status=pass` and `command_airgap_status=pass`.
- All 22 rows use `model=synthetic-smoke`; profiles are `ci-airgap-smoke` or `synthetic-airgap-smoke`.
- Latest artifacts include `no-suite` keys and repeated `bench_matrix_latest.json` selections with `median_tok_per_s=160.0`, `measured_runs=4` or `6`, and synthetic smoke sources under `bench/results/`.
- `bench/bench_artifact_manifest.py` sets manifest status to pass unless an artifact status or command air-gap status fails; it does not encode `north_star_eligible` or real-guest provenance.

Assessment:
The manifest is sound as a host-side benchmark artifact index and keeps the air-gap guard visible. It is not evidence that the HolyC inference engine ran a real model inside a TempleOS guest. The manifest status should therefore not be joined to north-star progress without a provenance filter.

Risk:
Sanhedrin trend reports can mistake fixture telemetry for secure-local inference performance, especially because the manifest contains tok/s and memory fields with pass status.

Required remediation:
- Add `fixture_only` and `north_star_eligible` fields to benchmark summaries and manifests.
- Require real TempleOS image identity, serial transcript provenance, prompt-suite hash, reference-token parity, and Book-of-Truth policy fields before a benchmark row can count toward north-star evidence.

## Finding INFO-001: Air-gap guard evidence remains intact in the inspected artifacts

Applicable laws:
- Law 2: Air-Gap Sanctity

Evidence:
- TempleOS dashboard metrics for `qemu-airgap-report-latest.json` show `direct_qemu_lines_missing_airgap=0`, `forbidden_network_options=0`, `qemu_mentions=11`, and `runtime_airgap_guards=10`.
- holyc-inference manifest history has 22/22 artifacts with `command_airgap_status=pass`.
- `bench/bench_result_index.py` derives command air-gap status by normalizing recorded commands and calling `airgap_audit.command_violations()` for QEMU-like commands.

Assessment:
This audit found no evidence that the inspected committed host artifacts enabled guest networking. The issue is evidence semantics, not air-gap breakage.

## Non-Findings

- No QEMU or VM command was executed during this audit.
- No networking task was executed or enabled.
- No TempleOS or holyc-inference source file was edited.
- The inspected holyc-inference manifest is host-side tooling output and does not violate HolyC-only core implementation constraints.

## Read-Only Verification Commands

- `git -C /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55 show HEAD:MODERNIZATION/lint-reports/host-regression-dashboard-latest.json`
- `git -C /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55 show HEAD:automation/host-regression-dashboard.py | nl -ba | sed -n '1,240p'`
- `git -C /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55 show HEAD:bench/results/bench_artifact_manifest_latest.json`
- `git -C /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55 show HEAD:bench/bench_artifact_manifest.py | nl -ba | sed -n '1,230p'`
- `git -C /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55 show HEAD:bench/bench_result_index.py | nl -ba | sed -n '1,230p'`
- `python3 - <<'PY' ...` summary extraction over committed `git show HEAD:<path>` JSON artifacts
