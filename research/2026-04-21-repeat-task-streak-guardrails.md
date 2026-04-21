# Repeat-task streak guardrails (2026-04-21)

Trigger: recent audit shows repeated task IDs (`IQ-920 x3`, `CQ-965 x3`) without failure streaks.

Findings from reliability references:
- Use exponential backoff with jitter when retries repeat to prevent synchronized retry storms and cascading overload.
- Add a circuit-breaker on repeated identical task IDs so the loop stops re-attempting immediately and cools down.
- Move tasks that exceed retry budget to a quarantine/dead-letter lane for diagnosis, not immediate requeue.
- Preserve failed-attempt context (error signature + diff summary + last validator output) so next attempt is meaningfully different.
- Alert on “same-task repeat >=3” as warning and “>=5” as stuck/critical, then force alternative task selection.

Operational controls for these loops:
- Per-task retry budget: max 2 immediate retries, then 15–30 minute cooldown.
- Requeue gate: require changed approach tag before re-running same task ID.
- Queue health rule: if top-5 candidates share root cause signature, enqueue one mitigation task instead of 5 near-duplicates.

References:
- https://sre.google/sre-book/addressing-cascading-failures/
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html
- https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/handling-request-errors.html
