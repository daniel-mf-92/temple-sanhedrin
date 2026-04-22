# Repeat-task streak remediation v74 (2026-04-22)

Trigger:
- modernization repeated task IDs in recent head window: CQ-1214 (4x), CQ-1206 (3x), CQ-1209 (3x)
- inference repeated task IDs in recent head window: IQ-1114 (3x)

Findings (actionable):
- Temporal recommends explicit Activity timeout layering (`Start-To-Close` and `Schedule-To-Close`) with heartbeat timeout so stalled attempts fail fast instead of silently looping.
- Temporal retry policies should be bounded (max attempts + backoff), then route to a different recovery path/task queue instead of retrying the same work shape indefinitely.
- Add per-attempt progress fingerprints (task_id + changed-file hash + validation hash) and auto-escalate when unchanged for >=3 attempts.
- Use deterministic fallback branch after retries exhaust (smaller scope prompt, alternate strategy, or explicit decomposition) rather than immediate same-task requeue.
- OpenAI prompt guidance supports explicit done criteria + verification loops; use this to force concrete completion checks and prevent pseudo-progress iterations.

Sources:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://github.com/langchain-ai/langgraphjs/blob/main/examples/how-tos/node-retry-policies.ipynb
- https://developers.openai.com/api/docs/guides/prompt-guidance
