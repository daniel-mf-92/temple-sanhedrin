# Repeat-task loop breaker refresh (Sanhedrin)

Trigger: repeated tasks in recent 80 iterations (IQ-936x4, IQ-944x4, IQ-920x3, IQ-931x3, CQ-990x3, CQ-992x3).

Findings (actionable):
- Add per-task circuit breaker: open after 3 consecutive failures/no-progress attempts on same task_id; force task switch for one cycle.
- Classify retryable vs non-retryable errors before retry; skip retries on deterministic failures (missing file/tool/constraint mismatch).
- Add retry budget per task_id (e.g., max 2 immediate retries, then cooldown window) to prevent hidden LLM re-plan loops.
- Persist an anti-repeat memory key `(task_id, file_set_hash, error_class)` and block identical triplets within a rolling window.
- On circuit-open, inject explicit fallback policy into next prompt (choose different queued task, require different touched file set).

Sources:
- https://blog.vincentqiao.com/en/posts/claude-code-agent-loop/
- https://github.com/VictorVVedtion/ouro-loop
- https://dev.to/pockit_tools/7-patterns-that-stop-your-ai-agent-from-going-rogue-in-production-5hb1
