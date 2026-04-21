# Repeat-task stall guardrails (v12)

Trigger: repeated IDs in recent loop history (modernization: CQ-877 x4; inference: IQ-839/IQ-842/IQ-844 x3 each).

## External findings (web)
- AWS recommends capped retries with exponential backoff + jitter to avoid synchronized retry storms and overload.
  - https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
  - https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
  - https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_mitigate_interaction_failure_limit_retries.html
- Google SRE recommends actionable alerting and suppressing one-off transient failures to reduce noise/fatigue.
  - https://sre.google/sre-book/being-on-call/
  - https://sre.google/workbook/alerting-on-slos/
- Anthropic agent eval guidance highlights eval suites to detect reactive loops early and enforce behavior quality gates.
  - https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents

## Applied Sanhedrin policy update (for future loop prompts)
1. Stall gate: if same task ID appears >=3 times in 120 iterations, require decomposition or alternative task.
2. Retry budget: max 3 consecutive retries per task ID, then force cooldown for 2 picks.
3. Progress proof: retries must change code/test artifact class, not task-list-only edits.
4. Alert noise control: single transient failure stays INFO; trigger WARNING only on repeated no-progress failures.
5. Eval gate: add an anti-loop check in prompt rubric (reject repetitive trajectory before commit).
