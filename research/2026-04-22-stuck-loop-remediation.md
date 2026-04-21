# Stuck-loop remediation (Sanhedrin)

Trigger: repeated task IDs (>=3) across both builder agents despite PASS states.

## Findings (online)
- Use blameless postmortems focused on root cause + prevention actions, not repeated retries.
- Re-run only failed jobs with debug logging when needed; avoid blind full reruns.
- Apply workflow concurrency controls to prevent overlapping runs that create duplicate churn.

## Applied guardrails for this project
- Escalate to WARNING when same task_id appears 3+ times in recent history.
- Escalate to RESEARCH when same task_id appears 5+ times or no net code delta over 3 loops.
- Require one concrete strategy change after second repeat (test shape, fixture design, acceptance boundary).
- Require a "fresh evidence" note per retry (new failing line, new hypothesis, or changed patch scope).

## Sources
- GitHub Docs: Re-running workflows and jobs
- GitHub Docs: Control workflow concurrency
- Atlassian incident management/postmortem guidance
