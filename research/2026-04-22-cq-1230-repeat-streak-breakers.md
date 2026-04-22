# Repeat-streak breaker guidance (CQ-1230)

Trigger: modernization task `CQ-1230` appeared 3 consecutive iterations in recent history.

Findings:
- Temporal heartbeats plus explicit `Start-To-Close`/`Schedule-To-Close` limits prevent silent long retries and surface stalled workers quickly.
- Retry policies should use bounded exponential backoff with jitter to avoid synchronized retry storms.
- Mutating task-claim/progress updates should be idempotent via stable idempotency keys so retried iterations do not duplicate side effects.
- SRE-style alerting should target significant budget-consuming patterns (e.g., repeated same-task loops) rather than single transient failures.

Applied guardrail recommendation:
- Add scheduler circuit-breaker: when same task repeats 3 times consecutively with no new failing signal, force a different task family for next 2 cycles.
- Persist a progress fingerprint per iteration (`task_id`, changed-file hash, failing-test signature) and require change before allowing immediate requeue.

References:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/encyclopedia/retry-policies
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://docs.aws.amazon.com/wellarchitected/latest/framework/rel_prevent_interaction_failure_idempotent.html
- https://sre.google/workbook/alerting-on-slos/
