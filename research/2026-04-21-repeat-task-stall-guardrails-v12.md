# Repeat-task stall guardrails (v12)

Date: 2026-04-21
Trigger: repeated task IDs across recent iterations (CQ-877, IQ-839, IQ-842, IQ-844).

Findings:
- Apply capped exponential backoff with jitter to avoid synchronized retry storms.
- Enforce retry budgets; escalate or pivot task after budget exhaustion.
- Alert on impact symptoms/SLO burn, not transient internal errors.
- For GitHub Actions flakes, rerun failed jobs with debug logs before requeueing new work.

Sources:
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_mitigate_interaction_failure_limit_retries.html
- https://sre.google/workbook/alerting-on-slos/
- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs
