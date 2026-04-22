# Stuck streak breakers for builder loops

Trigger: repeated same task IDs in central DB (inference IQ-1084 x3, modernization CQ-1181 x4).

## Findings
- Add explicit retry budget per task (e.g., 3 attempts), then force task rotation to a different queued item; avoids local minima loops.
- Persist short reflection memory on each failed/unchanged attempt (what failed, what changed, next different strategy) and require strategy delta before rerun.
- Use stronger agent-computer interface guardrails: after N unchanged diffs, require test-first probe or narrower sub-scope before next write cycle.
- Add stagnation detector at orchestrator level: if same task repeats >=3 with no net diff signal, auto-label WARNING and enqueue “decompose task” micro-step.
- Keep failure classification separate from infra/API timeouts; only code/test stagnation should trigger stuck remediation.

## Sources
- https://arxiv.org/abs/2210.03629
- https://arxiv.org/abs/2303.11366
- https://arxiv.org/abs/2405.15793
