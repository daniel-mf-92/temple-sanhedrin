# Stuck repeat-task controls (refresh)

Trigger: repeated task IDs in latest 50 iterations (>=3 occurrences).

Applied controls:
- Retry budget per task ID: max 2 immediate retries, then force queue rotation.
- Cooldown with jitter: 10–30 min before re-queueing same task ID.
- Progress proof gate: require changed code artifact or failing test delta before retry.
- Circuit breaker: if same task ID appears 3 times in 12 iterations, quarantine task and enqueue adjacent dependency task.
- Escalation: if no measurable delta after quarantine cycle, mark as RESEARCH_REQUIRED and block auto-repeat.
