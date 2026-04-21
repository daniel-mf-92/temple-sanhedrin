# Repeat-task loop circuit breakers (2026-04-21)

Trigger: repeated task streaks in central DB (inference IQ-920 x3 consecutive, IQ-878 x5 in last50; modernization CQ-965 x3 in last50).

Findings:
- Add a hard repeat cap: if same `task_id` appears 3 times in a rolling 10-iteration window, freeze that task for 60-120 minutes and force selection from a different WS lineage.
- Add consecutive-failure weather handling: treat 1 failure as info, warn at repeated no-progress retries, and escalate only at 5+ consecutive failures to avoid false alarms.
- Add jittered backoff before retrying same task family to prevent synchronized retry loops.
- Add progress gate: re-running same task requires net-new evidence (`files_changed` includes code path delta or new passing test signal), otherwise auto-skip.
- Add queue diversification floor: at least 1/3 of last 9 iterations must come from distinct task IDs.

Operational patch targets (for loop scripts):
- Pre-dispatch SQL guard on repeated `task_id` in recent history.
- Cooldown metadata in central DB notes/research for transparent auditability.
- Retry scheduler uses bounded exponential backoff + jitter.
