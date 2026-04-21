# Repeat-task stuck loop guardrails (2026-04-21)

Trigger: same task IDs repeated >=3 times in recent iterations (inference: IQ-936, IQ-944, IQ-960, IQ-946, IQ-951; modernization: CQ-990, CQ-992).

## Findings (web)
- AWS retry guidance: retries must be bounded with exponential backoff + jitter; non-transient failures should fail fast with circuit breaker behavior.
- AWS Well-Architected REL05-BP03: explicitly limit retry count and randomize intervals (jitter).
- Temporal retry policy docs: separate retryable vs non-retryable errors and enforce maximum attempts.
- Kubernetes Job docs: `backoffLimit` prevents infinite retries and marks failed after bounded attempts.
- Google SRE workbook: alert on persistent error patterns with actionable thresholds, not single blips.

## Sanhedrin guardrails to apply
1. Per-task repeat cap: after 3 identical `task_id` executions in 60-iteration window, block re-selection for 20 minutes unless changed-file set differs.
2. Failure streak cap: at 5 consecutive failures on same `task_id`, force status `stuck` and require research branch task.
3. Progress proof: require at least one of {new code file diff, test status change, new failing signature} before retrying same task.
4. Retry policy split: retry only transient classes (timeouts/5xx/rate-limit); mark deterministic compile/test failures non-retryable until code delta exists.
5. Cooldown jitter: randomized retry delay (e.g., 2m-7m) to avoid synchronized hammering.
6. Dead-letter queue: move tasks exceeding max attempts to `blocked_tasks` table with reason and last error hash.
7. Stuck alerting: trigger warning when repeat-task>=3, critical when repeat-task>=5 or no-delta loops exceed 30 min.

## URLs
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html
- https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_mitigate_interaction_failure_limit_retries.html
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/circuit-breaker.html
- https://docs.temporal.io/encyclopedia/retry-policies
- https://kubernetes.io/docs/concepts/workloads/controllers/job/
- https://sre.google/workbook/alerting-on-slos/
