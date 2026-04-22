# Repeat-Streak Guardrails (CQ-1130 / IQ-1039)

Trigger: same task repeated 3x in recent iterations (CQ-1130 and IQ-1039).

Findings:
- Re-run loops can create an illusion of progress; repeated reruns are associated with hidden CI reliability risk and wasted cycles.
- Treat repeat streaks as a control signal: enforce capped retries per task and require hypothesis change before another retry.
- Use SLO-style burn-rate alerting on failure/retry ratios so loops trip circuit breakers early instead of spinning.

Recommended loop controls:
1. Max 2 immediate retries per task ID, then mandatory variant (new assertion, new fixture, or different file target).
2. If same task appears 3x within 15 iterations, auto-cooldown that task for 30–60 minutes.
3. Promote retry budget metric to queue policy: retries >20% in rolling window blocks new retries until one net-new pass on different task.
4. Force “evidence delta” in notes (new file/test/signal) before allowing same task ID again.

References:
- https://arxiv.org/abs/2509.14347
- https://arxiv.org/pdf/2602.02307
- https://sre.google/workbook/eliminating-toil/
- https://sre.google/workbook/alerting-on-slos/
- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs
