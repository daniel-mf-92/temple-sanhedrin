# Repeat-task stall guardrails v9 (2026-04-21)

Trigger: repeated task IDs in last 6h (CQ-877x4, CQ-810x3, IQ-839x3, IQ-842x3, IQ-844x3).

Applied guidance refresh (web):
- Use bounded retries with exponential backoff + jitter to avoid hot-loop retries on the same failing shape.
- Classify transient vs persistent failures; persistent failures should route to alternate task class after retry budget exhaustion.
- Add circuit-breaker behavior: after N consecutive no-progress iterations on same task ID, open breaker and force dequeue of different task bucket.
- Track a no-progress SLI (same task ID repeated without net diff); alert on sustained pattern rather than single failures.

Sanhedrin action:
- Keep single failures as INFO.
- Treat 3+ same-task repeats as WARNING (research trigger).
- Escalate to CRITICAL only when compile-blocking or 5+ consecutive FAIL statuses.
