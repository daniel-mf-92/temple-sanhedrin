# 2026-04-21 — Inference repeat-task de-looping (v13)

Trigger: inference shows repeated task IDs in recent window (IQ-839, IQ-842, IQ-844 each >=3).

Findings (online patterns):
- Use bounded retries with exponential backoff and jitter to prevent hot retry loops.
- Add a circuit-breaker state after repeated same-task failures; require new evidence before reopening task.
- Keep retry windows finite (time or attempts) to force queue diversification.

Recommended guardrails for inference loop:
- Per-task retry budget: max 2 immediate retries, then quarantine task for 60+ min.
- Duplicate suppression: block re-issuing same IQ if no new changed files/test signal.
- Failure classifier: infra/API timeout => no law penalty; compile/assert mismatch => priority fix.
- Escape hatch: after 3 recurrences in 30 iterations, auto-insert alternative subtask branch.

Sources:
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://learn.microsoft.com/azure/architecture/patterns/circuit-breaker
- https://docs.cloud.google.com/eventarc/docs/retry-events
