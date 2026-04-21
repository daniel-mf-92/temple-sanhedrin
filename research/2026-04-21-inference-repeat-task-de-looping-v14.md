# Repeat-task de-looping guardrails (v14)

Trigger: repeated task IDs (3+ recurrences) across modernization/inference in latest 120 iterations.

Applied findings (online-backed):
- Enforce bounded retries per task fingerprint (`max_attempts`), then force queue advance.
- Use exponential backoff with jitter between retries to prevent synchronized retry storms.
- Add idempotency key per task+diff fingerprint so duplicate replays do not count as progress.
- Alert on symptom ("no forward progress for N iterations") instead of raw single-failure count.
- Add circuit-breaker state after repeated no-progress loops: cooldown + mandatory alternate task selection.

Operational thresholds for this project:
- INFO: single fail.
- WARNING: repeated fail/no-progress without movement.
- CRITICAL research trigger: >=5 consecutive fails OR same task >=3 recurrences.

Sources consulted:
- Google SRE book (Practical Alerting / monitoring principles): https://sre.google/sre-book/table-of-contents/
- AWS retry guidance (exponential backoff + jitter): https://docs.aws.amazon.com/sdk-for-kotlin/latest/developer-guide/retries.html
- Stripe idempotent request pattern (idempotency keys): https://docs.stripe.com/api/idempotent_requests
