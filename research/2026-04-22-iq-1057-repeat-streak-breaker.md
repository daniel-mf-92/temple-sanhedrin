# IQ-1057 repeat-streak breaker (research)

Trigger: inference repeated `IQ-1057` 3 consecutive passes.

Findings (apply to next queue picks):
- Add metamorphic relations for sampling invariants (rank-preserving token remaps, monotonicity under tighter `top_p`, deterministic behavior with fixed seed) to break single-task overfitting.
- Add calibration checks for truncation tails (nucleus/top-k set stability under entropy buckets) to detect regressions that unit tests miss.
- Add differential oracle mode: compare HolyC sampler outputs against a frozen reference corpus of logits + expected admissible token sets, not just exact token IDs.
- Rotate task class after 2 repeats: force next item to non-sampling surface (gguf parser, kv-cache, quant decode) unless a failing regression exists.

Sources:
- https://arxiv.org/abs/1904.09751
- https://openreview.net/forum?id=1tk6M8OTeJ
- https://arxiv.org/abs/2507.04354
