# Inference IQ-1011 repeat streak remediation (3x)

Trigger: inference agent repeated `IQ-1011` three consecutive iterations (00:33:59, 00:35:55 + prior run), indicating local optimization loop risk.

Findings:
- GGUF metadata/tensor info parsers should validate full tensor header envelopes before cursor commit (length, dims, type, offset, computed end), then commit atomically.
- Add corpus-driven parser fuzzing plus adversarial fixtures for truncated headers, oversized name lengths, and offset overflow to prevent “same guard, new wrapper” churn.
- Use rotation rule after 2 same-task passes: force one adjacent task (reader integration, bounds helper reuse, or failure-path tests) before returning.
- Prefer shared checked-read primitives to reduce duplicated preflight logic across `tensorinfo` and downstream loaders.

Suggested next slice for builder:
- Keep `IQ-1011` closed and queue a neighboring integration task that consumes checked tensor metadata in loader path, with a negative corpus test.

References:
- https://github.com/ggml-org/llama.cpp/blob/master/gguf-py/README.md
- https://huggingface.co/docs/hub/en/gguf
- https://google.github.io/oss-fuzz/
