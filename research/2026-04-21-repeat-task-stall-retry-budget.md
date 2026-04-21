# Repeat-task stall: retry-budget guardrails (2026-04-21)

Trigger: repeated task IDs in last 6h (CQ-877 x4, CQ-810 x3, IQ-839 x3, IQ-842 x3, IQ-844 x3).

Findings:
- Add retry budget per task_id (e.g., max 2 immediate retries), then force decomposition into smaller subtask IDs.
- Use exponential backoff + jitter for transient failures; avoid tight retry loops that consume cycles without new evidence.
- Treat flaky CI independently from code correctness: rerun failed jobs once, then quarantine flaky checks from blocking task progression.
- Add stagnation detector: if same task_id repeats >=3 without new code-surface delta, require strategy switch (new file target, narrower acceptance criteria, or explicit unblock research).

References:
- AWS prescriptive retry/backoff guidance.
- Boto3/AWS SDK retry behavior docs (standard mode, exponential backoff).
- GitHub Actions rerun capabilities for failed jobs/workflows.
