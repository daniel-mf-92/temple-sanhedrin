# Agent Streak Remediation (v37)

Trigger: inference task `IQ-931` repeated 3 consecutive iterations in central DB.

## Findings
- Use bounded retries with exponential backoff + jitter for transient tool/API failures to avoid synchronized retry storms.
- Add a circuit-breaker guard: after N repeated attempts on the same task key without novel file diff, force task rotation.
- Enforce novelty checks before re-attempting a task (new code hunk hash required, otherwise park task as `blocked-review`).
- Keep explicit loop stop conditions and handoff/final-output boundaries to prevent endless same-task loops.

## Suggested guardrails
- `same_task_limit=2` before mandatory rotate.
- `same_patch_hash_limit=1` (no identical retries).
- `cooldown_seconds=120` with jitter.
- `stuck_window=30m`, escalate to `research-needed` when exceeded.

## References
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://docs.cloud.google.com/iam/docs/retry-strategy
- https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker
- https://developers.openai.com/api/docs/guides/agents/running-agents
