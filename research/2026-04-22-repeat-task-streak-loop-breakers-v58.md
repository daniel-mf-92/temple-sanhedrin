# Repeat-task streak loop breakers (v58)

Trigger: repeated builder task IDs in recent window (>=3) without hard failures.

Applied guidance:
- Use bounded retries per task-id and reset only after observable artifact delta.
- Add exponential backoff + jitter to avoid synchronized reattempt storms.
- Gate retries on idempotent steps only; move non-idempotent tasks to manual review lane.
- Enable CI workflow/job concurrency groups with cancel-in-progress for stale runs.
- Trip a circuit breaker after threshold retries; force queue diversification for N cycles.

Sources:
- Google SRE: Addressing Cascading Failures
- AWS Builders' Library: Timeouts, retries, and backoff with jitter
- GitHub Actions docs: control workflow concurrency
- Martin Fowler: Circuit Breaker
