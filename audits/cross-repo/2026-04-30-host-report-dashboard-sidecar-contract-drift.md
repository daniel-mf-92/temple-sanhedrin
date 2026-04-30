# Cross-Repo Audit: Host Report Dashboard Sidecar Contract Drift

Audit timestamp: 2026-04-30T14:42:36+02:00

Audit angle: cross-repo invariant checks. This pass inspected the current read-only sibling worktrees for TempleOS host-report health/index artifacts and holyc-inference benchmark dashboard sidecars. No TempleOS or holyc-inference source files were modified. No QEMU or VM command was executed.

## Scope

- TempleOS read-only checkout: `/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55`
- holyc-inference read-only checkout: `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55`
- Sanhedrin audit repo: `/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55`
- LAWS.md focus: Law 2 air-gap evidence, Law 5 meaningful validation evidence, Law 7 blocker visibility, and the reporting plane needed for retroactive audits.

## Invariant

Host-side evidence dashboards that are used by Sanhedrin or CI should expose a common artifact contract:

- a normalized gate field that means the same thing in both repos;
- explicit sidecar completeness for machine output, human output, tabular output, and CI output;
- a clear distinction between advisory observations and release-blocking findings;
- local-only handling for any QEMU or Book-of-Truth evidence.

TempleOS is moving toward a report-pair index keyed on `gate_failed`, JSON/Markdown hashes, generated timestamps, orphan latest artifacts, and failing report gates. holyc-inference is moving toward dashboard sidecar completeness keyed on lowercase `status`, CSV/Markdown/JUnit presence, and dashboard digest inputs. Those contracts overlap but do not match.

## Summary

Found 5 findings: 4 warnings and 1 info. No guest networking, WS8 networking task, or VM launch was observed or executed. The drift is in the host evidence contract: TempleOS can mark report health as `blocked` while `gate_failed=false`, and holyc-inference can mark dashboard digests `pass` while included dashboards contain planned rows or drift counters. A cross-repo reader cannot safely compare these artifacts without repo-specific adapters.

## Findings

1. **WARNING - TempleOS health score can be blocked while its gate passes.**
   Evidence: `automation/host-report-health-score.py` computes `health_status` as `blocked`, `degraded`, `healthy`, or `excellent` from score and findings, but only puts strings into `gate_failures` for input errors or optional `--min-score` / `--max-findings` gates. The current `MODERNIZATION/lint-reports/host-report-health-score-latest.json` reports `health_status=blocked`, `health_score=28`, `total_finding_count=14`, `failing_component_count=2`, and `gate_failed=false`.

2. **WARNING - TempleOS artifact index treats orphan latest artifacts and failing child gates as release failures, but holyc-inference sidecar audit only verifies file-shape sidecars.**
   Evidence: `automation/host-report-artifact-index.py` adds gate failures for missing JSON/Markdown, invalid JSON, zero-byte pairs, orphan latest stems, stale/future timestamps, failing child report gates, Markdown/JSON gate mismatch, optional key order, and size budgets. The current TempleOS artifact index has `gate_failed=true`, `expected_report_count=80`, `paired_artifact_count=80`, and `orphan_latest_artifact_count=3`. By contrast, `bench/dashboard_sidecar_audit.py` marks a dashboard pass when JSON is valid and CSV, Markdown, and JUnit sidecars exist; the current holyc-inference sidecar audit reports `status=pass`, `dashboards=4`, `findings=0`, and `missing_sidecar_dashboards=0`.

3. **WARNING - holyc-inference dashboard digest does not elevate planned benchmark states or drift counters into findings.**
   Evidence: `bench/dashboard_digest.py` derives dashboard findings from summary keys named `findings`, `failures`, `violations`, or `regressions`, then treats a raw status of `pass`, `ok`, or `success` as `pass`. The current `bench/dashboards/bench_trend_export_latest.json` reports `status=pass` while its summary includes `status_counts={'pass': 81, 'planned': 8}`, `latest_status_counts={'pass': 6, 'planned': 1}`, and drift counters for `command_sha256=4`, `environment_sha256=4`, and `launch_plan_sha256=3`. The current `dashboard_digest_latest.json` still reports `status=pass`, `dashboards=3`, `findings=0`, and `total_dashboard_findings=0`.

4. **WARNING - sidecar completeness means different things across repos.**
   Evidence: TempleOS `ArtifactPair` captures JSON path, Markdown path, byte counts, SHA-256 hashes for each file and the pair, generated timestamp, report gate, Markdown gate, sorted-key status, age/future status, and JSON parse errors. holyc-inference `DashboardSidecarRecord` captures JSON validity plus CSV, Markdown, and JUnit sidecar presence. TempleOS currently has no JUnit/CSV sidecar expectation in the artifact index; holyc-inference currently has no pair hash, generated-at freshness, orphan-latest, Markdown gate mismatch, or child-gate propagation in the sidecar audit. Cross-repo retention or CI dashboards therefore cannot use "sidecars complete" as a portable evidence-quality statement.

5. **INFO - both inspected dashboard paths are host-side only and do not launch QEMU.**
   Evidence: holyc-inference dashboard tools state they consume existing artifacts and never launch QEMU, and the inspected commands only read JSON/Markdown source or summarize existing files. TempleOS report health/index tools read `MODERNIZATION/lint-reports` artifacts and do not execute VM commands. This audit did not run QEMU; if future reproduction requires a VM, the command must include `-nic none` or legacy `-net none`.

## Risk

Retroactive Sanhedrin audits can miscount cross-repo evidence quality if they read only one field:

- `gate_failed=false` can hide a TempleOS `health_status=blocked` unless optional thresholds were supplied.
- `status=pass` can hide holyc-inference planned benchmark states and drift counters.
- `sidecar present` can mean hashed JSON/Markdown pair integrity in TempleOS, but only CSV/Markdown/JUnit presence in holyc-inference.

This affects Law 5 and Law 7 historical conclusions because weak or split-brain validation evidence can look green depending on which repo-specific surface is parsed.

## Recommendations

- Define a shared report envelope with `result`, `gate_failed`, `release_blocking`, `finding_count`, `advisory_count`, `generated_at`, `artifact_hashes`, and `sidecar_classes`.
- Make TempleOS health scoring set a distinct gate field such as `health_gate_failed` when `health_status=blocked`, even if the legacy `gate_failed` remains threshold-driven.
- Make holyc-inference dashboard digest count non-pass child states such as `planned`, `unknown`, and drift counters as advisory or release-blocking findings according to an explicit policy flag.
- Add a Sanhedrin adapter that normalizes TempleOS `gate_failed` and holyc-inference `status` into one schema before cross-repo trend aggregation.

## Read-Only Evidence Commands

```bash
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/host-report-health-score.py | sed -n '92,240p'
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/host-report-artifact-index.py | sed -n '333,722p'
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/dashboard_sidecar_audit.py | sed -n '21,236p'
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/dashboard_digest.py | sed -n '70,293p'
python3 - <<'PY'
import json, pathlib
for path in [
    pathlib.Path('/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/MODERNIZATION/lint-reports/host-report-health-score-latest.json'),
    pathlib.Path('/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/MODERNIZATION/lint-reports/host-report-artifact-index-latest.json'),
    pathlib.Path('/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/dashboards/dashboard_digest_latest.json'),
    pathlib.Path('/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/dashboards/dashboard_sidecar_audit_latest.json'),
    pathlib.Path('/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/dashboards/bench_trend_export_latest.json'),
]:
    data = json.loads(path.read_text())
    print(path.name, data.get('gate_failed'), data.get('status'), data.get('summary', {}))
PY
```
