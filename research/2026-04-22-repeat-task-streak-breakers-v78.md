# Repeat-task streak breakers v78 (trigger: inference IQ-1070 x3)

## External findings (targeted)
- Wink (Meta, 2026): coding-agent misbehaviors cluster into specification drift, reasoning, and tool failures; lightweight targeted intervention resolves most single-step stuck cases.
- Voyager (Wang et al., 2023): automatic curriculum + skill library + execution-feedback loop improves exploration and avoids repeated local loops.

## Operational guardrails to apply
- Streak circuit-breaker: after 3 consecutive same-task passes/fails, force next pick from a different subsystem label.
- Intervention labels: classify each loop as `spec_drift`, `reasoning_loop`, or `tooling`; route only one remediation per class.
- Skill retrieval first: before rerunning same task, require retrieval of one prior successful analogous patch/test tuple.
- Exploration quota: reserve 20% of cycles for adjacent unchecked CQ/IQ tasks to prevent narrow local minima.
- Abort condition: 5 consecutive non-pass on same task => halt retries and open research ticket automatically.

## Sources
- https://arxiv.org/pdf/2602.17037
- https://arxiv.org/abs/2305.16291
