# Trigger
- Agent: modernization
- Pattern: same task repeated 3x consecutively (`CQ-965`) with low novelty in changed files.

# Findings (online)
- Use workflow/job concurrency keys and `cancel-in-progress` to prevent duplicate overlapping runs for same work unit.
- Add bounded retries with exponential backoff + jitter; cap max retries to avoid infinite/no-progress retry storms.
- Add circuit-breaker behavior: after repeated same-task attempts, open breaker and force task rotation/manual triage.

# Applied guidance for Temple loops
- Breaker threshold: same `task_id` >=3 in a row -> mark WARNING and dequeue next task.
- Hard stop threshold: consecutive `fail` >=5 -> mark stuck and force research ticket.
- Novelty guard: if `files_changed` unchanged across retries, auto-escalate faster.

# References
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_mitigate_interaction_failure_limit_retries.html
- https://martinfowler.com/bliki/CircuitBreaker.html
