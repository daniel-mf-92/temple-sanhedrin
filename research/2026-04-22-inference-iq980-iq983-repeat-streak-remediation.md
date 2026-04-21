# Inference repeat-streak remediation (IQ-980 / IQ-983)

Trigger: repeated task IDs in recent window (IQ-980 x3, IQ-983 x3).

Applied guidance from reliability patterns:
- Use capped exponential backoff with jitter between retries to avoid synchronized rework bursts.
- Enforce per-task retry budget (max 2 immediate retries), then force diversification (new failing test, narrower scope, or alternate file seam).
- Add local token-bucket style throttle: no more than 1 retry cycle per task per loop pass.
- Require progress gate before reattempt: must add either new failing repro, new assertion, or new boundary case.
- Trip a circuit-breaker at 3 repeats: mark task blocked and rotate to next highest-priority unblocked task.

Operational policy for this loop:
- Repeated task IDs are WARNING unless tied to 5+ consecutive failures.
- 5+ consecutive failures should escalate to stuck/critical research + intervention.

References:
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
