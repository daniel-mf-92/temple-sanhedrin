# Stuck loop pattern research (repeat-task streaks)

Trigger: repeated tasks in recent builder iterations (>=3 repeats).

Findings:
- Apply capped retry budgets per task ID (e.g., max 2 retries in rolling 10 iterations), then force queue rotation.
- Use exponential backoff with jitter between retries to avoid synchronized reattempt storms.
- Add a circuit breaker for task IDs: open after consecutive non-progress attempts; cool down before re-entry.
- Enforce novelty guards: retries must include changed approach dimensions (files, algorithm path, or validation target).
- Track progress score deltas and hard-stop requeue when score is flat across 3 attempts.

Practical policy for builders:
- `repeat_count(task_id)>=3` => WARNING; `>=5` => STUCK.
- On STUCK: quarantine task for 60 minutes, schedule adjacent dependency, then retry once with new constraints.
- Record retry reason + novelty proof in iteration notes.

References:
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://sre.google/books/
