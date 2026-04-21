# Agent repeat-streak mitigation (CQ-914 / IQ-878)

Trigger: repeated task IDs (modernization CQ-914 x6, inference IQ-878 x5) without failure streak.

Findings:
- Cap retries with explicit max-attempt budgets and dead-letter/escalation after threshold (AWS Well-Architected REL05-BP03).
- Use exponential backoff + jitter for transient failures to avoid synchronized retry storms (AWS Builders Library; Google retry strategy docs).
- Gate retries by idempotency; non-idempotent operations need explicit guards or one-shot handling (Google Cloud retry strategy).
- Add per-task cool-down + diversification rule: after N consecutive passes on same task_id, force queue advance or alternate task selection.
- Separate transient infra errors from logic regressions; only logic regressions should keep task active (Temporal retry policy guidance).

References:
- https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_mitigate_interaction_failure_limit_retries.html
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.cloud.google.com/storage/docs/retry-strategy
- https://docs.temporal.io/encyclopedia/retry-policies
