# Anti-stuck pattern: repeated task loops (IQ-878)

Trigger: inference agent repeated `IQ-878` 5 times in recent window.

Findings (research-backed):
- Add explicit "retry budget" per task ID (max 2 consecutive attempts), then force task rotation.
- Persist a short reflection note after each attempt (what failed, what changed), and block retries if note is unchanged.
- Require action-observation loops with concrete verification deltas (new test or new file diff) before allowing same task ID again.
- Tighten interface feedback: include failing command, exact file touch-set, and one required next action to avoid aimless retries.

Suggested guardrails for loop prompts:
- "If same task_id appears 3 times in last 10 iterations, pick next queue item and log reason."
- "No more than 2 consecutive passes on same task_id unless files_changed introduces new .HC lines."

Sources:
- https://arxiv.org/abs/2303.11366 (Reflexion)
- https://arxiv.org/abs/2405.15793 (SWE-agent)
- https://arxiv.org/abs/2210.03629 (ReAct)
