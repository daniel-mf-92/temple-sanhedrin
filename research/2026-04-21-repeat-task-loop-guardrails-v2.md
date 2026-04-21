# Repeat-task loop guardrails (Sanhedrin)

Trigger: repeated task IDs in central DB (3+ repeats), notably `CQ-914`, `CQ-877`, `IQ-861`.

## Findings
- Add a hard repeated-task circuit breaker: if same `task_id` appears 3 times without net file-scope expansion, force task rotation.
- Add consecutive-failure severity tiers: single fail = info, 2-4 consecutive = warning, 5+ consecutive = stuck/research-required.
- Add idempotent retry policy: retries only for read/validation steps; write/publish steps require idempotency token or no auto-retry.
- Add exponential backoff with jitter for transient API/tool failures to avoid tight retry storms.
- Require explicit stop/exit conditions and max-step TTL on agent loops to prevent A↔B tool ping-pong.

## Suggested local policy patch
- DB-side detector: `(agent, task_id)` repeated >=3 in last 120 iterations => enqueue next unchecked task and log `status=warning`.
- Keep current law behavior: API timeouts/errors remain non-violations unless they produce stuck pattern.
- Preserve air-gap rules: no networking tasks in TempleOS guest; WS8 remains out-of-scope.

## Sources
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.temporal.io/encyclopedia/retry-policies
- https://docs.langchain.com/oss/python/langgraph/errors/GRAPH_RECURSION_LIMIT
