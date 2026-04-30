# Cross-Repo Audit: Artifact Manifest Gate Semantics Drift

Timestamp: 2026-04-30T21:36:04+02:00

Audit angle: cross-repo invariant check for whether TempleOS host report gates and holyc-inference benchmark artifact manifests expose compatible pass/fail semantics for promotion evidence.

Repos reviewed:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55` at `64827c16fa23745bf62af9ebbdf827175b49a0b8`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55` at `a70776642a09de7ed01eb75aaaebbdd3243f84c2`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at `8719164d129e25df8cb92b8aff889c9fc56476f0`

No TempleOS or holyc-inference source file was modified. No QEMU, VM, WS8 networking, package-download, SSH, networking, or live liveness command was executed.

## Expected Cross-Repo Invariant

Any cross-repo promotion gate that consumes TempleOS host reports and holyc-inference benchmark artifacts needs one fail-closed status contract:
- a stable top-level gate field with machine-readable failures;
- optional diagnostic findings must not be silently counted as promotion-pass evidence;
- air-gap, immutable-launch, command-hash, commit, freshness, dry-run, and timestamp uniqueness checks must have explicit pass/fail/waived states;
- latest aliases must be joinable to immutable history without ambiguity.

Finding count: 5 warnings.

## Findings

### WARNING-001: holyc benchmark manifest reports `status=pass` while carrying dry-run and timestamp evidence gaps

Applicable laws:
- Law 2: Air-Gap Sanctity
- Law 5: North Star Discipline

Evidence:
- `bench/results/bench_artifact_manifest_latest.json` reports `status: pass`, `history_artifacts: 149`, `dry_run_coverage_violations: 122`, and `timestamp_collisions: 42`.
- The same report has `require_dry_run_coverage: false` and `require_unique_timestamps: false`, so those findings are diagnostics rather than failing conditions.
- `bench/bench_artifact_manifest.py:946-954` only fails dry-run coverage and timestamp collisions when the corresponding `require_*` flags are enabled.

Assessment:
The manifest is useful for discovery, but it is not fail-closed promotion evidence. A cross-repo gate that treats `status=pass` as equivalent to TempleOS `gate_failed=false` can accidentally promote measured QEMU rows whose launch plans were not paired with dry-run artifacts and whose key/timestamp history is not unique.

Required remediation:
- Introduce a strict promotion profile for holyc benchmark manifests that requires dry-run coverage and unique timestamps.
- Mark non-strict manifests as `advisory` or `diagnostic` so they cannot be confused with release gates.

### WARNING-002: holyc latest rows allow `unknown` and `unchecked` sub-statuses under an aggregate pass

Applicable laws:
- Law 2: Air-Gap Sanctity
- Law 5: North Star Discipline

Evidence:
- `bench/results/bench_artifact_manifest_latest.json` latest rows include passing artifacts with `command_hash_status: unknown` and `freshness_status: unchecked`, including the `ci-airgap-smoke/.../no-suite` rows.
- `bench/bench_artifact_manifest.py:198-211` fails only literal `"fail"` values for artifact, air-gap, telemetry, command-hash, commit, and freshness fields.
- The README says the manifest can gate command hashes and artifact freshness, but the published latest report leaves those checks non-failing unless flags are supplied at runtime (`bench/README.md:958-968`).

Assessment:
`unknown` and `unchecked` are not proof states. For cross-repo release accounting, they should either fail closed or carry an explicit waiver, otherwise a partially proven benchmark row can become indistinguishable from a fully proven one.

Required remediation:
- Define a promotion status lattice such as `pass`, `fail`, `waived`, `unknown`, `unchecked`, and make only `pass` and approved `waived` values eligible for release evidence.
- Require command-hash and freshness checks for benchmark rows used by TempleOS promotion gates.

### WARNING-003: TempleOS index fails closed on child report failures, but holyc has no equivalent `gate_failed` sink

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- TempleOS `MODERNIZATION/lint-reports/host-report-artifact-index-latest.json` reports `gate_failed: true`, `failing_report_gate_count: 17`, and 19 top-level `gate_failures`.
- `automation/host-report-artifact-index.py:626-724` accumulates missing artifacts, orphan stems, stale/future artifacts, child report gate failures, markdown mismatches, size issues, and exposes `gate_failed: bool(gate_failures)`.
- holyc `bench/results/bench_artifact_manifest_latest.json` uses top-level `status`, but has no `gate_failed` or `gate_failures` fields.

