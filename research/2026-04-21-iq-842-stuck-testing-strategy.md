# IQ-842 unblock research (2026-04-21)

Trigger: inference same task streak reached 3 on `IQ-842`.

## Findings
- Prefer metamorphic relations for attention kernels (permutation invariance, masked-token invariance, scale monotonicity) to reduce oracle ambiguity.
- Differential checks need tolerance-aware comparators (ULP/relative tolerance), not strict bit-equality, to avoid false positives.
- Add seed-sweep fuzz harness around small matrix shapes and adversarial edge values to catch partial-write and overflow regressions early.
- Keep commit/no-partial semantics, but separate `preflight` invariants from `numeric` invariants in tests to localize failures faster.

## Sources reviewed
- https://ieeexplore.ieee.org/abstract/document/10229487
- https://dl.acm.org/doi/10.1145/3689757
- https://lingming.cs.illinois.edu/publications/asplos2023.pdf
- https://docs.nvidia.com/deeplearning/tensorrt/latest/inference-library/accuracy-considerations.html
