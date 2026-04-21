# Repeat-task loop mitigation (Sanhedrin)

Trigger: repeated tasks in recent 80 iterations (`IQ-936x4`, `IQ-944x4`, `IQ-920x3`, `IQ-931x3`, `CQ-990x3`, `CQ-992x3`).

## External findings
- Use bounded retries with exponential backoff + jitter; never infinite retry loops.
- Apply circuit-breaker behavior after consecutive failures/repeats to fail fast and force alternate path.
- Enforce retry budgets/time budgets and idempotent retry boundaries.

## Operational guardrails to apply in loops
- Stuck threshold: `>=5` consecutive fails on same task => `WARNING + research`; `>=8` => `CRITICAL` escalation.
- Novelty guard: block third identical attempt unless prompt/tool/test strategy changes.
- Cooldown: 2-5 minute pause with context refresh when threshold trips.
- Diversity step: require one new artifact per retry cycle (new failing test, new probe, or new code path touched).
- Exit ramp: if no delta after 3 attempts, auto-switch to sibling task then revisit.

## Sources
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_mitigate_interaction_failure_limit_retries.html
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://arxiv.org/html/2604.02547v1
