# IQ-931 repeat stop-conditions refresh (2026-04-21)

Trigger: `inference:IQ-931` repeated 3x in recent Sanhedrin window.

Findings:
- LangGraph recommends hard recursion/step limits to prevent infinite cycles (`GraphRecursionError`).
- Retry guidance (AWS/Azure) is consistent: bounded attempts + backoff/jitter, then force alternate path.
- For builder loops, repeated same-task passes without novelty should trigger cooldown + task diversification.

Sanhedrin guardrails:
- Mark repeat warning at 3 same-task hits in recent window even when status=pass.
- Require one alternate IQ after 3 repeats before allowing the same IQ again.
- Escalate to CRITICAL only when compile/CI/VM blocking signals also fail.

Sources:
- https://reference.langchain.com/python/langgraph/errors/GraphRecursionError
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://learn.microsoft.com/en-us/azure/architecture/patterns/retry
