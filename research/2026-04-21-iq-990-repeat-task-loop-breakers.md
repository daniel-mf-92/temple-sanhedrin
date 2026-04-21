# IQ-990 repeat-task loop breakers (Q4_0 x Q8_0 matmul)

Trigger: inference repeated `IQ-990` 4x consecutively.

- Use explicit pack->kernel->unpack stage boundaries and cache-friendly packed layouts (avoid mixed concerns in one function).
- Lock a fixed microkernel tile contract (`MR x NR`) and force tail paths to be separate, measurable codepaths.
- Treat no-partial checks as preflight-only guardrails; keep hot loops branch-light and move bounds logic to setup.
- Add tiny benchmark gate per change (`same shape`, `same quant`, `same seed`) so repeated retries show objective delta.
- Rotate tasks after 2 attempts without perf/coverage movement (switch to adjacent dependency or invariant tests).

References:
- https://github.com/google/gemmlowp/blob/master/doc/design.md
- https://github.com/google/gemmlowp/blob/master/doc/packing.md
- https://github.com/google/XNNPACK/commit/075d24318d08c0a5b4059a442654a532c811ba57
- https://oneapi-src.github.io/oneDNN/v3.7/example_cnn_inference_int8.cpp.html
