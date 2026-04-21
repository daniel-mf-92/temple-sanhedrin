# Repeat-task streak guardrails v16

Trigger: repeated task IDs in recent window (modernization: CQ-914 x6; inference: IQ-844 x3, IQ-861 x3).

## Applied guardrails
- Add task-attempt budget: hard-stop after 3 consecutive fails on same task_id.
- Use retry policy only for transient/tool errors: truncated exponential backoff + jitter.
- Enforce idempotent task writes (dedupe key = repo + task_id + diff-hash).
- Add cooldown quarantine for repeated task_id (skip for next 5 scheduler cycles).
- Inject diversification rule: after 2 repeats, force nearest unblocked sibling task.
- Store terminal failure reasons as structured enums (not free-text) to improve rerouting.

## References
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.cloud.google.com/storage/docs/retry-strategy
- https://learn.microsoft.com/en-us/azure/azure-functions/functions-idempotent
