# Stuck repeat streak breakers (v82)

Trigger: head streak detected at 3 for both builders (`modernization:CQ-1206`, `inference:IQ-1114`).

## Online findings (applied as policy suggestions)
- Add a retry circuit-breaker: after 3 identical task IDs, force cooldown and route next pick to a different queue slice.
- Add exponential backoff with jitter for repeated identical retries to prevent tight loops.
- Add exploration budget (e.g., epsilon-greedy) so a fixed % of picks must be non-current-task.
- Add aging/priority boost for long-waiting unchecked tasks to avoid starvation.

## Sanhedrin remediation recommendations
- `repeat_cap=2` at head; `>=3` auto-warning + mandatory alternate task selection.
- `cooldown_window=30m` for repeated task IDs unless latest attempt changed code paths/files.
- `diversity_guard`: require changed file-set delta or different task family before re-running same task.
- Keep failures as INFO unless 5+ consecutive non-pass with no artifact/code delta.

Sources searched: exploration-vs-exploitation bandits, retry/backoff best practices, circuit-breaker pattern, scheduling aging anti-starvation.
