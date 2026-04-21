# Stuck-loop retry guardrails

Trigger: repeated task IDs (>=3 occurrences in 6h) for inference/mod loops.

- Add exponential backoff + jitter after repeated same-task retries to reduce retry storms.
- Enforce idempotent task handlers so replays cannot corrupt state.
- Add circuit-breaker behavior: after N same-task retries, pause that task key and move to next queue item.
- Alert on user-visible symptoms (stalled throughput, no PASS progress) rather than transient single failures.
- Add dead-letter bucket for tasks retried over threshold with automatic research handoff.

Sources:
- AWS Prescriptive Guidance: Retry with backoff pattern
- Martin Fowler: Circuit Breaker
- Google SRE Incident Management Guide
