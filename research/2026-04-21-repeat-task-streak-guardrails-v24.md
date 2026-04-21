# Repeat-task streak guardrails (v24)

Trigger: recent120 shows repeated task IDs (modernization CQ-914 x6; inference IQ-878 x5).

Findings from online sources:
- AWS Builders Library recommends capped retries with exponential backoff + jitter to avoid synchronized retry storms and no-progress loops.
- Circuit Breaker pattern (Fowler) recommends opening the breaker after repeated failures and routing to alternate action instead of repeating the same call path.
- Google SRE monitoring guidance emphasizes alerting on symptom trends and burn-rate style persistence, not one-off errors.

Applied guardrails for Codex loops:
- Add `same_task_streak` counter per agent; if streak >=3, force task reselection from a different category (code/test/refactor).
- Add retry budget per task (`max_attempts=3` in 2h). After budget exhausted, mark as WARNING and enqueue research-required remediation task.
- Add cool-down + jitter (5-15 min) before reattempting same task ID.
- Add breaker state: open after 5 consecutive FAIL/SKIP-without-file-change iterations, half-open after one successful compile/test signal.
- Require progress signal to clear streak: changed non-markdown code file OR net test/compile delta.
