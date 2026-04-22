# Repeat-task streak control for agent loops

Trigger: repeated task IDs observed 3+ times in recent iterations (`IQ-1070`, `IQ-1063`, `CQ-1152`, `CQ-1160`).

Findings (external patterns):
- Use a circuit-breaker state for task selection: after 3 consecutive same-task picks, open breaker for that task for a cooldown window; only half-open after cooldown with a single probe run.
- Use exponential backoff + jitter for retried tasks to avoid synchronized re-picks and churn loops.
- Use multi-window burn-rate style alerting for loop quality: short window catches spikes in repeats, long window confirms sustained churn before escalation.

Sanhedrin-ready policy sketch:
- `same_task_streak >= 3` => WARNING + force queue diversification.
- `same_task_streak >= 5` or `fail_streak >= 5` => CRITICAL + mandatory research + explicit cooldown for repeated task IDs.
- Keep API timeouts/errors as non-violations unless they create a sustained streak with no code progress.

References:
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://sre.google/workbook/alerting-on-slos/
