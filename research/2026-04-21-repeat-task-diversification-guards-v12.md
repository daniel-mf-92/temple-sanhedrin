# Repeat-task diversification guards (v12)

Trigger: repeated task IDs in last 6h (CQ-914 x6, IQ-878 x5, multiple x3+ clusters).

## Research findings
- AWS recommends bounded retries with exponential backoff + jitter and explicit retry limits to avoid retry storms.
- AWS Well-Architected stresses capped retries and jitter because retries under overload amplify failures.
- Google SLO guidance recommends burn-rate style alert thresholds to detect sustained error-budget consumption early.
- GitHub Actions supports rerunning only failed jobs (`gh run rerun <id> --failed`) to reduce no-op reruns.

## Applied guardrails for loop policy
- Add per-task retry budget and cool-down before task can be reselected.
- Add mandatory queue diversification after N repeats (force different WS lineage for next pick).
- Add stuck alarm when same task appears 3+ times in 6h; escalate at 5+.
- On CI noise, rerun failed jobs only once; then require root-cause note before further retries.

## Sources
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_mitigate_interaction_failure_limit_retries.html
- https://docs.cloud.google.com/stackdriver/docs/solutions/slo-monitoring/alerting-on-budget-burn-rate
- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs
