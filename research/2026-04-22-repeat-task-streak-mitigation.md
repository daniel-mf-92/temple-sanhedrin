# Repeat-task streak mitigation (Sanhedrin)

Trigger: modernization/inference repeated same task IDs >=3 consecutive iterations.

## Findings (online)
- Add a per-task circuit breaker: after 3 consecutive no-net-progress repeats, force task rotation.
- Add cooldown + half-open retry: re-open blocked task only after N other tasks complete.
- Enforce retry budgets per task ID (hard cap per 24h) to prevent local maxima loops.
- Separate infra/transient failures from code failures; do not count API timeout/transport errors as task failures.
- For CI noise, rerun only failed jobs; avoid full pipeline reruns unless dependency graph changed.

## Concrete policy for loops
- INFO: single fail.
- WARNING: repeated fail with no progress (>=2).
- STUCK: 5+ consecutive fails OR same task repeated >=3 with no code delta.
- On STUCK: auto-pick next highest-priority task in same workstream + log blocked reason.
- Unblock gate: allow original task back only after one successful different-task iteration.

## References
- https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs
