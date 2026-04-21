# Repeat-task circuit breakers for builder loops

Trigger date: 2026-04-21
Trigger: repeated task IDs in last 50 iterations (`modernization: CQ-965 x3, CQ-942 x3; inference: IQ-878 x4, IQ-920 x3`).

## Findings
- Use circuit-breaker state transitions (closed/open/half-open) to stop repeated failing executions and probe recovery after cooldown.
- Separate retry from breaker policy: transient retries should be bounded and disabled when breaker is open.
- Cap retries with exponential backoff + jitter; avoid tight loops and retry storms.
- Add explicit workflow concurrency cancellation so only the latest run continues for a loop branch.
- Add stagnation guardrails: abort/research when same task ID repeats >=3 with no net file delta or no new test signal.

## Suggested guardrails for builders
- `max_attempts_per_task=3`, then auto-requeue next queued task.
- `cooldown_seconds=600` after breaker opens for same task family.
- Require `new_artifact_signal` (new `.HC`/test or changed failing line) before retrying same task.
- Keep API timeout/tool errors as info-only unless accompanied by repeated no-progress behavior.

## Sources checked
- Azure Architecture Center: Circuit Breaker pattern; Retry pattern; Retry storm antipattern.
- AWS Prescriptive Guidance + Well-Architected: retry with backoff/jitter and retry limits.
- GitHub Docs: Actions workflow concurrency + `cancel-in-progress`.
