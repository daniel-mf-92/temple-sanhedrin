# Stuck-task streak breaker (concise)

Trigger observed: same task repeated >=3 times (inference: IQ-946, IQ-951; modernization: CQ-992).

Recommended controls:
- Apply a retry budget (max 3 immediate retries) before mandatory task switch; avoid infinite same-task loops.
- Use a circuit-breaker cooldown (10-30 min) after repeated same-task attempts, then re-enter with a narrowed scope.
- Quarantine flaky validations from merge-blocking path while keeping them in a monitored non-blocking lane.
- Track a flake/stuck metric: if pass/fail oscillates or same task repeats on 3 consecutive loop cycles, auto-escalate research + alternate implementation path.

Sources:
- https://sre.google/sre-book/handling-overload/
- https://docs.datadoghq.com/tests/flaky_management/
- https://mill-build.org/blog/4-flaky-tests.html
