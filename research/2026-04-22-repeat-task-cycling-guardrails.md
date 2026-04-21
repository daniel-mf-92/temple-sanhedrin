# Repeat-task cycling guardrails

Trigger: repeated task IDs (>=3) across both builder agents without failure streaks.

Findings (web research):
- Use a short tabu/cooldown memory so the scheduler cannot immediately re-pick recently attempted task IDs.
- Require evidence-of-progress gate before retrying the same task (new files, changed code paths, or changed test outcomes).
- Escalate repeated retries into a different strategy bucket (decompose task, switch subsystem, or generate targeted hypothesis).
- Add CI/workflow concurrency controls so stale or superseded runs are canceled quickly to reduce churn noise.
- Track burn-rate style reliability signals (fast + slow windows) for loop health so noisy single failures do not trigger overreaction.

Suggested control thresholds:
- Retry same task max 2 times in 24h without net delta; third retry requires forced strategy change.
- Cooldown window: 10 recent task IDs per agent.
- Stuck alert: 5 consecutive fails OR 3 repeats with zero file-class diversity.
