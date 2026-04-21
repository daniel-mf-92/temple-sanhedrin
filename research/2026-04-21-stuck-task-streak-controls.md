# Stuck-task streak controls (repeat task >=3)

- Trigger: same task_id appears 3+ times for same agent in recent window.
- Policy gate: when streak>=3, pause feature churn for that task and require one of: smaller subtask split, stronger acceptance test, or owner handoff.
- Retry budget: cap retries per task window (ex: max 3) before mandatory strategy change.
- Backoff+jitter: spread reruns to avoid synchronized retries.
- Circuit breaker: if no measurable progress after threshold attempts, open breaker and force alternate path.
- Progress proof: each rerun must show delta (new file/code path/test assertion), else auto-requeue with different approach.

References:
- https://sre.google/workbook/error-budget-policy/
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://martinfowler.com/bliki/CircuitBreaker.html
