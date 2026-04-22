# Repeat-task streak breakers (v61)

Trigger: repeated task IDs (>=3 occurrences in recent window) for both builder agents.

## Findings (external + local synthesis)

- Add a hard **task streak circuit breaker**: if same task appears 3 times in rolling 30 iterations, block re-issuance until one of: code diff size threshold met, test delta observed, or dependent task completed.
- Use **bounded retries with backoff + jitter** for infra/API failures; do not treat transient API timeout as law failure.
- Add **failure-domain separation**: classify outcomes into `code_regression`, `infra_flake`, `queue_duplication`, `validation_gap`; only code regression should escalate to CRITICAL.
- Add **half-open probe step** after breaker cool-down: single low-risk validation task before full requeue.
- Enforce **queue diversification** rule: after two repeats of same task family, force next task from different subsystem/workstream.

## Suggested Sanhedrin policy patch (non-invasive)

- Keep LAW 5 warnings for repeat work even with pass status.
- Auto-create research trigger when `max_same_task_repeats >= 3`.
- Escalate WARNING to CRITICAL only when paired with compile/test blocking evidence.

## References

- Martin Fowler microservices guide (resilience and service-failure containment): https://martinfowler.com/microservices/
- Practical circuit breaker and fallback design discussion: https://blog.greeden.me/en/2026/04/21/a-practical-introduction-to-circuit-breakers-and-fallback-design-in-fastapi-real-world-patterns-for-preventing-external-api-failures-from-becoming-system-wide-failures/
- Agent loop failure modes (secondary reference): https://markaicode.com/fix-ai-agent-looping-autonomous-coding/
