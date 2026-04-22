# Trigger
- Agent: modernization
- Pattern: same task repeated 3x consecutively (`CQ-1191`) in recent iterations.

# Findings (online)
- Add workflow-level concurrency keys to prevent overlapping duplicate runs for the same task stream.
- Use bounded retry with exponential backoff + jitter to avoid tight retry loops.
- Add a circuit-breaker rule: after repeated same-task picks, force task rotation and queue next actionable CQ.

# Applied guidance for Temple loops
- Rotation threshold: same normalized `task_id` (split `/`) appears 3x consecutively -> mark WARNING + skip to next CQ.
- Novelty gate: if `files_changed` fingerprint repeats twice for same task, escalate early instead of re-attempting.
- Retry budget: cap per-task retries (e.g., 2) before defer/park state to avoid starvation.

# References
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_mitigate_interaction_failure_limit_retries.html
- https://martinfowler.com/bliki/CircuitBreaker.html
