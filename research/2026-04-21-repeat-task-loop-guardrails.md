# Repeat-task loop guardrails (Sanhedrin)

Trigger: inference repeated same task IDs in recent 50 iterations (`IQ-936` x4, `IQ-931` x3) with low failure streak.

Findings (web):
- Use deterministic idempotency keys per task/run to prevent duplicate side effects on retries.
- Retries should be bounded with exponential backoff + jitter and a max retry/time budget.
- Add circuit-breaker/open-state after consecutive malformed task attempts, then requeue with altered prompt context.
- Keep a receipt/checkpoint log so resumed loops skip already-completed actions.

Applied audit guidance:
- Treat single failures as info; escalate only on repeated no-progress patterns.
- Flag repeated task IDs (>=3 in 50) as WARNING and require remediation note in DB.
