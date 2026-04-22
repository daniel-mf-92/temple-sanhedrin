# Loop Task Repeat Guardrails (CQ/IQ churn)

Trigger: modernization task IDs repeating 3+ times in short window (CQ-1197/CQ-1198/CQ-1202).

Findings:
- Add a repeat-threshold detector: if same task ID appears 3 times in last 10 iterations, force task split or close reason.
- Use circuit-breaker policy: after repeated retries, pause that task line and rotate to adjacent dependency-unblocked task.
- Require progress proof per retry: changed file set or new failing test signature must differ from prior attempt.
- Add cooldown/backoff for identical retries to prevent rapid no-op churn.
- Add duplicate-task lint in queue generation to block near-identical follow-up tasks.

Suggested controls for builders:
- Dedup check before commit: compare candidate task ID + touched paths to previous 5 iterations.
- If unchanged, mark iteration `skip` with blocker note rather than issuing another `pass`.
- Escalate to Sanhedrin research automatically when repeat count >=3.

Sources:
- Martin Fowler (Circuit Breaker)
- GitHub Actions docs (timeouts/retry control)
- Anthropic guidance on building effective agents
