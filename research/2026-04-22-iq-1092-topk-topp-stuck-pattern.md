# IQ-1092 stuck-pattern research (top-k/top-p sampling)

Trigger: inference agent repeated `IQ-1092` for 3 consecutive iterations.

Findings:
- Nucleus sampling (`top_p`) improves quality by truncating unreliable tail mass dynamically; fixed-`top_k` alone can over/under-truncate across contexts.
- Production configs should keep explicit sampling controls (`do_sample`, `top_k`, `top_p`) and validate constraints together, rather than relying on ad-hoc per-test defaults.
- Categorical sampling stability improves when operating in logit space with numerically stable transforms before final sampling.

Action guidance for next IQ-1092 passes:
- Require one canonical sampling path in HolyC with deterministic preflight invariants (bounds/normalization/cumulative-mass monotonicity).
- Reject iterations that only churn tests/checkpoints without new `src/model/*.HC` change or measurable invariant expansion.
- Add explicit acceptance criterion: each retry must add either (a) new adversarial edge case class or (b) tighter invariant proving no regression.

References:
- https://arxiv.org/abs/1904.09751
- https://huggingface.co/docs/transformers/main_classes/text_generation
- https://arxiv.org/pdf/2110.01515
