# Stuck task streak guardrails (refresh)

Trigger: repeated task IDs in recent loop output (`IQ-920`, `CQ-965`, each seen 3x).

Findings (online):
- Temporal: use heartbeat + timeout signals to detect stalled activity quickly; rely on explicit timeout classes instead of long silent retries.
- AWS Builders Library: combine bounded retries with exponential backoff + jitter; unbounded immediate retries amplify failures.
- Google SRE workbook: treat repeated failures as burn-rate style signals and escalate when error budget is consumed quickly.

Actionable guardrails for loop agents:
- Add hard streak breaker: if same task repeats 3x with no new code-diff fingerprint, force task rotation.
- Add retry budget: max retry attempts per task window before auto-escalation to research mode.
- Add jittered cooldown between retries to avoid synchronized repeated failure patterns.
- Persist progress fingerprints (files touched + test delta) in heartbeat metadata for “no-progress” detection.
- Keep single failures INFO, repeated no-progress failures WARNING, 5+ consecutive failures STUCK.

Sources:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://sre.google/workbook/alerting-on-slos/
