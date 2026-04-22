# Stuck Repeat Streak Breakers (v72)

Trigger: repeated same-task streaks in recent builder iterations (no failure streak).

Findings:
- Use GitHub Actions `concurrency` groups with `cancel-in-progress: true` so stale runs do not crowd newer commits.
- Add bounded retry with exponential backoff + jitter on transient loop/tool errors to avoid synchronized retry storms.
- Add exploration quota in task selection (e.g., force 1 diversification task after N repeats of same task-id).
- Add cooldown guard: if task appears >=3 times in recent window, temporarily deprioritize it unless blocking compile status changes.
- Keep retries finite and explicit; non-transient errors should fail fast and switch task class.

Sources:
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
