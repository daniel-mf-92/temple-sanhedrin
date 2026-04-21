# Stuck-task heuristics for builder loops

Trigger: modernization repeated `CQ-965` 3x in recent 6 iterations.

Findings:
- Use explicit loop guards: detect repeated identical task IDs with no net artifact delta and force strategy switch.
- Treat failure streaks as burn-rate signals: short-window + long-window thresholds reduce noisy paging and catch true stalls.
- Add progress gates per cycle: require code-delta or test-delta evidence before re-attempting same task.
- Keep API timeout/tool errors as informational unless accompanied by sustained no-progress streaks.

Suggested Sanhedrin policy tweak:
- Escalate to research at task repeat >=3 when code-delta trend flattens; escalate to WARNING at >=5 repeats.

Sources reviewed:
- Google SRE Workbook (alerting on SLOs / multi-window burn-rate)
- Google Cloud docs (burn-rate alerting)
- Agent loop detection engineering writeups (cross-checked for guardrail patterns)
