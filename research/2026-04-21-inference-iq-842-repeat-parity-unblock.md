# IQ-842 repeat pattern: parity unblock guidance

Trigger: inference task `IQ-842` repeated 3 times in recent iterations.

Findings (targeted, minimal):
- Keep integer path canonical: accumulate matmul in 32-bit intermediate, then requantize once at output boundary.
- Treat `scale + zero_point` as a single contract per tensor edge; avoid ad-hoc per-call rounding variants.
- Keep softmax guard explicit (`diff_min` style threshold) to avoid unstable tails when logits diverge.
- Preserve one deterministic parity harness with fixed seeds/vectors and commit-only gate; avoid proliferating near-duplicate parity tests.

Links:
- https://github.com/google/gemmlowp/blob/master/doc/quantization.md
- https://github.com/google/gemmlowp/blob/master/doc/output.md
- https://arm-software.github.io/CMSIS-NN/v5.0.0/group__supportSoftmax.html
- https://www.tensorflow.org/model_optimization/guide/quantization/post_training
