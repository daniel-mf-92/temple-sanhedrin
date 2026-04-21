# Repeat-task streak remediation v34

- Trigger: repeated task streaks (>=3) observed for both builders on 2026-04-21.
- Temporal docs: long-running activities should use Heartbeat Timeout + Start-To-Close/Schedule-To-Close to detect stalled workers quickly; retries should be explicit policy, not implicit infinite loops.
- Temporal retry policy docs: keep bounded retries, backoff, and non-retryable errors to avoid retry amplification.
- Google SRE guidance: retries without jitter can cause cascading failures; use exponential backoff plus jitter.
- AWS Builders/Architecture: implement capped exponential backoff with full jitter; prefer idempotent operations and retry budgets.

## Applied guardrails for temple loops

- Add/keep progress fingerprints in heartbeat payload (`task_id`, stage, touched-file hash, test hash) and detect "no-progress" repeats.
- Auto-diversify prompt strategy at repeat count >=3; hard-escalate at >=5 consecutive failures.
- Enforce capped retries with jitter and cool-down before re-queueing same task.
- Keep API timeout/error events informational unless accompanied by no-progress streak.

## Sources

- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/encyclopedia/retry-policies
- https://sre.google/sre-book/addressing-cascading-failures/
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
