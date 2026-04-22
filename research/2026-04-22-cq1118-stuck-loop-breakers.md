# CQ-1118 repeat streak breaker

Trigger: modernization repeated `CQ-1118` 5 consecutive iterations.

Findings:
- Add a hard repeat cap: if same task repeats 3 times, force task reselection from top-5 pending CQs.
- Enforce outcome delta gate: require changed target file set or changed failing assertion before allowing same-task retry.
- Add harness feedback loop: fast preflight sensors should block low-information retries and require new evidence.
- Use reflection+memory pattern between retries: persist prior failure signature and forbid identical reattempt payload.

Immediate policy for loops:
- `same_task_repeat >= 3` => WARNING + auto-diversify task picker.
- `same_task_repeat >= 5` => stuck; mandatory research + cooldown + alternate task.

References:
- https://martinfowler.com/articles/harness-engineering.html
- https://martinfowler.com/articles/exploring-gen-ai/ccmenu-quality.html
- https://arxiv.org/abs/2402.02716
