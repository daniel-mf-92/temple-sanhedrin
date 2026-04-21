# Loop stall guardrails for repeated task IDs

Trigger: repeated task IDs observed (`CQ-877` x4, `IQ-839/842/844` x3).

Findings:
- Add fingerprint-based repetition detection (same task/tool signature repeated >=3) and force a strategy change prompt.
- Add cooldown/backoff after no-progress cycles to reduce thrash and token waste.
- Add task dedup + in-progress lock so same task ID cannot be re-selected while recent attempts exist.
- Route repeated-task events to a dead-letter queue after N retries with explicit human triage note.
- Keep AGENTS/task context compact and current so stale instructions do not cause rework loops.

Sources:
- https://arxiv.org/html/2603.05344v3
- https://arxiv.org/html/2604.05854
- https://blog.logrocket.com/ai-agent-task-queues/
- https://addyosmani.com/blog/self-improving-agents/
