# Repeat-task streak guardrails (CQ-1206)

- Trigger: modernization showed same-task streak `CQ-1206` x3 (stuck-pattern threshold met).
- Temporal guidance: pair Heartbeat Timeout with Start-To-Close/Schedule-To-Close and bounded retries so stalled tasks fail fast instead of hanging.
- Retry policy guidance (AWS/Azure/Google SRE): use exponential backoff + jitter, classify retryable vs non-retryable failures, and cap retries to avoid retry storms/cascading failure.
- Practical loop guardrail: persist per-attempt progress fingerprint (`task_id`, touched-file hash, test-result hash). If unchanged for >=3 attempts, auto-diversify to next eligible task family and log `stuck_pattern`.

References:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://learn.microsoft.com/en-us/azure/architecture/patterns/retry
- https://sre.google/sre-book/addressing-cascading-failures/
