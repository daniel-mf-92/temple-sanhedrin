# Repeat-task streak remediation (IQ-920, CQ-965)

Trigger: repeated task IDs (3x) observed in recent 80 builder iterations.

- Add hard repeat guard: if same task appears 3x in window, block it for 2 cycles and force next oldest unblocked task.
- Add reflection memory: persist last failure cause + "what changed" delta; reject retries with identical plan hashes.
- Add exploration fallback: after 2 failed retries, require one orthogonal strategy (different file set or validation path).
- Add progress gate: retry only when diff touches code artifacts relevant to task acceptance.

References:
- https://arxiv.org/abs/2210.03629
- https://arxiv.org/abs/2303.11366
- https://arxiv.org/abs/2303.17651
