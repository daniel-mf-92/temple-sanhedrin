# Cross-Repo Audit: Artifact Provenance Gate Drift

- Audit time: `2026-04-29T03:58:17Z`
- Scope: cross-repo invariant check of committed artifact/provenance reports in TempleOS and holyc-inference
- TempleOS head inspected: `891966eec085c81dfb73c37657118399d1c650b0`
- holyc-inference head inspected: `20c659dc54357856ff5642378b9d692cc632ff90`
- Sanhedrin branch: `codex/sanhedrin-gpt55-audit`

## Scope

Read-only comparison of TempleOS `MODERNIZATION/lint-reports/*latest*` provenance surfaces and holyc-inference `bench/results/*latest*` benchmark provenance surfaces. I did not modify trinity source code, run live liveness checks, run QEMU, execute WS8/networking tasks, or inspect uncommitted builder work except to note it exists and avoid touching it.

## Expected Cross-Repo Invariant

Committed generated reports that can influence gates, dashboards, or audit conclusions should carry enough provenance to prove:

- which repository commit produced the artifact,
- whether the artifact was produced from the current committed source,
- what exact file payload was reviewed, and
- whether stale or internally inconsistent evidence makes the gate fail.

This invariant matters for LAWS.md Law 2, Law 5, Law 7, and Law 10 because stale or non-reproducible evidence can make air-gap, north-star, blocker, and immutable-image conclusions appear stronger than the committed artifacts justify.

## Findings

- **WARNING - TempleOS host artifact index lacks commit and content-hash provenance.** `MODERNIZATION/lint-reports/host-report-artifact-index-latest.json` indexes 40 report pairs but the artifact records have no `sha256`, `commit`, `current_commit`, or `commit_status` fields. By contrast, holyc-inference `bench_artifact_manifest_latest.json` records payload `sha256`, benchmark `commit`, `current_commit`, and commit-match state for each latest artifact. TempleOS therefore cannot prove from the committed index alone that all dashboard inputs came from the inspected commit or that reviewed bytes match the intended artifact.

- **WARNING - TempleOS host artifact index commits absolute local paths.** All 40 TempleOS `json_path` values in `host-report-artifact-index-latest.json` begin with `/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/...`; holyc-inference latest manifest sources are repo-relative. Absolute paths make the committed artifact non-reproducible across machines and leak local worktree topology into audit evidence.

- **WARNING - Gate semantics diverge on empty or non-failing failure evidence.** TempleOS `host-regression-dashboard-latest.json` reports `gate_failed: true` while `gate_failures` is empty, with `failing_count: 1` and `report_failure_count: 1`. holyc-inference `bench_artifact_manifest_latest.json` reports `status: pass` even though all 6 latest artifacts have `current_commit_match: false`, 3 have `command_hash_status: unknown`, and all 6 have `freshness_status: unchecked`. The repos do not share a clear invariant for when artifact evidence is warning-only versus gate-failing.

- **WARNING - Freshness and drift evidence is observable but not enforced consistently.** TempleOS host artifact index observes `timestamp_skew_seconds: 2486` but has `max_skew_minutes: 0` and `gate_failed: false`; the dashboard observes `timestamp_skew_minutes: 30.2` with `max_skew_minutes: 0`. holyc-inference result index observes 4 command-drift groups while keeping overall `status: pass`. These reports expose useful drift signals, but the default gate posture lets stale/skewed evidence remain advisory.

## Positive Checks

- TempleOS host artifact index has complete JSON/Markdown pairing for 40 expected report stems and no orphan latest artifacts in the committed report.
- holyc-inference benchmark manifest records stronger artifact identity than TempleOS, including repo-relative source paths and file `sha256` for latest artifacts.
- holyc-inference result index reports no prompt-suite drift and no environment drift in the inspected committed artifact.
- No source-code changes were made in TempleOS or holyc-inference during this audit.

## Evidence Commands

- `git -C /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55 rev-parse HEAD`
- `git -C /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55 rev-parse HEAD`
- `git -C /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55 show HEAD:MODERNIZATION/lint-reports/host-report-artifact-index-latest.json`
- `git -C /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55 show HEAD:MODERNIZATION/lint-reports/host-regression-dashboard-latest.json`
- `git -C /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55 show HEAD:bench/results/bench_artifact_manifest_latest.json`
- `git -C /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55 show HEAD:bench/results/bench_result_index_latest.json`
