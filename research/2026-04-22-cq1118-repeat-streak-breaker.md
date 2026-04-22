# CQ-1118 repeat-streak breaker

Trigger: modernization task `CQ-1118` repeated 5 consecutive iterations.

Findings (online + applied):
- Use an explicit "stuck threshold" gate: after 3 repeats, require a measurable delta target before next run.
- Split one large target into acceptance probes (smoke, perf, invariants) and rotate probe focus each iteration.
- Promote batch-size discipline: force one smallest shippable change per loop to avoid local maxima.
- Add anti-loop guardrail in prompt/checklist: if same task repeats 3x with no new invariant, auto-pivot to next queued CQ.
- Preserve fail/weather model: transient API/timeout remains informational, only repeated no-progress loops escalate.

Recommended immediate guardrail for Sanhedrin:
- Mark repeat streak >=5 as WARNING and require research + pivot recommendation in DB notes.
