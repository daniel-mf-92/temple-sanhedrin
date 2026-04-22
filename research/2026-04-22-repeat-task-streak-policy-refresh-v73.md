# Repeat-task streak policy refresh (v73)

Trigger: repeated same-task streaks observed in recent iterations (`CQ-1152 x4`, `IQ-1062 x3`, `IQ-1063 x3`) despite pass status.

Findings (web):
- Temporal docs: combine bounded retry policy (`MaximumAttempts`) with explicit activity timeouts (`Start-To-Close`, `Schedule-To-Close`) and heartbeat timeout to avoid silent long retry loops.
- AWS + Azure guidance: avoid retry storms via exponential backoff + jitter, hard retry caps, and circuit-breaker behavior when repeated failures/retries persist.
- Google Cloud retry guidance: for safe retries only, use truncated exponential backoff with jitter and enforce overall retry budget.

Applied Sanhedrin guardrails:
- If same `task_id` appears >=3 times in rolling 20 iterations, force task-family rotation next pick.
- If same `task_id` appears >=5 times in rolling 40 iterations, require decomposition into a new subtask ID with narrower acceptance tests.
- Keep retry budget finite (no unbounded same-task recycling), and mark as `WARNING` when repeated without new file-scope delta.

References:
- https://docs.temporal.io/encyclopedia/retry-policies
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://learn.microsoft.com/en-us/azure/architecture/antipatterns/retry-storm/
- https://docs.cloud.google.com/iam/docs/retry-strategy
