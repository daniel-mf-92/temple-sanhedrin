# IQ-1063 repeat-streak guardrails (2026-04-22)

Trigger: inference task `IQ-1063` repeated 3 consecutive iterations.

Findings:
- Enforce explicit graph stop controls (`recursion_limit`) so looping paths hard-stop before runaway repetition.
- Read and branch on per-step metadata (`langgraph_step`) to trigger fallback behavior before recursion-limit exceptions.
- Add bounded workflow retries/heartbeats so stalled work fails fast and requeues with capped attempts.
- Use CI workflow `concurrency` + `cancel-in-progress: true` to prevent stale duplicate loop runs from consuming capacity.

References:
- https://docs.langchain.com/oss/python/langgraph/errors/GRAPH_RECURSION_LIMIT
- https://docs.langchain.com/oss/python/langgraph/graph-api
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.github.com/en/actions/concepts/workflows-and-actions/concurrency
