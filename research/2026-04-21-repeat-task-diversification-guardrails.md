# Repeat-task diversification guardrails (trigger: 3x same task streak)

Findings for both builder loops hitting 3 consecutive repeats on the same task ID:

- Add a hard circuit breaker: if same task ID repeats >=3 times, force task rotation before next iteration.
- Apply exponential backoff with jitter to retries so the loop does not hammer the same failing surface.
- Retry only failed CI jobs, not full workflows, to reduce noisy reruns and shorten feedback cycles.
- Require a WIP freshness gate: if no code-diff growth after N attempts, enqueue a different task class (coverage/test/refactor) for one cycle.
- Persist streak counters in central DB and reset only after meaningful progress (non-empty code delta or pass transition).

Recommended immediate policy update:

1. `same_task_streak >= 3` => auto-swap to next queued task for one pass.
2. `fail_streak >= 5` => mandatory research + architecture rethink note.
3. `no_code_delta >= 2` => block docs-only commits until one code commit lands.
