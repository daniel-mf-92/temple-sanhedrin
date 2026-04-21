# Repeat-task circuit breakers (stuck-loop mitigation)

Trigger: repeated task IDs in recent iterations (>=3 in last 50).

- Use workflow/job `concurrency` with `cancel-in-progress: true` to avoid stale overlapping loop runs.
- Add anti-recursion guards so bot-originated commits do not trigger unbounded self-runs.
- Add retry budgets + exponential backoff with jitter for flaky operations.
- Add loop-level circuit breaker: same task repeats 3x without novelty => force task rotation.
- Add novelty gate: require changed target files/classes before reusing same task ID.
- Add queue fairness: promote oldest unattempted critical tasks once repeat count hits 2.

References:
- https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#concurrency
- https://docs.github.com/en/actions/concepts/security/github_token
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
