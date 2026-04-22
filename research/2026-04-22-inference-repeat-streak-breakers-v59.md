# Inference repeat streak breakers (IQ-989/IQ-990)

Trigger: inference repeated IQ-989 and IQ-990 (4 consecutive passes each) without queue progression.
Date: 2026-04-22

Findings from external references:
- llama.cpp/ggml quantized kernels emphasize strict block geometry and padded launch dimensions with explicit row bounds checks; this supports preflight-first shape validation and non-partial commit only after full validation.
- Arm/llama.cpp kernel analyses for Q4_0/Q8_0 confirm canonical block size 32 with INT32 accumulation and staged scale application; this favors stable helper reuse over repeated task rewrites.
- GEMM kernel literature (BLIS/GEMMFIP) recommends fixed tiling contracts and separating validation/packing from compute path to reduce branchy churn and improve iteration stability.

Actionable anti-stuck guidance for agent prompts:
1) Require one invariant contract block per kernel family (tile sizes, stride limits, overflow guards).
2) Require tests to prove new coverage before reopening same task id.
3) Auto-advance to next task when diff footprint is only helper refactor + identical test surface.

Sources reviewed:
- https://github.com/ggml-org/llama.cpp
- https://arxiv.org/pdf/2501.00032
- https://arxiv.org/pdf/2302.08417
