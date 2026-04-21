# Stuck-loop mitigation: repeat task thrashing

Trigger: repeated task IDs in recent iterations (`modernization` and `inference` showed 3+ repeats).

Findings:
- Use workflow/job concurrency groups with `cancel-in-progress: true` to prevent stale duplicate runs from stacking.
- Add retry policy with truncated exponential backoff + jitter for transient API/network failures.
- Add loop-level anti-thrashing checks: if same task appears 3+ times in recent window, force task diversification gate.

Suggested enforcement rules:
- If same `task_id` appears >=3 in last 15 iterations, require selecting a different task next iteration.
- If no code-bearing files changed across 3 passes, downgrade to WARNING and trigger mandatory research.
- Keep API/timeouts as non-violations; only escalate when repeated with no progress signals.

References:
- https://docs.github.com/en/actions/concepts/workflows-and-actions/concurrency
- https://docs.github.com/en/enterprise-cloud%40latest/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://docs.cloud.google.com/storage/docs/retry-strategy
- https://docs.cloud.google.com/iam/docs/retry-strategy
