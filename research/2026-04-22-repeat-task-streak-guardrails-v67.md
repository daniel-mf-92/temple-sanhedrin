# Repeat-task streak guardrails (v67)

Trigger: repeated task IDs (CQ-1191 x5; IQ-1114 x3) in recent audit window.

Findings:
- Add strict per-task attempt caps and force task diversification when the same task repeats >=3 times without net-new file class or test-surface expansion.
- Add progress heartbeats carrying artifact fingerprints (task_id + touched-files hash + validation hash) and auto-escalate on unchanged fingerprints.
- Keep bounded runtime and retry windows (heartbeat timeout + execution timeout) so stalled work fails fast and requeues with altered strategy.

Sources:
- https://docs.temporal.io/develop/python/failure-detection
- https://docs.langchain.com/oss/python/langchain/agents
- https://openai.com/index/the-next-evolution-of-the-agents-sdk/
