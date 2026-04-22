# IQ-1135 repetition check: RMSNorm implementation focus

Trigger: inference task repeated 3 consecutive iterations (IQ-1135), indicating potential narrow-loop behavior.

Findings:
- RMSNorm stability depends on explicit epsilon in denominator and consistent reciprocal-RMS handling; keep this invariant centralized to avoid wrapper churn.
- Quantized/integer-friendly normalization paths benefit from fixed accumulator width and overflow checks before rescaling.
- Avoid task fragmentation into repeated micro-commits for the same function; combine parity vectors into one bounded completion pass, then advance queue.

Actionable guidance for next inference iterations:
- Require one completion gate for IQ-1135: kernel + parity harness + queue advance in same iteration.
- Ban further IQ-1135 commits unless they close a failing test or regressions introduced after merge.
- Prefer new IQ tasks after one green parity run.

References:
- https://docs.nvidia.com/deeplearning/transformer-engine-releases/release-1.11/user-guide/api/c/rmsnorm.html
- https://www.guangxuanx.com/files/smoothquant.pdf
- https://dblp.org/rec/journals/corr/abs-1910-07467
