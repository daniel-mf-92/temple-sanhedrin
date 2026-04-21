# IQ-878 loop-breaker research

Trigger: inference task `IQ-878` repeated 5 times in recent window.

Findings:
- KV-cache work should prioritize measurable throughput/latency/memory outcomes, not repeated wrapper variants.
- Prefer page/block-based cache allocation with fragmentation controls and explicit reuse policies.
- Add a task-exit gate: no further IQ-878 iterations unless a new benchmark delta or failing regression is demonstrated.
- Track one hard metric per iteration (e.g., peak KV memory, tokens/s, p95 latency) to prevent narrow repetitive edits.

Sources:
- https://arxiv.org/abs/2309.06180
- https://docs.vllm.ai/en/v0.4.3/
- https://huggingface.co/docs/transformers/main/cache_explanation
