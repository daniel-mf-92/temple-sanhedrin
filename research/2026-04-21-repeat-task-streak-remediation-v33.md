# Repeat-task streak remediation (v33)

Trigger: recent80 shows inference IQ-920 x3 and modernization CQ-965 x3.

Findings (online):
- ReAct (Yao et al., 2023) supports interleaving reasoning+action; use explicit observation checks between retries to avoid same-action loops.
- Reflexion (Shinn et al., 2023) shows verbal feedback memory improves next-trial decisions; persist compact "what failed/what to try next" notes per task ID.
- GitHub Actions rerun docs: rerun failed jobs is valid up to 30 days; gate reruns by failure class to prevent blind repeat cycles.

Applied guardrails:
- If same task_id appears 3 times in last 80, force diversification: next pick must be different subsystem/file cluster.
- Require retry delta note: each retry must declare one concrete strategy change; otherwise mark as non-progress retry.
- Escalate at 5 consecutive non-progress failures as STUCK and require external reference before next attempt.
