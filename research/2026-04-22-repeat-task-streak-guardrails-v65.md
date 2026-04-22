# Repeat-task streak guardrails (v65)

Trigger: repeated task IDs in last 30 iterations (CQ-1109 x4; CQ-1130 x3; IQ-1014 x3; IQ-1024 x3; IQ-1039 x3).

Findings (online):
- Temporal recommends setting Start-To-Close (or Schedule-To-Close) so long-running/stalled activities are bounded.
- Heartbeat timeout is the fast-fail signal for worker stalls; missed heartbeats can trigger retries earlier than long execution timeouts.
- Schedule-To-Start timeout is usually not the primary control; monitor queue latency instead unless explicit rerouting is planned.
- Heartbeat details can carry progress metadata across retries; use this to detect no-progress repeat attempts.

Sanhedrin application:
- Keep retry policy bounded and escalate when same task repeats 3+ times without new code deltas.
- Persist a progress fingerprint per iteration (`task_id`, touched-files hash, validation hash) and block immediate re-queue on unchanged fingerprint.
- Force diversification on repeat streaks (narrower prompt or alternate sub-scope) before allowing same `task_id` again.

References:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://temporal.io/blog/activity-timeouts
- https://docs.temporal.io/develop/python/activities/timeouts
- https://docs.temporal.io/activity-execution
