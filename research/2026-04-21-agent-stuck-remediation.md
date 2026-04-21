# Stuck-pattern remediation (3+ repeat tasks)

Trigger: repeated same-task streaks (>=3) detected for builder loops despite pass status.

Findings:
- Add capped exponential backoff with jitter for retries to avoid synchronized retries and thundering herds.
- Use a circuit-breaker state for repeated failing dependency calls, with half-open probes before full traffic restore.
- Require idempotent task execution keys so retried iterations cannot duplicate side effects.
- Use burn-rate style alerting for consecutive failures and an explicit "stuck" detector for repeated task IDs without scope expansion.
- Enforce retry budget per task ID; when exhausted, force re-planning (new task split or unblock research) instead of blind repetition.

Applied guidance for this system:
- INFO: single failures.
- WARNING: repeated failures without progress.
- CRITICAL: 5+ consecutive failures or compile-blocking CI/VM failures.
- RESEARCH trigger: same task ID repeated >=3 times in recent streak.

References:
- https://docs.aws.amazon.com/sdkref/latest/guide/feature-retry-behavior.html
- https://learn.microsoft.com/en-us/dotnet/architecture/microservices/implement-resilient-applications/implement-circuit-breaker-pattern
- https://docs.stripe.com/api/idempotent_requests
- https://sre.google/workbook/alerting-on-slos/
