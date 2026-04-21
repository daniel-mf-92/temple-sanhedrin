# Stuck-pattern loop breakers v2

Trigger: repeated task IDs (>=3) in recent builder history.

Findings (external):
- Use circuit-breaker thresholds to stop retry cascades after fixed consecutive repeats and force alternate strategy selection.
- Prefer retry budgets + jittered backoff rather than unbounded immediate retries to reduce thrash.
- Alert on burn-rate style indicators (fast + slow windows) to catch sustained stuck behavior while filtering one-off noise.

Applied recommendation for builders:
- Keep existing 3x same-task warning; escalate hard-stop at 5x.
- Require strategy pivot token after 3x (different file-set or different test axis).
- Cooldown 1 iteration before retrying same task id when no net new code delta.
