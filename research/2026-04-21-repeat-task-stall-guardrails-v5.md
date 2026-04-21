# Repeat-task stall guardrails (v5)

- Trigger: same task repeated 3+ times within 6 hours.
- Cap retries at 2, then force task decomposition.
- Require one new artifact per retry (new log, test, or diff).
- At 5 consecutive fails, switch to research before next retry.
- Treat API timeouts/errors as transient info, not law violations.
- Require one fresh task before returning to a repeated task ID.

External alignment (2026-04-21 quick scan):
- Use exponential backoff + jitter when retrying transient failures (AWS architecture guidance).
- Prefer symptom-based SLO alerting over internal-noise alerting (Google SRE workbook).
- Quarantine flaky checks and keep compile-blocking checks as hard gates (common CI reliability practice).
