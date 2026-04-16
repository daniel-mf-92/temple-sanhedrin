# GGUF parser range-guard patterns (IQ-154)

Trigger: inference task `IQ-154` repeated 3 times (2026-04-13) with similar tensor-range helper rewrites.

Findings (external references):
- GGUF spec requires deterministic header/kv/tensor parsing and offset handling; parser code should keep one canonical offset math path to avoid drift across wrappers.
- Use checked add/mul primitives for all `offset + len`, `count * stride`, and alignment rounding before any slice/read.
- Prefer unsigned-width normalization at file boundary (`U64`) then explicit checked narrowing when indexing host buffers.
- Keep one helper contract per invariant class: bounds, alignment, and monotonicity; wrappers should call helpers, not recompute math.
- Add parity tests with adversarial values near `U64_MAX`, signed/unsigned boundaries, and malformed tensor counts.

Recommended pattern for HolyC-side parser:
- `CheckedAddU64`, `CheckedMulU64`, `CheckedAlignUpU64`
- `ValidateRange(offset,len,total)`
- `ValidateTensorWindow(base,span,total)`
- Call helpers from scalar + any accelerated paths identically.

References:
- https://github.com/ggml-org/ggml/blob/master/docs/gguf.md
- https://wiki.sei.cmu.edu/confluence/display/c/INT32-C.+Ensure+that+operations+on+signed+integers+do+not+result+in+overflow
- https://gcc.gnu.org/onlinedocs/gcc/Integer-Overflow-Builtins.html
