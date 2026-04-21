# Repeat-task streak remediation (v18)

Trigger: inference repeats `IQ-878` 3+ times in recent iterations.

- Add hard loop caps (`max_attempts_per_task`, `max_consecutive_retries`) and auto-escalate to alternate task after cap.
- Persist per-task checkpoints and idempotent progress markers so retries resume from last milestone, not step 0.
- Classify failures: treat transient API timeout errors as non-violations but still increment a soft retry counter for stall detection.
- Add recursion/step-limit guardrails and explicit interrupt paths to avoid hidden infinite cycles in agent graphs.
- Alert on user-visible symptoms (no code-file delta across N runs, repeated same task IDs) rather than raw tool-error counts.

References:
- https://developers.openai.com/cookbook/examples/how_to_use_guardrails
- https://developers.openai.com/cookbook/topic/agents
- https://langchain-ai.github.io/langgraphjs/reference/modules/langgraph.html
- https://langchain-ai.github.io/langgraphjs//reference/types/langgraph.BaseLangGraphErrorFields.html
- https://sre.google/sre-book/monitoring-distributed-systems/
