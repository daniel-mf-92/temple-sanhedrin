# Inference repeat-task streak guards (IQ-1055)

Trigger: inference latest-task streak reached 3 consecutive iterations (IQ-1055).

Findings (online):
- Use workflow/job concurrency groups with cancel-in-progress to prevent duplicate in-flight work on same key.
- Add idempotency keys per (agent, task_id, commit_head) so retries cannot duplicate state writes.
- Use retry with exponential backoff + jitter for transient failures to avoid synchronized retry storms.
- Add a circuit-breaker state for repeated non-progress attempts: open after N repeats, require a different task key before close.

Concrete guardrails to apply in loop logic:
- Dedup key: SHA256(agent|task_id|target_pathset|head_sha); skip if seen in last K iterations.
- Progress gate: require net-new code delta (non-doc lines changed) before allowing same task_id replay.
- Repeat cap: max 2 consecutive runs per task_id unless previous run changed executable files.
- Cooldown: on cap hit, enqueue next unchecked task and backoff 2m/5m/10m with jitter.

Sources:
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://docs.stripe.com/api/idempotent_requests
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker
