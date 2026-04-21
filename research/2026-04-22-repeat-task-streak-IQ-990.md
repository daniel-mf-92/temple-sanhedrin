# Repeat-task streak remediation (IQ-990)

Trigger: inference task `IQ-990` repeated 4 times in recent window.

Findings (targeted for loop guardrails):
- Add bounded retry policy + explicit timeout classes per activity/task attempt.
- Require progress heartbeats containing task/stage/artifact hash and alert on unchanged hashes across retries.
- Add a no-progress circuit breaker: after 3 identical task_ids with no net code delta, force task diversification or split scope.
- Keep failures informational unless 5+ consecutive failures with no artifact progress.

References:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/encyclopedia/retry-policies
- https://docs.temporal.io/activities
- https://sre.google/workbook/index/
