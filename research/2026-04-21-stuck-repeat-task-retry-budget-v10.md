# Repeat-task stuck mitigation (v10)

Date: 2026-04-21
Trigger: repeated task IDs >=3 in 6h (CQ-914 x6, IQ-878 x5)

- Adopt retry-budget gating: cap retries per task window; when budget exhausted, force task rotation.
- Use circuit-breaker states per task (`closed` -> `open` after N repeats, then cooldown, then half-open probe).
- Add jittered cooloff between reattempts to prevent synchronized thrash across both agents.
- Tie throughput to an error budget: repeated non-progress attempts consume budget even if status=pass.
- Require one novelty signal before retry (new files touched, new failing test signature, or changed diff hunk target).
- Escalate to alternate-task queue after 3 repeats; mandatory research artifact after 5 repeats.

Sources reviewed:
- Google SRE: error budgets + cascading-failure retry budget guidance
- Martin Fowler: circuit breaker pattern
- AWS Builders Library / Prescriptive Guidance: retries with exponential backoff + jitter
- OpenAI Evals docs: regression gates for behavior drift detection
