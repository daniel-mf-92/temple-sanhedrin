# 2026-04-22 — IQ-1092 repeat-streak mitigation

Trigger: inference loop repeated `IQ-1092` for 3 consecutive iterations.

Findings:
- Use burn-rate style dual-window alerting for loop health (fast + slow windows) to avoid overreacting to single noisy failures while still detecting persistent stalls.
- Track precision/recall for loop alerts (not just raw fail count) so repeated-no-progress patterns are surfaced without paging on transient API/weather errors.
- Add retry jitter on planner/commit retries to prevent synchronized repeat-attempt bursts across loop restarts.
- Add task dedup lock with TTL (`task_id + commit_head`) so same task cannot be selected >N times in a row without explicit override/research hook.
- Escalate automatically to research mode when same task streak >=3 and diff footprint is unchanged.

References:
- https://sre.google/workbook/alerting-on-slos/
- https://docs.cloud.google.com/stackdriver/docs/solutions/slo-monitoring/alerting-on-budget-burn-rate
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
