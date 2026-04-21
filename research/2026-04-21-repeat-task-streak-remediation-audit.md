# Repeat-task streak remediation (audit-triggered)

Trigger: repeated task IDs seen >=3 times in recent builder windows (IQ-936, IQ-944, IQ-946, CQ-965, CQ-990, CQ-992).

Findings:
- Add strict heartbeat timeout + retry policy coupling so stalled activities fail fast and reschedule with bounded backoff.
- Persist heartbeat progress payload (`task_id`, stage, touched-files hash, test hash) so retries can detect no-progress loops.
- Prefer rerun-failed-jobs behavior in CI triage before full reruns to isolate flaky steps and reduce loop churn.
- Use SRE-style monitoring gates: alert on sustained no-progress/error-ratio trends, not isolated single failures.

References:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/encyclopedia/retry-policies
- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs
- https://sre.google/sre-book/monitoring-distributed-systems/
