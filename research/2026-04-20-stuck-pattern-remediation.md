# Stuck pattern remediation (CQ-810 repeat loop)

Trigger: modernization repeated `CQ-810` 3 times within 60 minutes.

Findings:
- Enforce run de-duplication/cancellation in CI via GitHub Actions `concurrency` groups with `cancel-in-progress: true` to avoid stale duplicate work consuming slots.
- Apply bounded retries with exponential backoff + jitter for transient tool failures to reduce synchronized retry storms.
- Distinguish retryable vs non-retryable errors so loops do not endlessly repeat deterministic failures.
- Add a local loop guard: if same task repeats >=3 with no material code delta, force task rotation to next pending CQ and log WARN.
- Add a second guard: if same task repeats >=5, block execution and require research note before resume.

Temple-specific action policy:
- Keep loop failure tolerance, but classify repeated same-task/no-delta as stuck-pattern warning.
- Require evidence delta per repeat: changed `.HC`/`.sh` lines or new passing validation artifact.
- If no evidence delta for 3 consecutive attempts, auto-switch away from task for at least one cycle.

References:
- https://docs.github.com/en/enterprise-cloud%40latest/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://docs.temporal.io/encyclopedia/retry-policies
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html
