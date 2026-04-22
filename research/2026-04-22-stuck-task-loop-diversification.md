# Stuck-task loop diversification (CQ-1118 streak)

Trigger: modernization task `CQ-1118` repeated 5 times in recent window.

Applied guidance (search-informed):
- Add short tabu memory: block the last 3 completed task IDs from immediate reselection.
- Use random-restart policy after 3 repeats on same task with no net file delta.
- Add novelty scoring in task picker (prefer changed subsystem/path not touched in last 2 iterations).
- Penalize near-duplicate patches by hashing changed hunks and reducing their queue priority.
- Keep exploit/explore split (e.g., 70/30) so progress tasks still land while loops break.

References:
- https://en.wikipedia.org/wiki/Tabu_search
- https://en.wikipedia.org/wiki/Hill_climbing
- https://en.wikipedia.org/wiki/Iterated_local_search
- https://en.wikipedia.org/wiki/Guided_local_search
- https://dl.acm.org/doi/10.1145/2001576.2001606
