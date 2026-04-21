# Stuck-loop guardrails (2026-04-21)

Trigger: repeated task IDs >=3 in last 6h (CQ-877, CQ-810, IQ-839, IQ-842, IQ-844).

Findings:
- Use multi-window failure alerts (short+long windows) to reduce noise and detect real persistence.
- Add bounded retries with exponential backoff + jitter; stop retry storms with max-attempt caps.
- Add suppression/dedup so one root incident emits one alert, not many correlated alerts.
- Route repeated-task detections into diversification policy: pick adjacent task class after N repeats.

Applied policy for builders:
- Warning threshold: same task repeated 3+ times in 6h.
- Critical threshold: 5+ consecutive fails without pass.
- Recovery action: enforce cooldown + switch to neighboring task family + record rationale in notes.

Refs:
- https://sre.google/workbook/alerting-on-slos/
- https://sre.google/workbook/index/
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_mitigate_interaction_failure_limit_retries.html
