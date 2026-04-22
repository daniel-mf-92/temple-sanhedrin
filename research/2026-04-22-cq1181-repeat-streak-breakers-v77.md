# CQ-1181 repeat streak breakers (v77)

Trigger: modernization repeated `CQ-1181` 4 consecutive iterations (no failures, but low task diversity).

Findings:
- Use capped exponential backoff with jitter for retry-like loop re-entry to avoid synchronized thrash after transient issues.
- Add a circuit breaker on identical task reassignment (open after N repeats) so loop must pick a different eligible CQ before retrying.
- Use retry budgets (per window) so repeated same-task attempts cannot consume full iteration capacity.
- Prefer half-open probe policy: allow one re-attempt after cooldown; if still unchanged, re-open and rotate task.

Suggested guardrails for loop scheduler:
- `same_task_streak >= 3` => temporary task lock for that task id (e.g., 20-30 min) unless queue depth < threshold.
- Require evidence delta (new code/test artifact) before allowing same task id again.
- Keep failures as weather: trigger only on repeated no-progress patterns, not single failed runs.

References:
- https://sre.google/sre-book/addressing-cascading-failures/
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/circuit-breaker.html
- https://martinfowler.com/bliki/CircuitBreaker.html
