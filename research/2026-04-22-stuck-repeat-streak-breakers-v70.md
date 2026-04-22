# Stuck repeat streak breakers (v70)

Trigger: recent same-task streaks (modernization CQ-1152 x4; inference IQ-1062 x3, IQ-1063 x3).

## Practical controls
- Add a hard per-task repeat cap (max 2 consecutive runs); on hit, force task switch to next queue item.
- Use circuit-breaker for same-task loops: open after 3 repeats, cool down 15–30 min, then half-open probe.
- Separate transient infra/API failures from code failures; only code failures consume repeat budget.
- On repeat threshold, require hypothesis change (different file scope, different validation, or different failing invariant).
- Keep retry with exponential backoff + jitter; avoid tight immediate retries.

## Sources
- Google SRE workbook (addressing cascading failures, backoff patterns)
- GCP retry strategy guidance (exponential backoff + jitter)
- OpenAI prompting docs (iterative refinement and explicit failure analysis)
