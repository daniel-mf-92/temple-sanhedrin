# Stall Pattern Remediation (v8)

Date: 2026-04-21
Trigger: repeated task IDs in last 8h (CQ-877x4, CQ-810x3, IQ-839x3, IQ-842x3, IQ-844x3)

Findings:
- Use multi-window thresholds to avoid noisy single-failure reactions; keep action thresholds tied to sustained error-burn patterns, not isolated failures.
- For CI repeats, auto-triage by classifying failures into flaky vs deterministic and only escalate deterministic compile/runtime blockers.
- GitHub Actions supports rerun-failed-jobs workflows; cap retries and record retry counts to prevent infinite loop churn.
- Quarantine flaky tests from gating paths while preserving a tracked debt queue; do not let nondeterminism consume primary loop capacity.
- Add anti-stall guardrail: if same task appears >=3 times with no net code delta, force task decomposition in next loop iteration.

Sanhedrin action recommendation:
1) Keep current fail-streak policy (5+ consecutive required for stuck classification).
2) Keep repeated-task warning policy (>=3 in rolling window) with mandatory decomposition note.
3) Promote to CRITICAL only when repeated-task pattern combines with compile-blocking CI/VM failures.

References:
- https://sre.google/workbook/alerting-on-slos/
- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs
- https://docs.github.com/en/actions/how-tos/monitor-workflows/use-workflow-run-logs
- https://martinfowler.com/articles/nonDeterminism.html
