# Stuck-loop retry guards (repeat-task pattern)

Trigger: repeated tasks >=3 in recent iterations (inference: IQ-936x4, IQ-931x3, IQ-920x3; modernization: CQ-965x3, CQ-990x3, CQ-992x3).

Findings (operationally relevant):
- Keep transient CI/API failures as non-violations; classify and retry with bounded exponential backoff + jitter.
- Use explicit retry budgets per task_id (max attempts/window), then force task switch when budget exceeded.
- Add dual thresholds: warning at repeated-task>=3; critical only if consecutive failures>=5 with no code progress.
- Re-run only failed jobs/steps in GitHub Actions to reduce noise and isolate flaky failures.
- Use burn-rate style alerting windows to avoid paging on spikes and surface sustained degradation.

References:
- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html
- https://docs.cloud.google.com/stackdriver/docs/solutions/slo-monitoring/alerting-on-budget-burn-rate
