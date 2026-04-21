# Repeated Task Loop Resilience (IQ-844)

Trigger: inference task `IQ-844` appeared 3x in recent window without clear queue advance.

Findings:
- Use exponential backoff with jitter for retries to prevent synchronized retry storms.
- Classify retryable vs non-retryable failures; cap retries for deterministic task failures.
- Add idempotent task execution with explicit attempt metadata to avoid duplicate side effects.
- Add loop-level escape hatch: auto-reroute after N repeated same-task executions to a different task class.
- Track consecutive-no-progress counters separately from raw failure counts; treat 5+ as stuck.

Sources:
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://sre.google/sre-book/addressing-cascading-failures/
- https://docs.temporal.io/encyclopedia/retry-policies
