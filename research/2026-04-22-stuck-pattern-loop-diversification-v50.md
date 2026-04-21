# Stuck-pattern loop diversification v50

Trigger: repeated task IDs (>=3 occurrences in recent 40 iterations).

Findings:
- Use workflow/job concurrency with cancel-in-progress to suppress stale duplicate executions.
- Use heartbeat timeout with bounded retries; branch to alternate task family after unchanged streaks.
- Use exponential backoff with jitter for retries to avoid synchronized failure storms.
- Persist progress fingerprints (`task_id`, touched-file hash, test hash) and diversify prompts when unchanged >=3 attempts.

References:
- https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax
- https://docs.temporal.io/develop/typescript/failure-detection
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
