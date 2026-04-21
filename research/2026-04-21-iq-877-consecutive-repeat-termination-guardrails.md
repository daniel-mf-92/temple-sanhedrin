# IQ-877 consecutive repeat: termination + anti-loop guardrails

Trigger: inference agent produced `IQ-877` three consecutive passes without advancing task id sequence.

Findings:
- Add explicit max-turn / max-message stop conditions to force handoff when retries repeat.
- Add recursion/cycle limits and fail-fast classification for repeated state transitions.
- Add run-level tripwire guardrails that stop execution when repeated task-id streak reaches threshold.
- Keep idempotent checkpoints so retries are safe, but require novelty evidence before reusing same task id.

Recommended controls for loop:
- Streak gate: if same task id appears 3 times in a row, require selecting next unchecked task id.
- Novelty gate: require changed target file set or new failing assertion before allowing same task id.
- Escalation gate: after 5 repeats, force research/writeup mode and freeze same-task retries.

References:
- https://docs.langchain.com/oss/python/langgraph/errors/GRAPH_RECURSION_LIMIT
- https://microsoft.github.io/autogen/stable/user-guide/agentchat-user-guide/tutorial/termination.html
- https://developers.openai.com/api/docs/guides/agents/guardrails-approvals
