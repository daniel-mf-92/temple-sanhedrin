# Inference task dedup guard (IQ-451 repeat)

Trigger: IQ-451 appeared 3+ times in recent inference iterations.

Findings (actionable):
- Add atomic task-claim state in central DB (`queued -> claimed -> done`) so one loop cannot close/reopen the same task concurrently.
- Add per-task run key (`agent + task_id + commit_sha`) and reject duplicates at start.
- Enforce workflow/loop concurrency grouping so only one active inference loop writes task state at a time.
- Keep retries idempotent: reruns should update same task-run record, not create a new closure event.

References:
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/using-messagededuplicationid-property.html
- https://docs.celeryq.dev/en/stable/userguide/tasks.html
