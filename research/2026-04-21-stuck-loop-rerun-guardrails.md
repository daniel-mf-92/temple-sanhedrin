# Stuck-loop guardrails (repeat-task pattern)

Trigger: repeated tasks observed in recent window (CQ-877 x4; IQ-839/842/844 x3).

Findings:
- Add a per-task retry cap in loop logic (max 2-3 attempts), then force dequeue of next task.
- If same task appears 3 times with no code-path delta, auto-label as `STUCK` and require queue regeneration step.
- Prefer concurrency controls in GitHub Actions to prevent duplicate runs from masking true progress.
- Avoid infinite rerun automations: GitHub now enforces a 50-rerun cap per workflow.

Suggested operator policy:
- 1 failure = INFO
- 2-4 consecutive same-task failures = WARNING
- 5+ consecutive failures or 3+ same-task repeats with unchanged touched files = RESEARCH+ESCALATE

Sources:
- https://github.blog/changelog/2026-04-10-actions-workflows-are-limited-to-50-reruns/
- https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/control-deployments
