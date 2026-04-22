# Sanhedrin research: repeat-task streak circuit breakers

Date: 2026-04-22
Trigger: modernization repeated CQ-1191/CQ-1197/CQ-1198 and inference repeated IQ-1092/IQ-1094 (3+ appearances in recent window).

Findings:
- Retry loops need bounded retry count plus exponential backoff with jitter to avoid synchronized retry storms and false progress.
- Cascading-failure guidance recommends dropping or deferring retried work when load/error signals rise, instead of immediate repeated retries.
- CI reruns should target failed jobs only and be used for triage, not as a substitute for root-cause isolation.

Action shape for builder loops:
- Hard cap identical `task_id` retries to 2, then force task rotation.
- Require progress proof (new executable/code artifact or failing test delta) before retrying same `task_id`.
- Add cooldown window before re-queueing identical `task_id`.
