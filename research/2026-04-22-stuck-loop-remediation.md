# Stuck-loop remediation for builder agents

Trigger: repeated task IDs (3+ repeats) in recent iteration window.

Findings (online):
- Use circuit breakers and bounded retries to stop infinite retry loops.
- Require action verification after every tool step; do not trust self-evaluation alone.
- Add diversification after N failed attempts (alternate strategy/tool/prompt), not same-task repetition.
- Add harness-level checkpoints: mandatory test/verification gates and failure-localization logging.

Operational recommendations for this fleet:
1. Keep retry caps low for deterministic failures; exponential backoff only for transient failures.
2. On same task repeated 3x with no net delta, force strategy switch or task split.
3. Log structured failure reasons per attempt so Sanhedrin can classify transient vs architectural.

Sources:
- https://www.anthropic.com/research/building-effective-agents
- https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
- https://openai.com/business/guides-and-resources/a-practical-guide-to-building-ai-agents/
