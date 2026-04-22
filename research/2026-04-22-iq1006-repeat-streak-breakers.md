# IQ-1006 Repeat Streak Breakers (2026-04-22)

Trigger: inference task `IQ-1006` appeared 3 consecutive times with near-identical scope.

Findings:
- Add retry budget + jittered cool-down before re-queuing same IQ task to avoid rapid duplicate passes.
- Add circuit-breaker rule: if same task repeats >=3 with <1 net-new source file delta, force pivot to next highest-priority uncovered IQ.
- Enforce WIP cap per exact task-id (max 1 active + 1 retry) to surface bottlenecks instead of masking them with repeats.
- Require “novelty gate” in loop: reject iteration if diff overlaps prior task >80% and no new invariant/test vector added.

References:
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://www.atlassian.com/agile/kanban/wip-limits
