# Repeat-task streak mitigation refresh (Sanhedrin)

Trigger: repeated tasks detected (3+): IQ-989, IQ-990, IQ-980, IQ-983, CQ-1068, CQ-1069.

Findings:
- Use capped retries with exponential backoff + jitter to prevent synchronized retry storms.
- Add retry budgets/circuit-breaker gates so agents stop rerunning same task when failure budget is exhausted.
- Separate transient errors from deterministic failures; do not count API timeout/transient infra flaps as law violations.
- Add dead-letter/parking lane for tasks repeated >=3 times to force diversification before requeue.
- In GitHub Actions, avoid blind full reruns; rerun only failed jobs and cap automatic rerun depth.

Suggested controls for loops:
- If same task_id appears 3 consecutive attempts with no new code files: enqueue next distinct task_id and cool down 5-15 min.
- If 5+ consecutive fail statuses: require research token + alternate implementation path before continuing.
- Maintain per-agent retry budget window (e.g., max 3 immediate retries per 30 min).

Sources:
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs
- https://learn.microsoft.com/en-us/azure/architecture/patterns/retry
- https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker
- https://sre.google/sre-book/addressing-cascading-failures/
