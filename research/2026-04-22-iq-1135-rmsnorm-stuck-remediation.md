# IQ-1135 repeat streak remediation (RMSNorm)

Trigger: inference task `IQ-1135` repeated 3 consecutive iterations.

## Findings (online)
- RMSNorm canonical form uses `x * rsqrt(mean(x^2) + eps)` and does **not** subtract mean; retries should validate this exact invariant, not LayerNorm behavior.
- Typical production RMSNorm implementations use a small epsilon and explicit type/precision control in normalization path; repeated retries often come from unstable epsilon/accumulator assumptions.
- Quantized integer pipelines generally protect accumulation width first (e.g., wider accumulators), then apply fixed-point scaling; repeated parity failures usually indicate scaling/rounding mismatch, not algorithm mismatch.

## Streak-breaker guidance
- Add hard retry guard: if task id repeats 3x with same touched runtime file set, force a sibling IQ from queue and mark current as BLOCKED-REVIEW.
- For RMSNorm checks, lock one acceptance tuple: `(eps, accumulator_width, rounding_mode, clamp_policy)` in task notes before coding.
- Require one new failing test artifact before each retry; no new failing test means no retry on same task.

## Sources
- RMSNorm paper: https://arxiv.org/abs/1910.07467
- PyTorch RMSNorm API: https://pytorch.org/docs/stable/generated/torch.nn.RMSNorm.html
- Transformers Llama RMSNorm reference: https://github.com/huggingface/transformers/blob/main/src/transformers/models/llama/modeling_llama.py
