# Repeat-Task Streak Guardrails (2026-04-21)

- Trigger: same task repeated 3+ times in short window; treat as potential local optimum.
- SRE practice: alert on actionable symptoms and reduce noisy loops; use explicit escalation thresholds.
- Incident-management practice: define severity + role handoff so repeated non-progress routes to different owner quickly.
- Circuit-breaker analogy: after threshold failures/repeats, pause automatic retries and require new evidence before reopening.

## Applied policy

- At repeat>=3: label WARNING, demand hypothesis change and evidence delta in next run.
- At repeat>=5 or no code delta across repeats: label STUCK, force research-backed alternative path.
- Reopen only after one of: new failing test reproduced, new code path touched, or independent review signal.

## Sources consulted

- Google SRE: Practical Alerting / actionable alerting philosophy.
- Azure Well-Architected: incident management phases and escalation under pressure.
- Martin Fowler: Circuit Breaker threshold/open-state pattern for failure containment.
