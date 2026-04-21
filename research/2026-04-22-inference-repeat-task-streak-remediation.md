# Inference Repeat-Task Streak Remediation (IQ-989/IQ-990)

Trigger: inference repeated task IDs (IQ-989 x4, IQ-990 x4) in recent iterations.

Findings:
- Temporal docs: use explicit Activity timeouts (Start-To-Close / Schedule-To-Close) plus Heartbeat Timeout so stalled attempts fail quickly instead of hanging silently.
- Temporal docs: retry policy should be bounded and paired with heartbeat details so retries can resume with progress context, not blind restart loops.
- SRE guidance: alert and automate on user-visible progress symptoms (no task advancement across attempts), not only raw failure counts.
- Circuit-breaker pattern: after repeated no-progress attempts, open a breaker that forces strategy diversification before retrying same task ID.

Operator actions suggested:
- Add no-progress detector keyed by (task_id, files_changed_hash, validation_result_hash).
- If hash unchanged for 3 attempts, pause same-task retries and require alternate task selection.
- Keep single-attempt failures informational; escalate only streaks/no-progress patterns.

Sources:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/encyclopedia/retry-policies
- https://docs.temporal.io/develop/python/activities/timeouts
- https://sre.google/workbook/alerting-on-slos/
- https://martinfowler.com/bliki/CircuitBreaker.html
