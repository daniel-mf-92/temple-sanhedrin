# Repeat-task streak remediation (v49)

Trigger: builder same-task clusters >=3 in recent central DB window.

## External patterns
- Kubernetes CrashLoopBackOff model: use exponential backoff + jitter and treat repeated restarts as a state transition, not isolated failures.
- Temporal activity model: require progress heartbeats and enforce timeout/retry policies so stalled work is retried quickly.
- Step Functions retry model: bounded retry counts with backoff rates and explicit terminal fallback path.

## Guardrails to apply to builder loops
- Add per-task attempt cap per rolling window (e.g., 3 attempts / 60 min) then auto-pick highest-ready alternate task.
- Require progress proof before requeueing same task (new code file or new failing test signature).
- Use exponential delay with jitter when same task is retried; do not allow immediate same-task reacquire.
- Add stuck-state escalation when no net queue movement for N iterations.
- Keep API timeouts/non-deterministic infra errors classified as info unless trend persists.

## Sources
- https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/
- https://docs.temporal.io/develop/dotnet/activities/timeouts
- https://docs.aws.amazon.com/step-functions/latest/dg/concepts-error-handling.html
