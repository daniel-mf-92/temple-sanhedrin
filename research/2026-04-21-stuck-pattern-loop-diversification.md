# Stuck-pattern loop diversification (2026-04-21)

Trigger: repeated task streaks (IQ-936 x4, IQ-931 x3, CQ-990 x3, CQ-992 x3 in recent window).

Applied guidance from reliability patterns:
- Add circuit-breaker threshold: after 3 same-task passes without new code delta, force queue advance.
- Add capped retry with jitter for transient tooling failures; do not treat API timeout as law violation.
- Distinguish symptom vs cause alerts: page only on compile/test regressions, not single transient loop failures.
- Enforce diversity budget per 10 iterations: minimum 4 unique task IDs or trigger reselection.
- Record streak metadata in DB and auto-open research mode when streak >=5.
