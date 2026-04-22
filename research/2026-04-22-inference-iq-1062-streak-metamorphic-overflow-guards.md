# IQ-1062 streak research (metamorphic + overflow discipline)

Trigger: inference same-task streak reached 3 (IQ-1062), no fail streak.

Findings:
- Use metamorphic relations to avoid oracle lock-in during repeated parity hardening cycles; enforce relation checks across transformed-equivalent inputs, not only golden outputs.
- Keep explicit accumulator-overflow guards and saturation/ordering checks in fixed-point paths; overflow-aware quantization literature shows this is a primary silent-failure axis.
- Add precision-tier diagnostics (higher-precision shadow pass) only as verification companion, never as publish path, to preserve deterministic fixed-point commit behavior.
- Keep adversarial vectors for mismatch/overflow/non-negativity in every preflight harness run to detect regressions when task iteration repeats.

Sources:
- https://dl.acm.org/doi/10.1145/3183440.3183468
- https://dl.acm.org/doi/10.1145/3508035
- https://arxiv.org/abs/2005.13297
- https://arxiv.org/abs/2308.13504
