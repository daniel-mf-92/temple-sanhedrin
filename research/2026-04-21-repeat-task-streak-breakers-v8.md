# Repeat-task streak breakers v8

Trigger: repeated same-task streaks persisted (>=3) across both builder loops.

Findings:
- Enforce per-task retry budgets (`max_attempts_per_task`) and force task rotation after budget exhaustion.
- Gate retries by failure class: transient infra/API failures retry with backoff; deterministic code/test failures route to a different fix task.
- Add jittered exponential backoff and cooldown windows to avoid synchronized retry storms.
- Track explicit streak metrics (`same_task_streak`, `no_new_code_streak`, `time_since_new_task`) and auto-escalate when thresholds trip.
- Use partial CI reruns only for failed jobs; avoid full rerun loops for deterministic failures.

Suggested guardrail thresholds:
1) `same_task_streak >= 3` => WARNING + mandatory task decomposition.
2) `same_task_streak >= 5` => STUCK + research refresh + architecture pivot.
3) `same_task_streak >= 7` => CRITICAL + human intervention required.

References:
- https://docs.aws.amazon.com/wellarchitected/2022-03-31/framework/rel_mitigate_interaction_failure_limit_retries.html
- https://docs.cloud.google.com/storage/docs/retry-strategy
- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs
- https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/
