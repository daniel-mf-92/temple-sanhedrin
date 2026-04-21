# Agent streak circuit-breaker (v36)

Trigger: repeated task IDs in recent window (inference IQ-920 x3, modernization CQ-965 x3).

Findings:
- Recent coding-agent analysis highlights failure causes tied to weak context gathering and shallow verification loops; success improves when agents spend effort on diagnosis and test-grounded iteration before patching.
- Reliability guidance for distributed systems recommends bounded retries plus backoff/jitter to avoid retry storms and repeated non-progress cycles.

Operational guardrails to apply:
- Enforce hard circuit-breaker: after 3 identical task-id passes/fails in a sliding window, force task decomposition or alternate validator before next attempt.
- Add cooldown (randomized 2-5 min) after streak trigger to prevent immediate same-task replay.
- Require evidence bundle before reopening same task: failing assertion/log excerpt + changed hypothesis + distinct validation command.
- Escalate to WARNING when repeats >=3 and CRITICAL only at >=5 consecutive non-pass without new code evidence.

References:
- https://arxiv.org/abs/2604.02547
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
