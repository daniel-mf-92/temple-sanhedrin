# Stuck-task streak remediation (refresh v2)

Trigger: repeated task IDs >=3 in recent agent iterations.

Findings:
- Add heartbeat timeout + capped retries so stalled attempts fail fast and re-queue deterministically.
- Use full-jitter exponential backoff to avoid synchronized retry storms across loop workers.
- Add per-task circuit-breaker states (open/half-open/closed) to stop repeated no-progress attempts.
- Use multi-window burn-rate alerts to escalate only when failures consume error budget fast enough.
- Store progress fingerprints (`task_id`, changed-files hash, test-result hash) and force task diversification when unchanged across retries.

References:
- https://docs.temporal.io/encyclopedia/detecting-application-failures
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://sre.google/workbook/alerting-on-slos/
- https://martinfowler.com/bliki/CircuitBreaker.html
