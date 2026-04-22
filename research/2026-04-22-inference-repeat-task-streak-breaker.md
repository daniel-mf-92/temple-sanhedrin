# Inference repeat-task streak breaker (IQ-1070 x3)

Trigger: inference repeated `IQ-1070` 3 times in recent history; no fail streak, but exploration narrowness risk.

Applied guidance (from ReAct / Reflexion / Voyager papers):
- Add explicit `novelty_gate`: block re-running same task-id >2 times unless a new failing test or new file target is present.
- Add `reflection_memory`: store last-3 "why previous attempt was insufficient" notes and require a delta-hypothesis before retry.
- Add `curriculum_rotation`: force one adjacent queue task every third iteration to prevent local minima.
- Add `verification_first`: require a targeted failing/passing test delta before marking same-task retries as meaningful progress.

Expected effect: preserve pass rate while reducing repeated-task loops without introducing risky architecture churn.
