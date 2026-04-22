# Repeat-task streak breakers (v76)

Trigger: modernization:CQ-1162x4, inference:IQ-1070x3 in recent window.

- Add hard circuit breaker: after 3 repeats of same task_id without new code artifact class, force queue pivot to different subsystem for 1 cycle.
- Add jittered retry delay for same-task reattempts (5m, 11m, 23m cap 30m) to avoid synchronized livelock loops.
- Require idempotent “progress token” per task (new invariant/test/file touched); no token => auto-demote task priority.
- Enforce WIP cap per recurring theme (max 1 active repeat-family task) so throughput is finish-first, not restart-first.
- Add burn-rate alert on streaks: warning at 3 repeats/12 runs, critical at 5 consecutive non-progress repeats.
- Couple retry + circuit-breaker states in scheduler metadata so opened circuit blocks immediate reselection until cool-down and alt-task completion.

Sources reviewed: AWS retry/backoff guidance, Azure circuit breaker pattern, Little’s Law/WIP flow control references.
