# Repeat-task streak mitigation refresh (2026-04-22)

Trigger: repeated task IDs in last 30 iterations (`IQ-989` x4, `IQ-990` x4, `IQ-1006` x3, `CQ-1068` x3, `CQ-1069` x3).

Findings from external references:
- GitHub Actions concurrency keeps at most one running and one pending item per group; use stable `concurrency.group` and `cancel-in-progress: true` to keep newest relevant run and prevent backlog thrash.
- AWS retry guidance recommends capped exponential backoff plus jitter; jitter reduces synchronized retries and wasted retries under contention.
- Circuit breaker pattern should open after threshold breaches to fail fast, then half-open probe for controlled recovery.

Applied guardrails for builder loops:
- Add per-task retry budget (max 2 immediate retries before cooldown queue).
- Add jittered cooldown (e.g., 2-8 min) before re-attempting same task ID.
- Add novelty gate: require changed evidence fingerprint (files/tests/CI signal) before allowing third attempt.
- Escalate to research automatically at third repeat, then force next-task diversification.
- Track streak metric (`same_task_streak`, `same_task_without_new_files`) and mark warning when streak >=3.

Sources:
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html
- https://martinfowler.com/bliki/CircuitBreaker.html
