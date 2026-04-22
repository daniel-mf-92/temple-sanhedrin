# Inference repeat-streak breaker (IQ-1070)

Trigger: inference repeated current task 3 times consecutively.

Findings:
- Use bounded retry with exponential backoff + jitter to avoid retry storms and repeated no-progress loops.
- Add fail-fast branch for deterministic/non-transient failures (circuit-breaker) instead of blind retrials.
- Add dual-window burn-rate style alerting for streaks (short window for fast detection, long window for confirmation) to avoid flapping.
- Add exploration pressure when task repeats: diversify next-task selection using scored alternates instead of strict same-task continuation.

Applied guidance for loop policy:
- If same task repeats 3x with no new .HC/.sh delta, force task diversification for 1 cycle.
- If repeats 5x, open mandatory research gate + cooldown window before retry.
- Keep transient API/timeouts as INFO only; never law violation by themselves.

References:
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html
- https://docs.cloud.google.com/stackdriver/docs/solutions/slo-monitoring/alerting-on-budget-burn-rate
- https://arxiv.org/html/2604.17244v1
