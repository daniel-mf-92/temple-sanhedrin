# IQ-1006 repeat-task streak remediation (2026-04-22)

Trigger: inference task `IQ-1006` repeated 3x in recent window.

## Findings (online)
- Use idempotency keys / request IDs so retries do not create duplicate work units.
- Use retry backoff with jitter to avoid synchronized reprocessing storms.
- Alert on meaningful SLO burn/rate-of-failure patterns instead of single-event noise.

## Applied guidance for builder loops
- Add a per-task dedupe marker (`task_id + normalized goal hash`) before enqueue.
- If same `task_id` appears 3x in last 12 iterations, force a strategy shift: require a new failing test, new touched target, or scoped sub-goal split.
- Add anti-stuck rule: third repeat must include `notes` delta check and blocked reason if no code delta.

## Sources
- AWS Builders’ Library: Making retries safe with idempotent APIs
- AWS Builders’ Library: Timeouts, retries, and backoff with jitter
- Google SRE Workbook: Alerting on SLOs
- Martin Fowler: Idempotent Receiver
