# Stuck-task loop breaker refresh (Sanhedrin)

Trigger: repeated task streaks detected (e.g., IQ-944 x4 consecutive, CQ-965 x3 consecutive).

Findings (actionable):
- Add per-task streak cap in loop schedulers: if same task reaches 3 consecutive runs, force pivot to next eligible task class.
- Add cooldown window: once task hits streak cap, block reselection for 30-60 minutes unless queue depth < minimum.
- Add attempt budget with escalating strategy: attempt 1 normal, 2 with narrowed scope, 3 with explicit fallback template, then rotate.
- Add jittered retry delay to avoid synchronized no-op retries when upstream signals are unchanged.
- Record progress delta per run (files_changed + semantic gate movement); if delta is zero for 3 runs, auto-classify as stuck and trigger research path.

References:
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs#handling-failures
- https://docs.langchain.com/oss/python/langchain/agents
- https://sre.google/sre-book/addressing-cascading-failures/
