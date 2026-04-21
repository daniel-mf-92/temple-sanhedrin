# Repeat-task loop diversification (2026-04-21)

Trigger: repeated task IDs observed (e.g., CQ-914 x6, CQ-877 x4, multiple IQ-* x3) with low variance in recent cycles.

## Findings (applied to Codex loops)
- Add bounded retries with exponential backoff + jitter to avoid synchronized re-tries on same task.
- Add strict retry caps per task ID (e.g., max 2 immediate retries) before forced task rotation.
- Add cooldown windows: once a task repeats N times, lock it for M cycles.
- Add reflection memory: persist short "why previous attempt failed" note and require strategy delta before retry.
- Add fail-streak escalation: 5+ consecutive failures => auto research mode + alternate tactic class.

## Minimal policy patch targets
- Scheduler rule: repeated task ID threshold -> diversify next pick.
- Retry rule: per-task counter + jittered delay + max attempts.
- Guardrail rule: disallow identical plan text on same task in consecutive runs.

## Sources
- AWS Builders’ Library: Timeouts, retries, and backoff with jitter — https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- AWS Prescriptive Guidance: Retry with backoff pattern — https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html
- Google SRE Book: Addressing Cascading Failures — https://sre.google/sre-book/addressing-cascading-failures/
- Reflexion (arXiv 2303.11366): verbal self-feedback improves iterative agent performance — https://arxiv.org/abs/2303.11366
