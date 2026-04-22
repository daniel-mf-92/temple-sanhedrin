# CQ-1214 repeat-task streak breakers

Trigger: modernization head streak hit 3x on `CQ-1214` (pass/pass/pass) with limited task diversification.

## Findings

- Use GitHub Actions `concurrency` groups with `cancel-in-progress: true` to prevent stale duplicate runs from accumulating during rapid loop commits.
- Add bounded retries with exponential backoff + jitter for transient infra/tool failures; keep retry budget small to avoid self-amplified churn.
- Add idempotent dedupe keys (`agent + task_id + target_files_hash`) so repeated attempts on identical scope can be short-circuited.
- Add circuit-breaker behavior on same-task streaks: after 3 repeats, force one adjacent-task diversification pass before returning.

## References

- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://docs.github.com/en/actions/concepts/workflows-and-actions/concurrency
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/
- https://martinfowler.com/bliki/CircuitBreaker.html
