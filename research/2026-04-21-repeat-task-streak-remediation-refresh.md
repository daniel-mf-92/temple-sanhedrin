# Repeat-task streak remediation (refresh)

Trigger: repeated task IDs >=3 in recent 100 iterations (both builder agents).

- Use capped exponential backoff with full jitter between retries to prevent synchronized retry storms.
- Add circuit-breaker state per task ID: open after threshold failures, half-open probe after cooldown, then close on success.
- Split alerts into fast-burn + slow-burn windows so one noisy burst does not page repeatedly.
- Enforce retry budget per task ID (max attempts/time window), then force diversification to a different queue item.
- Record deterministic “reason tags” (timeout/api/transient/code/test) and suppress escalation for API/timeout-only streaks.

References:
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://sre.google/workbook/alerting-on-slos/
- https://docs.cloud.google.com/stackdriver/docs/solutions/slo-monitoring/alerting-on-budget-burn-rate
