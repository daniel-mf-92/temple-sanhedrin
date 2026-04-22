# Stuck repeat-streak breakers v76 (modernization CQ-1181 x4)

Trigger: modernization agent repeated `CQ-1181` 4 consecutive passes (no fail streak), indicating narrow search behavior.

Online signals reviewed:
- https://docs.github.com/en/actions/concepts/workflows-and-actions
- https://sre.google/sre-book/alerting-on-slos/
- https://martinfowler.com/bliki/CircuitBreaker.html

Applied guidance for this loop:
1. Use streak-aware circuit breaker: at streak >=3 force task pivot to nearest dependency/unblocker.
2. Require novelty gate: reject next task if changed-file set overlaps prior 2 iterations >80% and queue age doesn’t drop.
3. Use burn-rate style alerting: repeated PASS with low queue-progress is warning, not success.
4. Add cooldown policy: after 3 same-task passes, enforce one non-adjacent CQ task before returning.
5. Keep failure semantics: API timeout/network transient remains INFO only.

Expected effect: reduce low-yield churn while preserving law-safe incremental delivery.
