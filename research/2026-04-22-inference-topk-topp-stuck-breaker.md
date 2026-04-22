# Inference stuck-pattern breaker: top-k/top-p parity loops

Trigger: inference agent repeated `IQ-1092` in consecutive iterations (>=3), indicating local optimization loop risk.

## Key findings (online)
- Nucleus sampling (`top_p`) should include the smallest token prefix whose cumulative probability reaches threshold `p`; boundary handling must be deterministic and consistent.
- Very peaky distributions can make nucleus effectively deterministic (single-token nucleus), so parity tests should include both peaky and flat distributions.
- Fixed `top_k` and dynamic `top_p` interact; robust tests should validate ordering, truncation, and renormalization invariants separately.

## Recommended anti-stuck test matrix
- Boundary-at-threshold cases: cumulative mass exactly equals `p` and just-over-`p` by one token.
- Degenerate peaky logits: one-token nucleus expected; verify no out-of-bounds and deterministic behavior.
- Flat logits: large candidate set; verify stable sorting/tie behavior and normalization sum.
- Combined constraints: `top_k` then `top_p` vs `top_p` then `top_k` (explicit expected policy and assertion).
- Seeded parity corpus: fixed seeds + fixed logits snapshots to prevent repeated retuning drift.

## Sources
- https://huyenchip.com/2024/01/16/sampling.html
- https://arxiv.org/html/2408.16345v1
