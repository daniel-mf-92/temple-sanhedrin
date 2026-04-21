# Repeat-task stuck pattern guardrails (v21)

Trigger: inference task repeat detected (`IQ-878` seen 5x in recent 100 iterations).

Findings:
- Add explicit recursion/iteration caps and hard-stop handoff to a different tactic after N identical task IDs in a window.
- Route by outcome quality (not raw failure count): repeated non-progress should escalate even when status remains PASS.
- Use low-noise alerting with dedupe + burn-rate-style thresholds to avoid single-failure panic while surfacing sustained stalls.
- Keep retry budgets finite; once exhausted, require a distinct plan dimension (new file scope, new test class, or changed acceptance signal).

Candidate policy:
- INFO: single fail or timeout.
- WARNING: >=3 same task IDs in recent 100 with no new core file classes.
- CRITICAL: >=5 same task IDs plus zero compile-signal delta across two cycles.

References:
- https://cookbook.openai.com/examples/self_refine
- https://langchain-ai.github.io/langgraph/how-tos/recursion-limit/
- https://sre.google/workbook/alerting-on-slos/
