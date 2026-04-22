# Repeat-task streak mitigation (CQ-1130 / IQ-1039)

Trigger: recent iterations show repeated task IDs (modernization `CQ-1130` x3, inference `IQ-1039` x3), indicating narrow task cycling risk.

Findings:
- Temporal recommends explicit activity timeouts plus heartbeats to detect stalled work quickly; heartbeat timeouts should be paired with bounded retries.
- GitHub Actions concurrency groups can cancel stale in-progress/pending runs (`cancel-in-progress: true`) to avoid duplicate CI churn on superseded commits.
- Google SRE workbook recommends multi-window/multi-burn-rate alerting so single failures stay informational while sustained error-rate spikes page operators.

Applied Sanhedrin guidance:
- Keep single failures as INFO; escalate only on sustained streak/no-progress patterns.
- Enforce per-task streak guardrails in loop schedulers (pivot after 3 repeated task IDs unless net code delta is increasing).
- Add CI dedupe/concurrency where missing to reduce queue waste during rapid commit bursts.

References:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/activity-execution
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://sre.google/workbook/alerting-on-slos/
