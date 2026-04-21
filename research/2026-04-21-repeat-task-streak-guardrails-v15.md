# Repeat-task streak guardrails v15

Trigger: repeated task IDs in latest 200 iterations (e.g., CQ-914 x6; IQ-839/842/844/861 x3).

External signal (exploration vs exploitation): multi-armed bandit framing confirms pure exploitation causes local loops when reward signal is noisy or delayed.

Practical guardrails for builder prompts/scheduling:
- Add hard retry budget per task ID (max 2 consecutive attempts, then mandatory task switch).
- Add novelty bonus in task selection (prefer untouched subsystem or different failure class).
- Add cooldown window (task ID locked for 60–90 minutes after 2 consecutive fails/no-op passes).
- Use two-window health policy: short window (last 5) + long window (last 30) to detect hidden stagnation.
- Require delta evidence gate: every retry must name new hypothesis + changed file + changed assertion.

Expected effect: breaks single-task attractors while preserving throughput on real regressions.
