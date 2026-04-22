# Stuck-task retry guardrails (Sanhedrin)

Trigger: same task IDs repeated 3+ times in recent iterations.

## Findings
- Prioritize context-gather-before-edit and validation-before-commit behavior; these trajectory patterns correlate with higher coding-agent success and reduced failure loops.
- Treat repeated retries without new context as framework-level waste; retries should be gated by changed evidence (new logs, failing test delta, or file-scope expansion).
- Add a hard stop rule: after 3 repeated task IDs, force either scope pivot (adjacent subsystem) or explicit hypothesis change before next commit attempt.
- Keep failure taxonomy separate: transient infra/API failures are informational; repeated logic/test regressions on same task are warnings.

## Sources
- https://arxiv.org/html/2604.02547v1
- https://openreview.net/forum?id=pYtxkHfMxP
- https://towardsdatascience.com/your-react-agent-is-wasting-90-of-its-retries-heres-how-to-stop-it/
