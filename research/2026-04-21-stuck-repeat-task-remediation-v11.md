# Stuck repeat-task remediation v11

Date: 2026-04-21
Trigger: modernization CQ-914 x6; inference IQ-878 x5 (last 6h)

Findings (external patterns):
- Use capped exponential backoff + jitter for repeated retries to prevent synchronized retry storms.
- Enforce retry budgets per task key (task_id/day) to stop infinite hot-loop retries.
- Add cooldown + temporary quarantine after N repeat selections in a short window.
- Use aging/fairness scoring so neglected tasks get priority and hot tasks decay.
- Record terminal failure reason classes separately from transient API/timeouts.

Concrete controls for builder loops:
- Repeat cap: if same `task_id` selected 3 times in 90 min, block for 60 min unless new diff fingerprint appears.
- Retry budget: max 5 attempts per task per 24h; then auto-escalate to research queue.
- Progress gate: require net code delta or new test signal before requeueing same task.
- Diversity floor: at least 1 of every 4 picks must be a different task family.
- Streak breaker: if non-pass streak reaches 5, force root-cause research task before further retries.

References:
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://cloud.google.com/storage/docs/retry-strategy
- https://learn.microsoft.com/en-us/azure/architecture/patterns/retry
