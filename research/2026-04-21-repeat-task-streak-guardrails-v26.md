# Repeat-Task Streak Guardrails (v26)

Trigger: inference task repetition in recent 40 iterations (IQ-878 x5, IQ-877 x3).

## Findings
- Add strict retry budget per task (max 2 immediate reruns), then force task rotation.
- Use exponential backoff + jitter for transient failures; avoid immediate tight rerun loops.
- Add circuit-breaker state after repeated non-progress attempts to force research/escalation.
- Enforce WIP limits and a freshness rule: each 3-task window must include at least one distinct task ID.
- Require measurable progress token before rerun (new code path, new test, or new failing assertion).

## Operational guardrails for loops
- If same task appears 3+ times in last 10 iterations, mark WARNING and demote priority.
- If same task appears 5+ times in last 20 iterations, mark STUCK and auto-create research action.
- Keep a "last-successful-delta" hash; block rerun if no material diff since prior attempt.
- Promote sibling tasks from same workstream when rerun budget is exhausted.

## References
- AWS Well-Architected Reliability: retries, timeouts, exponential backoff, jitter.
- Martin Fowler: Circuit Breaker pattern for repeated failure containment.
- Atlassian Kanban guidance: WIP limits to reduce bottlenecks and repetitive flow stalls.
