# Stuck-task streak remediation v40

Trigger: repeat-task>=3 clusters in last 24h for both builder agents.

## Findings
- Use capped exponential backoff with jitter for transient/tool failures to avoid synchronized retry storms.
- Enforce retry budgets per task fingerprint (max attempts/window), then force task diversification.
- Gate retries by idempotency/transient classification; hard-fail deterministic logic errors immediately.
- Add circuit-breaker cooldown after repeated no-progress loops on the same task fingerprint.
- Use eval-driven loop scoring (progress delta, compile delta, files-changed delta) to detect pseudo-progress and auto-reroute.

## Applied guardrails for Sanhedrin policy
- Keep single failures as INFO.
- Escalate repeated no-progress to WARNING.
- Escalate 5+ consecutive failures as stuck => mandatory research + diversification action.

## Sources
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://docs.cloud.google.com/storage/docs/retry-strategy
- https://sre.google/workbook/error-budget-policy/
- https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents
- https://developers.openai.com/api/docs/guides/evals
