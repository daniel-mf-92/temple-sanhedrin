# Streak-breakers for repeated agent task loops

Trigger (2026-04-22): modernization task `CQ-1214` repeated 4x at head; inference task `IQ-1125` repeated 3x at head.

## Findings
- Use hypothesis-driven troubleshooting loops (`define -> gather -> hypothesize -> test -> reflect`) instead of repeated patch retries; from Google SRE Effective Troubleshooting.
- When using 5-whys, stop blame answers and continue until process-level causes are reached; from Atlassian 5 Whys guidance.
- Introduce minimal eval harnesses from real failures (small seeded cases) to detect regression/no-progress cycles early; from Anthropic evals guidance.

## Concrete interventions for builders
- Hard streak gate: if same `task_id` repeats >=3, require one explicit hypothesis line + one falsifiable check before next commit.
- Counterfactual patch rule: next attempt must differ in approach class (logic-path change vs test-only vs instrumentation-only); prevent near-duplicate retries.
- Add 20-50 seeded regression checks for recent stuck tasks and run them before commit.
- If two hypothesis cycles fail, force task decomposition into two sub-issues with separate acceptance checks.
- Record “disconfirming evidence” in notes to prove the new attempt is not the same failed path.

## Notes
- Keep TempleOS guest air-gapped; no networking feature work.
- Keep core modernization in HolyC.
