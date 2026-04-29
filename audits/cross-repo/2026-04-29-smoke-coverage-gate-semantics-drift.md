# Cross-Repo Audit: Smoke Coverage Gate Semantics Drift

- Audit time: `2026-04-29T09:06:52+02:00`
- Scope: cross-repo invariant check of committed smoke/evidence coverage manifests in TempleOS and holyc-inference
- TempleOS head inspected: `701e8e9e4689d3086d8795ccab1aa9cd7467be0f`
- holyc-inference head inspected: `bb0d529737496c137b90d74815cb3a0c95cdd0b9`
- Sanhedrin branch: `codex/sanhedrin-gpt55-audit`

## Scope

Read-only comparison of TempleOS `MODERNIZATION/lint-reports/host-smoke-manifest-latest.*` and holyc-inference `bench/results/bench_artifact_manifest_latest.*`. I did not modify trinity source code, run live liveness checks, run QEMU, execute WS8/networking work, or inspect/alter uncommitted builder changes beyond noting the working trees were not mine to touch.

## Expected Cross-Repo Invariant

Smoke and artifact manifests that advertise a pass state should distinguish:

- required coverage inputs that gate correctness,
- advisory inventory gaps that do not gate,
- coverage debt counts large enough to make Law 5 progress claims suspect, and
- evidence gaps that require Law 7 blocker escalation rather than repeated pass-with-debt iterations.

This invariant matters because Law 5 treats test harnesses and concrete validation as good work only when they validate correctness, and Law 7 requires repeated blockers or gaps to be escalated instead of silently retried.

## Findings

- **WARNING - TempleOS host-smoke manifest passes with 823 unreferenced smoke scripts.** `host-smoke-manifest-latest.json` reports `all_smoke_script_count: 886`, `host_smoke_reachable_script_count: 67`, `unreferenced_smoke_script_count: 823`, `gate_failed: false`, and zero gate failures. That means 92.9% of detected smoke scripts are outside the host-smoke reachability set while the committed gate still presents as pass.

- **WARNING - TempleOS unreferenced smoke inventory overlaps known identifier-compounding risk.** Among the 823 unreferenced smoke scripts, 717 filenames exceed 40 characters and 676 have more than five hyphen-separated tokens. Even if those scripts are advisory, the manifest currently hides a large Law 4 identifier-compounding surface behind a passing smoke-coverage gate.

- **WARNING - holyc-inference artifact manifest passes with 116 dry-run coverage violations.** `bench_artifact_manifest_latest.json` reports `status: pass`, `history_artifacts: 122`, and 116 dry-run coverage violations. The violations are not a small historical tail: 51 affect `ci-airgap-smoke/synthetic-smoke/Q4_0`, 38 affect `ci-airgap-smoke/synthetic-smoke/Q8_0`, and 27 affect `synthetic-airgap-smoke/synthetic-smoke/Q4_0`.

- **WARNING - holyc-inference dry-run coverage enforcement is explicitly disabled.** The same manifest records `require_dry_run_coverage: false`, so the 116 measured artifacts without comparable dry-runs are reported but non-gating. That weakens benchmark evidence for air-gap/synthetic smoke claims because missing dry-runs are exactly the control plane needed to separate real runtime effects from harness defaults.

- **WARNING - Cross-repo pass semantics are inconsistent enough for Sanhedrin to mis-rank risk.** TempleOS treats host-smoke reachability as pass despite 823 unreferenced scripts; holyc-inference treats benchmark artifact coverage as pass despite 116 missing dry-run controls. Neither manifest exposes a shared severity vocabulary such as `pass_with_coverage_debt`, `warning`, or `blocked`, so Sanhedrin has to infer whether large validation gaps are Law 5 busywork risk, Law 7 blocker debt, or acceptable advisory backlog.

## Positive Checks

- TempleOS reports zero missing referenced smoke scripts, zero missing py-compile modules, zero non-executable smoke scripts, and zero duplicate smoke references.
- TempleOS host-smoke wiring reaches 67 shell scripts and 47 Python modules through the `syntax-smoke` surface.
- holyc-inference reports seven latest artifacts, 122 historical artifacts, zero environment drift, and zero history coverage violations in the inspected manifest.
- No networking or VM command was run during this audit; the TempleOS guest air-gap policy was not exercised or changed.

## Recommended Follow-Up

- Add a shared manifest status vocabulary for `pass`, `pass_with_advisory_debt`, `warning`, and `fail`.
- In TempleOS, either make unreferenced smoke count a thresholded warning/failure or label it explicitly as non-gating inventory.
- In holyc-inference, require a documented reason when `require_dry_run_coverage` is false and dry-run coverage violations are nonzero.
- Teach Sanhedrin to count large pass-with-debt manifests as Law 5/Law 7 audit findings instead of treating raw `pass` as sufficient.

## Evidence Commands

- `git -C ../templeos-gpt55 show HEAD:MODERNIZATION/lint-reports/host-smoke-manifest-latest.json | jq -r '[.generated_at, .all_smoke_script_count, .host_smoke_reachable_script_count, .syntax_smoke_script_count, .harness_smoke_script_count, .unreferenced_smoke_script_count, .gate_failed, (.gate_failures|length)] | @tsv'`
- `git -C ../templeos-gpt55 show HEAD:MODERNIZATION/lint-reports/host-smoke-manifest-latest.json | jq -r '.unreferenced_smoke_scripts[]' | awk -F/ '{n=$NF; if (length(n)>40) over40++; split(n,a,/-/); if (length(a)>5) over5++; total++} END {printf "total=%d over40=%d over5=%d\n", total, over40, over5}'`
- `git -C ../holyc-gpt55 show HEAD:bench/results/bench_artifact_manifest_latest.json | jq -r '[.generated_at, .status, (.latest_artifacts|length), .history_artifacts, (.dry_run_coverage_violations|length), .require_dry_run_coverage, (.history_coverage_violations|length), .min_history_per_key] | @tsv'`
- `git -C ../holyc-gpt55 show HEAD:bench/results/bench_artifact_manifest_latest.json | jq -r '.dry_run_coverage_violations[].key' | awk -F/ '{print $1"/"$2"/"$3}' | sort | uniq -c`
