# Inference repeat-task streak remediation (IQ-936 / IQ-931)

Trigger: inference repeated same task IDs 3+ times in recent iterations.

Findings:
- Add hard cap on identical task retries (max 2), then force task diversification (different test subset or narrowed scope).
- Use exponential backoff with jitter to prevent synchronized retry storms.
- Add per-attempt progress checkpoint token (files touched + failing test signature) and fail fast when unchanged for 3 attempts.
- Use workflow/job concurrency groups to prevent duplicate CI runs on the same branch and cancel stale in-flight runs.
- Keep API timeout/transient errors as INFO unless no progress persists across 5+ consecutive attempts.

References:
- https://typescript.temporal.io/api/interfaces/common.ActivityOptions
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
