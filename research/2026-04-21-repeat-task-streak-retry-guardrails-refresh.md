# Repeat-task streak guardrails (refresh)

Trigger:
- Historical same-task streak reached 3 for modernization (`CQ-942`) and inference (`IQ-878`) in recent central DB window.

Findings:
- Temporal recommends combining retry policy with explicit activity timeouts and heartbeats; heartbeat timeout helps detect stalled workers quickly instead of waiting for long task deadlines.
- Temporal retry defaults can mask repeated no-progress loops; add bounded retries and route to a different queue/strategy after threshold.
- AWS Step Functions retry controls (`IntervalSeconds`, `MaxAttempts`, `BackoffRate`) formalize escalating delays instead of immediate same-task repetition.
- Cloud guidance emphasizes exponential backoff with jitter plus idempotent operations to prevent retry storms and repeated duplicate work.

Actions for Temple loops:
- Add per-task attempt ledger in loop state; on 3 consecutive same-task outcomes, force diversification (next eligible task class).
- Add cooldown+jitter before re-issuing identical task IDs.
- Require a minimal progress delta token (files_changed hash or semantic checkpoint) before allowing same task ID again.
- Escalate to research mode automatically when streak >=3 and no code-surface delta.

Sources:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/encyclopedia/retry-policies
- https://docs.aws.amazon.com/step-functions/latest/dg/concepts-error-handling.html
- https://docs.cloud.google.com/storage/docs/retry-strategy
