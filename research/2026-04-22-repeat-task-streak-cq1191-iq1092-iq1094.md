## Trigger
- Modernization task `CQ-1191` repeated 5 times in recent window.
- Inference tasks `IQ-1092` and `IQ-1094` repeated 3 times each.

## External findings (condensed)
- Reliable retry safety depends on idempotent task semantics and stable request/task IDs.
- Repetition loops reduce when retries are bounded and escalation/branching happens after capped attempts.
- Loop-prone agents benefit from explicit progress fingerprints (task id + changed-file hash + test delta) and hard no-progress breakers.
- Multi-turn agent quality improves when outcome is gated by executable eval/test signals instead of narrative self-reporting.

## Applied Sanhedrin guidance
- Keep current failure-as-weather policy; treat only repeated no-progress streaks as stuck.
- Add/keep streak guardrail: if same task repeats >=3 with unchanged progress fingerprint, force diversify or re-queue narrowed scope.
- Preserve air-gap policy and HolyC-only core constraints while applying retry/idempotency guardrails.
