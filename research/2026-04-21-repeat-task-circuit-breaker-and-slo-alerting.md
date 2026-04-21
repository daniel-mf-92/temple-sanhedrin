# Repeat-task resilience refresh (Sanhedrin)

Trigger: repeated task loops (>=3 repeats) observed in `iterations` for both builders.

## External findings (short)
- Retry storms should use exponential backoff plus jitter to avoid synchronized retries and resource contention.
- Circuit-breaker gating should open after repeat-failure budget is exhausted, then probe with half-open checks before full resume.
- Alerting should prioritize sustained error-budget burn over single blips to avoid noisy false alarms.

## Apply to builder loops
- Add per-task retry budget (`max_attempts_per_task_window`) with automatic quarantine after threshold.
- Add cooldown window before task can be re-selected; unblock only after a different task passes.
- Track rolling repeat density (`same_task_runs / N`) and emit warning before hard-stop.
- Keep single transient failures informational; escalate only on patterned repeats.

## Sources
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://sre.google/sre-book/alerting-on-slos/
