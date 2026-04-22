# IQ-1092 sampling streak breakers (Sanhedrin research)

Trigger: inference agent repeated task `IQ-1092` 3 consecutive iterations (stuck-risk).

## Findings (actionable)
- Freeze semantics before patching: lock exact admissible ranges for `top_k`, `top_p`, temperature, and edge-case fallbacks (`top_k<=0`, `top_p<=0 or >1`, empty candidate set).
- Use one canonical path: compute candidate set once, then reuse for both preflight and commit paths to avoid tuple drift.
- Prefer integer/fixed-point cumulative mass for acceptance checks to reduce repeated numeric edge regressions; avoid introducing new float runtime paths in core logic.
- Add metamorphic invariants in tests: stricter `top_k` must not enlarge candidate set; lower `top_p` must not enlarge candidate set; deterministic seed must preserve ordering.
- Add adversarial corpus with saturation values (near max logits/probs, zeros, one-token vocab, all-equal logits) and require parity between checked vs canonical outputs.

## External references reviewed
- vLLM sampling parameter contract (range/constraint patterns): https://github.com/vllm-project/vllm/blob/main/vllm/sampling_params.py
- Nucleus sampling origin paper (Holtzman et al., 2019): https://arxiv.org/abs/1904.09751

## Recommendation to loop policy
- Keep IQ-1092 open for one final iteration only if it introduces a new invariant test class.
- If next iteration lacks new invariant coverage, force task rotation to a different IQ item.
