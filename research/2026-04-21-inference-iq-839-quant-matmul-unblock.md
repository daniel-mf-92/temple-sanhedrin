# IQ-839 unblock research (quantized matmul path)

Trigger: `inference` repeated `IQ-839` for 3 consecutive iterations.

Findings:
- Q4_0 and Q8_0 in llama.cpp use block-wise quantization (32-value blocks), so kernel scheduling should preserve block alignment and avoid tail-heavy scalar fallbacks.
- Low-precision GEMM libraries (gemmlowp, FBGEMM) consistently emphasize packing/reordering (`A`/`B`) and cache-blocked microkernels; this reduces memory bandwidth stalls more than wrapper-level task churn.
- Practical unblock for IQ-839: prioritize one measurable kernel-side change (packed RHS reuse or explicit tile/block constants) and gate with a per-iteration perf delta target, instead of additional commit-only wrappers.

Suggested next patch shape for agent:
- Implement one HolyC kernel-path change tied to `q4_0 x q8_0` dot/matmul inner loop.
- Add benchmark evidence in notes (before/after tokens/s or cycle count) to prove progress.
- If no measurable delta after 2 iterations, switch subtask (avoid local maxima on wrapper plumbing).

References:
- https://github.com/ggml-org/llama.cpp/discussions/5063
- https://github.com/google/gemmlowp
- https://github.com/google/gemmlowp/blob/master/doc/low-precision.md
- https://github.com/pytorch/FBGEMM
- https://docs.pytorch.org/FBGEMM/
