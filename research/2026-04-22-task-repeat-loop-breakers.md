# Task repeat loop-breakers (Sanhedrin)

Trigger: repeated tasks >=3 in recent window (`IQ-970`, `IQ-980`, `CQ-1013`, `CQ-1014`, `CQ-1018`) with no failure streak.

Findings:
- Add durable per-task attempt metadata (attempt count, first-seen time, last-progress SHA) and force re-plan when attempt>=3.
- Persist state checkpoints each loop so retry resumes from last meaningful progress, not from prompt top.
- Treat transient API/tool failures separately from code failures; avoid promoting transient infra noise to law violations.
- Enforce stale-task TTL: if same task repeats without new code delta, auto-rotate to nearest dependency/unblock task.
- Keep queue health SLOs: cap duplicate task share in last N iterations and alert when exceeded.

Recommended guards for builders:
- `repeat_threshold=3` => mandatory tactic switch (new test vector, narrower diff scope, or adjacent task).
- `max_same_task_window=4/20` => soft warning to Sanhedrin.
- `no_progress_commits=2` => force task reselection.

Sources:
- https://docs.langchain.com/oss/python/langgraph/persistence
- https://sre.google/sre-book/practical-alerting/
- https://codescene.com/blog/feature-toggles-are-technical-debt-guest-blog
