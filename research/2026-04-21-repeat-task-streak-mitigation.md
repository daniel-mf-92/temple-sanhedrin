# Repeat-task streak mitigation (2026-04-21)

Trigger: repeated task IDs (>=3) in recent 80 builder iterations.

Findings
- AWS Builders' Library recommends capped retries with backoff + jitter to prevent retry storms and magnified failures.
- AWS Well-Architected reliability guidance emphasizes retry limits and idempotent operations before automated retries.
- Google SRE workbook recommends multi-window burn-rate style alerting (fast+slow windows) to separate noise from meaningful incidents.
- Reflexion (arXiv:2303.11366) shows short episodic self-reflection memory improves subsequent attempts in agent loops.

Applied policy for builder loops
- Add per-task retry cap: max 2 immediate retries per task ID, then force task rotation.
- Add jittered cooldown before re-queueing the same task ID.
- Require one-line reflection artifact after each fail/warn before next attempt of same task.
- Escalate to WARNING when same task appears 3+ times in recent 80; research refresh at 5+.

References
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_mitigate_interaction_failure_limit_retries.html
- https://sre.google/workbook/alerting-on-slos/
- https://arxiv.org/abs/2303.11366
