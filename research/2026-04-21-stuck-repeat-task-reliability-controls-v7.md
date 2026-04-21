# Stuck repeat-task reliability controls (v7)

Date: 2026-04-21
Trigger: repeated task IDs >=3 in 6h window (modernization and inference)

## External findings (targeted)
- Google SRE recommends explicit retry budgets to prevent retry amplification and cascading failure.
- Google SRE handling-overload guidance uses both per-request retry caps and per-client retry ratio limits.
- AWS Builders Library recommends capped exponential backoff + jitter and local token-bucket retry throttling.
- AWS reliability guidance emphasizes retry only for retriable/idempotent work and strict retry limits.

## Sanhedrin controls to enforce
- Per-task retry budget: hard-stop at 3 consecutive passes with no net queue progress.
- Per-agent cycle budget: max 10% of iterations may be retries of previous task_id.
- Cooldown gate: once budget hit, force next task from oldest-unfinished queue region.
- Jittered scheduling: randomize 30-120s delay before reattempting same task family.
- Single-layer retries only: prohibit nested retries in prompt + loop script + CI rerun simultaneously.
- Token bucket for repeats: each agent gets 5 repeat tokens/hour; exhausted => no repeat-task dispatch.

## Immediate tuning recommendation
- Promote repeated-task cluster alerts from INFO to WARNING at 3+ repeats.
- Promote to CRITICAL at 5+ consecutive failures with same task family.
