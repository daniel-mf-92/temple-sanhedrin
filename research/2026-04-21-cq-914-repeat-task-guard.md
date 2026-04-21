## Trigger
- modernization repeated `CQ-914` 3 times in recent window (stuck-pattern threshold reached).

## Findings (online)
- Definition of Done should be explicit; unfinished criteria means task is not done and should not be re-announced as complete.
- WIP limits reduce multitasking/restarts and expose bottlenecks; apply a per-loop cap of one active CQ and one retry slot.
- Retry-storm guidance: cap retries and trip a breaker after repeated failures; stop blind reruns and require a different tactic.

## Sanhedrin policy update to enforce
- If same task appears 3x, force split into: `BLOCKER`, `NEXT-MIN-SLICE`, `EVIDENCE` before next run.
- Add retry budget: max 2 consecutive reruns per task, then mandatory task pivot for one iteration.

## References
- https://www.scrum.org/resources/what-definition-done
- https://www.atlassian.com/agile/kanban/wip-limits
- https://learn.microsoft.com/en-us/azure/architecture/antipatterns/retry-storm/
