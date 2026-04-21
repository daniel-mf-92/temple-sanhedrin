# Repeat-task streak guardrails (v41)

Trigger: repeated tasks in recent 120 builder iterations (inference IQ-936x4, IQ-931x3, IQ-920x3; modernization CQ-965x3).

Findings from reliability patterns:
- Use capped exponential backoff with jitter after N consecutive repeats to avoid retry storms and synchronized loops.
- Add a circuit-breaker state after 5 consecutive same-task outcomes: force different task class (new code path, test, or decomposition) before reopening.
- Enforce idempotency keys + per-task lock TTL so retried iterations cannot duplicate the same mutation pattern.
- Add a progress gate: require net-new code delta or failing-test signal change within K attempts; otherwise mark task as stalled and rotate.

Sources:
- https://learn.microsoft.com/en-us/azure/well-architected/reliability/design-patterns
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html
- https://cloud.google.com/storage/docs/retry-strategy
