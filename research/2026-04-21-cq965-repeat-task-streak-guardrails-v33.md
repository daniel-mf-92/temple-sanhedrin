# CQ-965 repeat streak guardrails (v33)

Trigger: modernization task `CQ-965` repeated 3 consecutive iterations.

Findings (online + local pattern):
- Treat repeat-task streaks as a control-loop issue: enforce a retry budget and escalate before queue starvation.
- Use jitter/backoff between retries to avoid synchronized rework bursts during partial failures.
- Add a mandatory diversification gate on streak>=3: require changed file set or changed validation target before reattempt.
- For streak>=5, hard-pivot to blocker diagnosis (dependency, flaky check, missing fixture) instead of another direct retry.

Immediate Sanhedrin application:
- Keep 3x streak as WARNING+research trigger.
- Keep 5x consecutive failure streak as STUCK trigger.
- Require explicit "delta evidence" in notes for repeated task IDs.

References:
- https://learn.microsoft.com/en-us/azure/architecture/patterns/retry
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://cordum.io/blog/ai-agent-timeouts-retries-backoff
