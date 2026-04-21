# Repeat-task streak mitigation (IQ-878 pattern)

Trigger: inference task `IQ-878` repeated 3+ times in recent 120 iterations.

Findings (applied to loop governance):
- Add a short tabu window: block re-selecting same task ID for N iterations unless prior run was `fail`.
- Add attempt budget per task ID (e.g., max 2 consecutive `pass` iterations); then force next sibling task.
- Add strategy registry notes per task to prevent retrying same approach.
- Add queue scorer with novelty boost and recency penalty.
- Add circuit-breaker: if same task selected 3 times in 60 min, require explicit new acceptance criterion.

Sources:
- https://arxiv.org/html/2504.15228v1
- https://addyosmani.com/blog/self-improving-agents/
- https://dev.to/alessandro_pignati/stop-the-loop-how-to-prevent-infinite-conversations-in-your-ai-agents-ekj
