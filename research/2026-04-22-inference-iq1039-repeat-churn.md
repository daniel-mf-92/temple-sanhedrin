# Inference IQ-1039 repeat churn

Trigger: `inference` repeated `IQ-1039` 3x in latest 10 iterations.

Findings (online + local telemetry):
- Duplicate task execution is commonly reduced by queue-claim atomicity (`BEGIN IMMEDIATE` + single-row claim) and by persisting a claim token per loop cycle.
- Repeat churn is often caused by stale queue views; selecting next task should exclude `(task_id, head_sha)` pairs already completed in recent iterations.
- CI/run overlap can amplify duplicate work; branch-level workflow concurrency reduces redundant simultaneous runs.

Recommended guardrails:
- Add DB-level dedupe key for inference loop claims: `(agent, task_id, commit_sha, status='pass')` lookback window.
- If same task appears >=3 times in 10 cycles, force diversification: pick next eligible IQ and add cooldown for repeated task IDs.
- Emit explicit churn metric (`repeat_task_rate`) each cycle and fail-open to alternate task when above threshold.

References:
- https://www.sqlite.org/lang_transaction.html
- https://www.sqlite.org/lang_returning.html
- https://docs.github.com/actions/using-jobs/using-concurrency
