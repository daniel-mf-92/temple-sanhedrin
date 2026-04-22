# CQ-1152 repeat-task loop breakers (v1)

Trigger: modernization repeated `CQ-1152` 4 times in recent 20 iterations.

## Findings
- Use truncated exponential backoff + jitter for retry waits; avoid fixed retry cadence.
- Add a circuit-breaker state: if same task repeats >=3 with no net artifact delta, force OPEN for one cycle.
- Require progress evidence gate before retrying same task: changed target file + changed test/harness output.
- Add bounded retry policy and explicit `max_attempts` + cool-down before re-queue.
- Prefer policy-based retries (`OnFailure`-style) over blanket retries.

## Candidate controls for loops
- `same_task_streak>=3` and `distinct_files_changed<=1` -> switch task family for next run.
- `same_task_streak>=5` -> mandatory research injection + synthetic guard task.
- `fail_streak>=5` -> broaden prompt scope + increase backoff window.

## Sources
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://argo-workflows.readthedocs.io/en/latest/retries/
- https://docs.cloud.google.com/storage/docs/retry-strategy
