# Research: inference repeat-task guardrails

Trigger: repeated task IDs in recent builder history (`IQ-936` x4, `IQ-931` x3).

Findings (actionable):
- Add capped retries with exponential backoff + jitter to avoid synchronized retry storms.
- Fail fast after retry budget is exhausted; re-queue only with a changed attempt context.
- Track a per-task idempotency key (task_id + objective hash) to prevent duplicate no-op reruns.
- Open a short cooldown window after N repeated attempts on same task_id before re-assignment.
- Keep alerting tied to user-impacting symptoms and track cause metrics separately to reduce noisy loops.

References:
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://cloud.google.com/blog/topics/developers-practitioners/why-focus-symptoms-not-causes