Assessment:
The two repos do not share a gate vocabulary. TempleOS exposes a direct fail sink that Sanhedrin can consume uniformly, while holyc benchmark manifests require status-specific interpretation plus flag knowledge. That makes cross-repo promotion code brittle and easy to misread.

Required remediation:
- Add `gate_failed` and `gate_failures` to holyc benchmark/eval manifests, even if `status` remains for human summaries.
- Require Sanhedrin promotion consumers to check the shared gate fields first.

### WARNING-004: TempleOS contract allows missing gate fields in child reports, weakening schema convergence

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- `MODERNIZATION/lint-reports/host-report-contract-latest.md` reports 4 invalid `gate_failed` fields, 4 invalid `gate_failures` fields, 25 Markdown pairs missing gate lines, and still `Gate: PASS`.
- `automation/host-report-contract.py:182-203` records missing or invalid gate fields, but only fails for type mismatch and inconsistent `gate_failed`/`gate_failures` combinations.
- The same contract summarizes invalid gate-field counts without turning missing gate sinks into contract failures at `automation/host-report-contract.py:247-258` and `automation/host-report-contract.py:276-282`.

Assessment:
TempleOS is ahead of holyc in exposing gate metadata, but its contract still treats several missing gate fields as acceptable. That tolerance makes it harder to converge the trinity on one artifact contract and leaves room for advisory reports to masquerade as gate reports.

Required remediation:
- Split report classes into `gate report` and `advisory report`.
- For gate reports, require `gate_failed`, `gate_failures`, and a Markdown gate line.

### WARNING-005: Freshness is effectively optional on both sides for cross-repo promotion evidence

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- TempleOS `host-report-artifact-index-latest.json` reports `timestamp_skew_seconds: 51499` and `timestamp_skew_exceeded: false` because `max_skew_minutes` is 0.
- TempleOS also reports `stale_artifact_count: 0` with `max_age_hours: 0`, which indicates the staleness budget is disabled for this generated index.
- holyc latest benchmark rows report `freshness_status: unchecked`; strict stale-artifact failure only happens when `--fail-on-stale-artifact` is supplied (`bench/bench_artifact_manifest.py:1174-1177`).

Assessment:
Freshness is being collected but not enforced in the artifacts reviewed here. A cross-repo promotion gate can therefore join current TempleOS control-plane state to stale holyc benchmark rows, or vice versa, without a hard failure.

Required remediation:
- Define a shared freshness budget for promotion evidence and record it in both manifests.
- Treat disabled freshness as `advisory`, not `pass`, for promotion-grade reports.

## Non-Findings

- No HolyC purity violation was found in the reviewed surfaces.
- No integer-purity violation was found in the reviewed benchmark manifest path.
- No air-gap breach was found; this audit reviewed saved artifacts and source text only.

## Evidence Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55 rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55 rev-parse HEAD
jq '{expected_report_count,present_json_count,present_markdown_count,paired_artifact_count,orphan_latest_artifact_count,stale_artifact_count,timestamp_skew_seconds,timestamp_skew_exceeded,failing_report_gate_count,gate_failed,gate_failures_count:(.gate_failures|length),family_counts}' /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/MODERNIZATION/lint-reports/host-report-artifact-index-latest.json
jq '{status, require_dry_run_coverage, require_unique_timestamps, require_environment_stability, min_history_per_key, min_measured_runs, min_total_tokens, latest_count:(.latest_artifacts|length), history_artifacts, dry_run_coverage_count:(.dry_run_coverage_violations|length), timestamp_collision_count:(.timestamp_collisions|length), history_coverage_count:(.history_coverage_violations|length), sample_coverage_count:(.sample_coverage_violations|length), environment_drift_count:(.environment_drift|length)}' /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/results/bench_artifact_manifest_latest.json
jq -r '.latest_artifacts[] | [.key,.status,.command_airgap_status,.telemetry_status,.command_hash_status,.freshness_status,.commit_status,.source] | @tsv' /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/results/bench_artifact_manifest_latest.json
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/bench_artifact_manifest.py | sed -n '190,215p;920,958p;1138,1186p'
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/host-report-artifact-index.py | sed -n '626,724p;850,864p'
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/host-report-contract.py | sed -n '182,203p;247,258p;276,282p'
```
