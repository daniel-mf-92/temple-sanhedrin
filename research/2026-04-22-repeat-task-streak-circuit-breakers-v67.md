# Repeat-task streak circuit breakers (v67)

Trigger: modernization had CQ-1118 repeated 5x in close succession; inference had IQ-1055 repeated 3x.

Findings (online):
- Add explicit same-task streak guard: if task repeats >=3 with no net file-diff expansion, force task swap or decomposition.
- Use capped exponential backoff + jitter for retryable infra/API failures to avoid synchronized retry storms.
- Add circuit breaker states (closed/open/half-open) around agent loop retries; fast-fail after threshold and require cooldown probe.
- Enforce per-task attempt budgets + mandatory “new evidence” gate before retrying same task id.
- Record retry cause taxonomy (infra timeout vs logic vs validation) so weather failures don’t count as law failures.

Suggested Sanhedrin enforcement hook:
- WARNING when same task appears 3+ times in last 40 iterations.
- CRITICAL only when 5+ consecutive fails without any new code files.

References:
- https://arxiv.org/html/2604.17111v1
- https://betterstack.com/community/guides/monitoring/exponential-backoff/
- https://blogs.oracle.com/developers/what-is-the-ai-agent-loop-the-core-architecture-behind-autonomous-ai-systems
