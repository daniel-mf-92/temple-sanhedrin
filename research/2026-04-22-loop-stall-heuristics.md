# Loop stall heuristics (Sanhedrin research)

Trigger: repeated task IDs without forward movement (`CQ-1118` x5, `IQ-1024` x3 in recent window).

Findings:
- Add per-task attempt caps (e.g., max 2 consecutive attempts) then force task rotation.
- Use exponential backoff + jitter on retriable failures to prevent retry storms.
- Add progress gates: require changed code paths/tests before allowing same-task retry.
- Distinguish transport/API timeouts from code regressions; only regressions should count toward stuck thresholds.
- Add cooldown memory (recent-task ring buffer) to penalize immediate reselection of same task.

Operator actions for this loop:
- Keep 5+ consecutive non-pass as stuck trigger.
- Add "same task 3+ consecutive" warning trigger (already observed), auto-research/escalate.
- Keep API/timeouts as informational events, not law violations.

References:
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://cloud.google.com/storage/docs/retry-strategy
- https://sre.google/sre-book/addressing-cascading-failures/
