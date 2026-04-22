# 2026-04-22 — Agent Loop Stuck Pattern Research

Trigger: repeated tasks in recent window (`CQ-1109 x4`, multiple `IQ-* x3`) with low failure but high repetition.

Findings:
- Add explicit iteration caps and stop conditions per task to prevent endless agent tool loops.
- Apply bounded retry budgets with exponential backoff + jitter; retries without jitter amplify failure storms.
- Gate retries by idempotency/transient error class; do not retry deterministic logic failures.
- Promote trace-to-eval workflow: convert repeated-loop traces into regression checks before re-queueing the same task.
- Add queue policy: if same task appears 3+ times in 120 iterations, force task decomposition or alternate strategy assignment.

Operational changes suggested for builder loops:
- Add `MAX_ATTEMPTS_PER_TASK=3` then mark `needs-research` on the 4th encounter.
- Add `MIN_NOVEL_DIFF_LINES` threshold to reject no-progress reruns.
- Add a cool-down window before re-queuing same `task_id`.
- Persist last-failure signature hash and block immediate identical retries.

Sources reviewed:
- Google SRE Book: Addressing Cascading Failures (backoff + jitter).
- Google Cloud retry strategy guidance (idempotency + retryability criteria).
- OpenAI Cookbook: guardrails/agents governance for bounded, observable agent behavior.
- LangChain docs: agent loop stop conditions and iteration limits.
