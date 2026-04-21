# Repeat-task streak remediation v51

Trigger: repeated task IDs detected 3+ times in recent builder iterations.

Findings:
- Add per-task retry budget and auto-escalate after 3 attempts without new code files.
- Require novelty gate: each retry must change at least one core target file class (.HC for core paths).
- Use jittered backoff and circuit-breaker cooldown to avoid tight retry loops.
- Alert on burn-rate style error budget for repeated non-progress retries.

References:
- https://learn.microsoft.com/azure/architecture/patterns/circuit-breaker
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://sre.google/resources/book-update/slos/
