# IQ-1135 stuck-pattern research (RMSNorm checked semantics)

Trigger: inference agent repeated `IQ-1135` 3 consecutive iterations.

Findings (actionable):
- Keep epsilon in denominator path for numerical stability; default to dtype/opmath epsilon when not explicit.
- Prefer strict shape/stride guards before numeric work; fail fast on aliasing and capacity mismatch.
- Keep overflow checks in accumulation path for quantized variants; validate row-batch behavior with parity tests.
- Preserve RMSNorm semantics (scale-only normalization, no recentering) to avoid drifting into LayerNorm behavior.

Sources reviewed:
- PyTorch RMSNorm docs
- RMSNorm paper (arXiv:1910.07467)
- ONNX Runtime quantization guidance
