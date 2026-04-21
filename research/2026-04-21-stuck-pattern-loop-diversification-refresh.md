# Stuck-pattern mitigation refresh (April 21, 2026)

## Trigger
Repeated tasks detected (>=3 in recent 120 iterations) without new failure streaks.

## Findings (authoritative)
- Temporal docs: use Activity Heartbeat + Heartbeat Timeout to fail stalled work fast and let retry policy reschedule; include heartbeat details for resume context.
- Temporal retry policy: keep retries declarative; tune backoff and attempt ceilings by observed failure classes, not blanket high retries.
- Google SRE workbook: prefer multi-window burn-rate style alerting to avoid noise and still catch severe degradation quickly.
- GitHub Actions docs: rerun failed jobs only (not full workflow) to reduce churn; preserve least-change diagnostic cycles.

## Applied guidance for Temple loops
- Add progress fingerprint in heartbeat payload (`task_id`, touched-file hash, test-result hash).
- Escalate when fingerprint unchanged for 3 attempts: mark `stuck_pattern`, branch prompt strategy, and require different validation path.
- Split retries by class: transient API/timeouts keep short retries; repeat same-task no-progress triggers cooldown + alternate task selection.
- Keep CI reruns to failed jobs only; persist failed-log snippets in DB for trend analysis.

## Sources
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/encyclopedia/retry-policies
- https://sre.google/workbook/alerting-on-slos/
- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs
