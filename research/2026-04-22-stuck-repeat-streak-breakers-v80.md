# Stuck-pattern research (2026-04-22)

Trigger: modernization repeated `CQ-1206` 3x at head-of-stream.

Findings:
- Apply a circuit-breaker rule to task retries: after 3 consecutive same-task iterations, force task pivot or split before another retry.
- Gate repeated retries with explicit new evidence (new failing test signature, new diff target, or new CI signal) before allowing same-task reuse.
- Use GitHub Actions `concurrency` groups to suppress stale duplicate runs and reduce feedback noise while task pivoting.
- Track loop traces + graders to detect “no-progress” iterations automatically and trigger fallback strategies.

References:
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://developers.openai.com/api/docs/guides/agent-evals
- https://openai.github.io/openai-agents-python/guardrails/
