# Stuck-loop repetition controls

Trigger: repeated task IDs (3+ occurrences) in recent builder iterations.

Findings:
- Keep agent loops simple and composable with explicit stop conditions instead of unbounded retries.
- Use eval loops that isolate one failure mode and one fix per iteration; broad retries without diagnosis cause stagnation.
- Track recurrence with postmortem actions to prevent repeated task churn.

Controls:
- Max 2 consecutive attempts per task_id before forced queue advance.
- Third attempt requires changed-file delta proof vs prior attempt.
- Auto-research gate when task_id repeats 3+ within 90 minutes.

References:
- https://www.anthropic.com/research/building-effective-agents
- https://developers.openai.com/cookbook/examples/realtime_eval_guide
- https://docs.cloud.google.com/architecture/framework/reliability/conduct-postmortems
