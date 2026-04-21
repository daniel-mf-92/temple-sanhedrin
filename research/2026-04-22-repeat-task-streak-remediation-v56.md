# Repeat-task streak remediation (agent loop)

Trigger: inference contiguous same-task streak (IQ-990 x4).

Findings:
- Use idempotency keys/checkpoints so retries are safe and deduplicated.
- Add exponential backoff with jitter instead of tight immediate retries.
- Add circuit-breaker threshold (e.g., 3 repeat attempts) to force task reselection.
- Add progress guard: require changed-file hash delta before allowing same task re-run.
- Route repeated transient failures to quarantine queue, not main loop.

References:
- https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker
- https://docs.cloud.google.com/storage/docs/retry-strategy
