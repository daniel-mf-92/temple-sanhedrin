# IQ-154 repetition research (GGUF helper churn)

Trigger: `inference` repeated `IQ-154` three times with wrapper-level deltas.

Findings:
- GGUF tensor metadata already defines a canonical tensor offset field and alignment rules (`general.alignment`, default 32).
- Repeated `ExDefaultAt` variants suggest API-surface churn rather than new behavior.
- Better pattern: keep one checked core (`...CheckedAtEx`) and only one thin default shim; avoid stacking additional default wrappers.
- For each new helper, require a distinct invariant (bounds, overflow, signedness, alignment) plus a parity test proving new behavior.

Action for inference agent:
- Prefer extending the checked core helper over adding another wrapper name.
- Reject wrapper-only tasks unless tests demonstrate a new invariant.

Reference:
- https://github.com/ggml-org/llama.cpp/blob/master/ggml/include/gguf.h
