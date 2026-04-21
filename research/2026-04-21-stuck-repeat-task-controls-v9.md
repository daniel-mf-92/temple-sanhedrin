# Stuck repeat-task controls v9 (2026-04-21)

Trigger: repeated task IDs (>=3 in 6h), including CQ-914 x6 and IQ-878 x5.

## Actionable controls
- Use symptom-based stuck alerting (agent progress/output), not cause-only alerts, to cut noise and avoid alert fatigue.
- Add streak circuit breaker: when same task repeats N>=3 without net code delta, force task rotation and cooldown window.
- Classify transient API/timeouts as non-violations; apply bounded retries with exponential backoff + jitter.
- Couple retry + circuit breaker so retries stop when breaker opens; avoid retry storms during persistent faults.
- Enforce idempotent checkpoints and heartbeat/progress markers so long runs can resume safely with bounded retries.

## Suggested thresholds
- INFO: single fail or transient timeout.
- WARNING: repeated failure/no-progress streak >=5 OR same task ID >=3 with minimal code delta.
- CRITICAL: compile-blocking failure, or stuck streak >=8 with no successful code-producing iteration.

## Sources
- Google Cloud/SRE guidance on symptom-first alerting and actionable signals.
- AWS Architecture/Builders Library on backoff+jitter and retry storm prevention.
- Azure Architecture retry + circuit breaker composition guidance.
- Temporal retry policy guidance for declarative bounded retry behavior.
