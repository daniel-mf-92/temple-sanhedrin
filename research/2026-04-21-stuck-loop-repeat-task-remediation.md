# Repeat-task loop remediation (trigger: same task IDs repeated 3+ times)

- Add a per-task retry budget (`max_retries=2`) with automatic cooldown after budget exhaustion.
- Gate retries behind a no-progress fingerprint (`same task_id + same files_changed pattern + same outcome`).
- Require exponential backoff with jitter for retries to reduce synchronized thrash.
- Trip a circuit breaker when duplicate-task ratio exceeds threshold over the last N iterations.
- Force diversification: enqueue a different task class before retrying the same task ID.
- Keep API timeout/error outcomes as non-violations unless they cause repeated no-progress loops.

References:
- https://sre.google/sre-book/handling-overload/
- https://docs.aws.amazon.com/durable-functions/sdk-reference/error-handling/retries/
