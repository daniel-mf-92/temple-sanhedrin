# Stuck Task Repeat Remediation v42

Trigger: repeated task IDs (>=3), including modernization `CQ-914x6` and inference `IQ-878x5`.

## Web-backed guardrails
- Use truncated exponential backoff with full jitter on retrying failed loop steps to prevent synchronized retry storms.
- Add a circuit breaker: after N repeat picks of the same task without new files/tests, pause that task for a cooldown window and force queue reselection.
- Use GitHub Actions concurrency groups to cancel superseded runs and keep only freshest loop execution per branch.
- Classify retriable vs permanent failures; do not retry permanent policy/schema failures.
- Enforce no-progress detector: if same task ID appears 3 times with unchanged file set, auto-escalate and emit research/audit warning.

## Sources
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://docs.cloud.google.com/iam/docs/retry-strategy
- https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker
- https://learn.microsoft.com/en-us/azure/architecture/patterns/retry
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
