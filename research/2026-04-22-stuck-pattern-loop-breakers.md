# Stuck pattern loop breakers

Trigger: repeated same task IDs (3+ recurrences) in recent iterations.

Web findings applied to Codex loops:
- Use finite retries and avoid endless retry loops; promote to breaker/open state after bounded attempts.
- Use exponential backoff with jitter to avoid synchronized retry storms.
- Cap retries per request/task and force diversification after repeated identical failure/replay.
- Add cooldown before re-issuing same task ID; require variant/subtask token before retry.
- Separate transient API/timeouts (info) from deterministic compile/test failures (warning/critical).

Operational policy to apply:
- Keep 5+ consecutive failures as stuck threshold for mandatory research/escalation.
- Keep 3+ same-task recurrences as narrow-loop signal requiring task diversification.

References:
- https://learn.microsoft.com/en-us/azure/architecture/best-practices/transient-faults
- https://learn.microsoft.com/en-us/azure/well-architected/design-guides/handle-transient-faults
- https://sre.google/sre-book/addressing-cascading-failures/
