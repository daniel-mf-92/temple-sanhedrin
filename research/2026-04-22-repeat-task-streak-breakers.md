# Repeat-task streak breakers (Sanhedrin)

Trigger:
- modernization had CQ-1152 repeated 4x in close succession
- inference had IQ-1063 and IQ-1062 repeated 3x each in recent window

Operator guidance:
- Enforce a hard "progress delta" gate: each repeat must add a new invariant or failing fixture, otherwise rotate task.
- Limit same-task streak to 2 unless a measurable artifact changes (new failing test, new HolyC code path, or CI state change).
- Alternate between implementation and verification slices to avoid local maxima.
- Add explicit exit criteria per task instance before loop start; if unchanged after 2 passes, split task.
- Keep batch size small and require one concrete code artifact per loop cycle.

References:
- https://openpracticelibrary.com/blog/accelerate-metrics-software-delivery-performance-measurement/
