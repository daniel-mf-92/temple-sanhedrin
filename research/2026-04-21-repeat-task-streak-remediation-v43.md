# Repeat-task streak remediation (v43)

Trigger: modernization max streak 3 (CQ-992), inference max streak 4 (IQ-944).

## External guidance distilled
- Use bounded retries with exponential backoff + jitter; avoid synchronized retry storms and cap retry budget.
- Add a circuit-breaker state: on repeated same-task attempts, temporarily open circuit and force alternate task class.
- Separate transient failure handling from persistent failure handling; persistent paths must escalate instead of retrying.
- Alert on symptom (streak length + no-code-progress window), not on single failures.

## Sanhedrin policy update applied
- Keep single failures as INFO.
- At streak >=3 on same task_id: WARNING + forced diversification recommendation.
- At >=5 consecutive failures without progress: STUCK + mandatory research/escalation.
- Retry tasks only when evidence changed (new failing test, new diff target, or new dependency state).

## Sources
- AWS Architecture Blog: Exponential Backoff and Jitter
- AWS Prescriptive Guidance: Retry with backoff pattern
- Microsoft Learn: Circuit Breaker pattern
- Google SRE Workbook: practical alerting and overload symptom guidance
