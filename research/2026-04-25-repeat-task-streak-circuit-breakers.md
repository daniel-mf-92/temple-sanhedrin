# Repeat-task streak circuit breakers (2026-04-25)

Trigger: same-task streak >=3 detected in both builders during Sanhedrin audit.

Findings:
- Temporal recommends explicit heartbeat + bounded activity timeouts (`heartbeat`, `start-to-close`, `schedule-to-close`) so stalled work fails fast and retries deterministically.
- Retry policy should distinguish transient vs permanent failures; repeated same-task loops need a non-retryable/alternate-path branch after capped attempts.
- SRE alerting guidance favors symptom alerts (streak/no-progress) over raw failure counts; add streak-based burn alert for `same_task_streak >= 3` and critical for `>=5` without code delta.
- OpenAI eval guidance supports trace+artifact scoring; add a "progress fingerprint" eval (`task_id`, files_changed hash, test hash) to gate retries and force prompt diversification when unchanged across retries.

Suggested guardrails for loops:
- Enforce max attempts per task-id window (for example: 3) before mandatory queue diversification.
- Persist heartbeat payload with `task_id`, stage, file hash, test hash; treat unchanged payload across retries as no-progress.
- Add automatic downgrade from WARNING to CRITICAL when `same_task_streak >=5` and `files_changed` contains no code extensions.

References:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/activity-execution
- https://sre.google/workbook/alerting-on-slos/
- https://developers.openai.com/blog/eval-skills
- https://developers.openai.com/api/docs/guides/agent-evals
