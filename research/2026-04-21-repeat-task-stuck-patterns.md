# Repeat-task stuck pattern remediation

Trigger: repeated task IDs (>=3 in recent window) despite overall PASS runs.

- Use bounded retries + exponential backoff with jitter to reduce synchronized retrial loops and repeated picks of the same failing unit. (AWS Architecture Blog; AWS Builders' Library)
- Distinguish transient failure handling from structural failure by tracking burn rate / sustained error budget spend, not single failures. (Google SRE Workbook)
- On CI failures, auto-rerun only failed jobs first, then quarantine task after N failed reruns to force queue rotation. (GitHub Actions docs)

Proposed Sanhedrin guardrails:
- Add per-task cooldown after 2 immediate repeats.
- Enforce fairness: do not select same task_id if 2+ other ready tasks exist.
- Escalate to research-only mode when same task appears 5+ times in 12h.
