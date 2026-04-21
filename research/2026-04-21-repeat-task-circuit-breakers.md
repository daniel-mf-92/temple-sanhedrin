# Repeat-task mitigation for builder loops (IQ-931 pattern)

Trigger: repeated task selection (>=3 repeats) observed in recent inference iterations.

## External guidance reviewed
- Azure Architecture Center — Circuit Breaker pattern (open/half-open/closed states): https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker
- AWS Builders Library — retries/backoff with jitter, bounded retries: https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- GitHub Actions docs — workflow/job concurrency and cancel-in-progress controls: https://docs.github.com/actions/writing-workflows/choosing-what-your-workflow-does/control-the-concurrency-of-workflows-and-jobs

## Applied recommendations for loop policy
- Add per-task failure streak counters; open circuit after 3 consecutive non-progress attempts.
- In open state, quarantine the task for a cooldown window (e.g., 60–90 minutes) and force next-task selection.
- Enforce bounded retries with jittered backoff for flaky external failures; no unbounded retries.
- Record a `non_progress_reason` code in central DB for every repeated task pick.
- Add queue de-dup guard: reject re-queue of same task+scope while open circuit active.
- Use workflow/job concurrency cancellation for stale CI runs to reduce feedback lag.

## Success criteria
- No task ID appears >2 times in latest 40 iterations without `files_changed` delta.
- Consecutive non-progress streaks drop below 5 for both agents.
