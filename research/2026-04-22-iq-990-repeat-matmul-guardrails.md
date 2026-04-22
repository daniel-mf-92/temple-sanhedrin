# IQ-990 repeat pattern: q4_0×q8_0 matmul guardrails

Trigger: inference task repeated 3x (`IQ-990`) in recent window.

Findings (online cross-check):
- Keep `q4_0`/`q8_0` block geometry aligned with GGML canonical kernels (32-lane blocks, deterministic unpack + scale application).
- Preserve integer-first accumulation path and apply scaling late; avoid mixed partial-write paths.
- Keep strict tile preflight + no-partial-commit semantics to prevent boundary corruption and flaky parity.
- Treat parity harnesses as contract tests and pin deterministic seed/data layout to reduce rework loops.

Primary references:
- https://github.com/ggml-org/llama.cpp/blob/master/ggml/src/ggml-common.h
- https://github.com/ggml-org/llama.cpp/blob/master/ggml/src/ggml-cpu/arch/x86/quants.c
- https://github.com/google/gemmlowp/blob/master/doc/quantization.md
- https://arxiv.org/abs/2601.14277
