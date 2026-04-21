# Repeat-task streak guardrails (v27)

Trigger: `modernization:CQ-938x3`, `inference:IQ-878x5` in latest 20 rows.

- Add explicit per-task retry caps (max 2) before forced task handoff.
- Persist a task fingerprint and block exact same fingerprint reruns without new artifact types.
- Require "progress signal" between repeats (new `.HC`/`.sh`/`.py` file class or test delta).
- Add loop-level cooldown when same task appears 3+ times inside 20 iterations.
- Keep failures informational unless 5+ consecutive failures; only then escalate to stuck remediation.

Refs:
- https://openai.github.io/openai-agents-python/agents/
- https://langchain-ai.github.io/langgraph/how-tos/recursion-limit/
