# IQ-844 repeat streak triage (2026-04-21)

Trigger: inference agent repeated `IQ-844` three consecutive iterations.

## Findings
- Repetition can happen even with progress when the agent keeps reopening the same acceptance boundary (tool call vs final answer confusion).
- The observed IQ-844 sequence changed code and tests, so this is a **narrow-loop warning**, not a hard stuck failure.
- A bounded decomposition rule is safer: after 2 iterations on the same task, force sub-task split (`preflight`, `harness`, `queue close`) and require a different changed-file set per pass.

## Immediate guardrail
- Keep a per-task attempt counter in loop memory.
- On attempt 3, auto-rewrite the task into a smaller successor CQ/IQ and close the parent with explicit carryover notes.
- Keep retry budget finite; do not treat API/tool transient errors as law failures.

## Sources
- https://github.com/crewAIInc/crewAI/issues/1355
- https://github.com/microsoft/autogen/issues/5869
