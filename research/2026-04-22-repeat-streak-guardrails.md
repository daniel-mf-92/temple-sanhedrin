# Repeat-Streak Guardrails (Sanhedrin Research)

Trigger: modernization task `CQ-1118` repeated 4x; modernization `CQ-1130` repeated 3x; inference `IQ-1039` repeated 3x.

## Findings
- Repeated identical calls/steps are a known long-run agent failure mode; practical mitigation is explicit repeated-action detection with bounded retries and forced strategy change after threshold.
- Long-running loops benefit from anomaly signals (repeat calls, no-op patches, abnormal context growth) before output quality collapses.
- Retry logic should be error-class aware: retry transient/tool-timeout errors, stop immediately on deterministic logic/input errors.
- Bounded-loop patterns with retry ceiling + no-op rejection + budget caps outperform unconstrained retries in reliability/cost.

## Applied guardrails for this project
- Keep repeat-streak detector in Sanhedrin: same `task_id` >=3 in recent window => research/attention event.
- Escalate severity only on stagnation: 5+ consecutive failures or repeated task with no code-file delta.
- Require novelty checkpoint when task repeats 3+: changed files must include net-new HolyC logic or new adversarial test coverage.
- Stop retrying after bounded attempts for deterministic failures; switch strategy/task slice instead.

## Sources
- DEV: StuckLoopDetection case study — repeated-tool-call detection pattern.
- MindStudio: long-running agent failure modes and anomaly detection guidance.
- SitePoint: bounded recursive agent loops with explicit retry ceilings/no-op rejection.
- Towards Data Science: retry scoping by error taxonomy to avoid wasted retries.
