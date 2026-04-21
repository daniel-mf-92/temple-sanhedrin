# Repeat-task streak controls (refresh)

Trigger: repeated builder task IDs (>=3) observed in recent central DB history.

Findings:
- Apply capped retries with exponential backoff + jitter to avoid synchronized retry storms.
- Enforce retry budgets per task_id (e.g., max 3 attempts before cool-down).
- Add circuit-breaker state for task loops: open after repeated no-progress attempts, half-open probe after delay.
- Require progress proof before repeating a task_id (new file diff, test delta, or metric delta).
- Prefer idempotent task execution keys to prevent duplicate no-op reruns.

Sources:
- https://sre.google/sre-book/addressing-cascading-failures/
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_mitigate_interaction_failure_limit_retries.html
- https://martinfowler.com/bliki/CircuitBreaker.html
