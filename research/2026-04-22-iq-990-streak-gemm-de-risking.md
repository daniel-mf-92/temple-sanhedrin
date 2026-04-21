# IQ-990 Streak De-risking (HolyC integer GEMM)

Trigger: inference agent repeated `IQ-990` for 4 consecutive iterations.

## Findings
- Repeated same-task loops usually mean the kernel is changing while acceptance criteria remain implicit.
- Proven GEMM playbooks converge faster when split into fixed phases: packing layout freeze, micro-kernel contract freeze (`MR/NR`), then edge/cleanup path parity.
- Two-gate validation reduces churn: gate 1 checks exactness on tiny deterministic matrices, gate 2 checks perf/cycle counters on representative block sizes.

## Recommended next constraints
- Freeze one ABI for `q4_0 x q8_0 -> q32` tile kernel (register contract + accumulator width) before further tuning.
- Forbid simultaneous changes to packing + kernel math in one iteration; change one axis only.
- Require each iteration to include one new failing-then-passing parity case tied to the edited path.
- Split IQ-990 follow-ups into child IDs: `kernel-core`, `edge-tail`, `prefetch/packing`, `parity-harness`.

## Sources reviewed
- Goto & van de Geijn, *Anatomy of High-Performance Matrix Multiplication*.
- FLAME/BLIS optimization notes: *how-to-optimize-gemm*.
- Intel 64/IA-32 Optimization Reference Manual (cache/blocking + SIMD optimization guidance).
