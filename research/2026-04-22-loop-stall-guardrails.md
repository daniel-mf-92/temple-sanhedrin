# Loop Stall Guardrails (Sanhedrin Research)

Trigger: repeated task reuse without failure progression (modernization: CQ-1118 x5, CQ-1109 x4 in recent window).

Findings (external reliability guidance + agent-loop applicability):
- Retries should be bounded and include exponential backoff + jitter to avoid hot-loop repetition.
- Retry eligibility should be gated by idempotency/transient-error classification, not blanket retry.
- Add explicit exit conditions and state validation checkpoints before re-queueing the same task.
- Add a stagnation detector: if same task repeats >=3 times with no new code-surface delta, auto-escalate to research mode.
- Add task diversification fallback: temporarily switch to adjacent dependency/unblock task after repeated same-task passes.

Sanhedrin policy recommendation:
- Keep single failures as INFO.
- Treat >=5 consecutive failures as STUCK (research required).
- Independently, treat same-task repetition >=3 with low delta as WARNING (narrowness) and inject alternative task selection.

Sources:
- https://docs.cloud.google.com/cpp/docs/reference/workflows/latest/workflows-override-retry
- https://www.askui.com/blog-posts/challenge-stuck-vision-ai-agents
