# Cross-Repo Audit: Matrix-Shape Telemetry vs Matmul Geometry Contract Drift

Timestamp: 2026-04-29T05:09:28+02:00

Scope: Cross-repo invariant check between TempleOS modernization and holyc-inference. This is historical/deep audit only; no live liveness watching and no trinity source changes.

Repos checked:
- TempleOS: `abbc679bc7c429c0d89cdef04432b2e7a9d51fc7` (`feat(modernization): codex iteration 20260429-045038`)
- holyc-inference: `ce09228422dae06e86feb84925d51df88d67821b` (`feat(inference): codex iteration 20260428-085506`)

## Audit Question

Does TempleOS' "matrix-shape" telemetry contract match what holyc-inference matmul kernels actually require for Q4_0/Q8_0 tensor execution?

Short answer: no. TempleOS has a large matrix-shape status vocabulary, but it is synthetic threshold/sweep telemetry. holyc-inference's matmul contract is concrete block/tile geometry with checked row/column strides, K-block span, capacities, overflow surfaces, and Q16/Q32 output layout. There is no shared schema or explicit cross-repo mapping between the two.

## Evidence

### TempleOS Surface

TempleOS `Kernel/Sched.HC` contains matrix-shape emitters under names such as:
- `SchedLifecycleInvariantWindowCompareDigestClampStatusAnomalyTailThresholdSweepDigestMatrixShapeStatus`
- `SchedLifecycleInvariantWindowCompareDigestClampStatusAnomalyTailThresholdSweepDigestMatrixShapeTail`
- `SchedLifecycleInvariantWindowCompareDigestClampStatusAnomalyTailThresholdSweepDigestMatrixShapeWindow`
- `SchedLifecycleInvariantWindowCompareDigestClampStatusAnomalyTailThresholdSweepDigestMatrixShapeBand`

The status core clamps only abstract telemetry inputs: `threshold_bp`, `threshold_step`, and `sweeps`, then emits derived counts such as `matrix_cells=sweeps*sweeps`, diagonal/off-diagonal counts, transition parity, and `deterministic_ok`.

Relevant source ranges:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/Sched.HC:3677`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/Sched.HC:3770`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/Sched.HC:3776`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/Sched.HC:3833`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/Sched.HC:3845`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/Sched.HC:4071`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/Sched.HC:4296`

Targeted source search outside TempleOS automation found no Q4_0/Q8_0, `row_stride_blocks`, `out_row_stride`, or matmul error-surface vocabulary in TempleOS source. The only non-automation GGUF reference found was a modernization task line for parser hardening:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:262`

### holyc-inference Surface

holyc-inference defines concrete Q4_0 and Q8_0 matmul contracts:
- Q4_0 layout: lhs rows are row-major blocks, rhs columns are pre-transposed column-bank rows, each logical dot uses `k_block_count`, output is row-major Q32 `I64` with explicit output row stride.
- Q4_0 error surface: `OK=0`, `ERR_NULL_PTR=1`, `ERR_BAD_LEN=2`, `ERR_OVERFLOW=3`.
- Q4_0 checked core validates non-negative capacities/dimensions/strides, `k_block_count <= {lhs,rhs}_stride`, `out_row_stride_cols >= rhs_cols`, capacity products, and row/column/output index overflow.

Relevant source:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/matmul/q4_0_matmul.HC:4`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/matmul/q4_0_matmul.HC:10`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/matmul/q4_0_matmul.HC:81`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/matmul/q4_0_matmul.HC:118`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/matmul/q4_0_matmul.HC:129`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/matmul/q4_0_matmul.HC:139`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/matmul/q4_0_matmul.HC:170`

Q8_0 is similarly concrete:
- Runtime contract: lhs `MxK` row-major Q8_0 blocks, rhs `NxK` row-major column-bank blocks, output `MxN` Q16 `I64` lanes with explicit output row stride.
- Error surface: `OK=0`, `ERR_NULL_PTR=1`, `ERR_BAD_DST_LEN=2`, `ERR_OVERFLOW=3`.
- It has shared checked helpers for tile shape, tile span bounds, no-partial tile scheduling, stride/K validation, required capacities, row-base calculation, and full argument validation.

Relevant source:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/matmul/q8_0_matmul.HC:4`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/matmul/q8_0_matmul.HC:14`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/matmul/q8_0_matmul.HC:76`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/matmul/q8_0_matmul.HC:104`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/matmul/q8_0_matmul.HC:116`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/matmul/q8_0_matmul.HC:163`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/matmul/q8_0_matmul.HC:683`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/matmul/q8_0_matmul.HC:712`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/matmul/q8_0_matmul.HC:745`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/matmul/q8_0_matmul.HC:876`

## Findings

1. WARNING - "matrix-shape" means different things in each repo.
   - TempleOS matrix-shape status is threshold/sweep telemetry; holyc-inference matrix shape is `{rows, cols, k_block_count, row strides, column-bank strides, capacities, output stride}`.
   - Risk: a future bridge could falsely treat TempleOS matrix-shape `deterministic_ok=1` as proof that inference matmul geometry is valid.

2. WARNING - No shared error-surface mapping exists.
   - holyc-inference distinguishes `NULL_PTR`, `BAD_LEN`/`BAD_DST_LEN`, and `OVERFLOW`.
   - TempleOS matrix-shape telemetry emits clamp/parity/digest fields but no `bad_len`, `overflow`, `null_ptr`, or capacity-proof status.
   - Risk: host or guest audit dashboards cannot faithfully explain why an inference matmul contract would fail.

3. WARNING - Capacity and overflow proofs are absent from TempleOS matrix-shape telemetry.
   - holyc-inference explicitly checks `rows * row_stride`, `cols * col_stride`, `rows * out_stride`, row-base products, and index sums.
   - TempleOS matrix-shape counts only `sweeps*sweeps`, diagonal/off-diagonal cells, threshold uniqueness, and transition parity.
   - Risk: large-shape or hostile-shape failures can be invisible at the TempleOS telemetry layer.

4. INFO - No direct Law 1, Law 2, or Law 4 violation found in this read-only audit.
   - TempleOS source spot-check did not add networking or non-HolyC core implementation for this contract.
   - holyc-inference matmul code remains HolyC and integer-status oriented in the audited files.

5. WARNING - Naming drift makes the contract harder to police.
   - TempleOS matrix-shape function and script names are deeply compounded.
   - holyc-inference also has long, stacked helper names around no-partial/preflight/parity wrappers.
   - Risk: the same Law 4 identifier-compounding pressure that previous audits found is now obscuring whether two similarly named "shape" contracts are actually equivalent.

## Recommended Backlog Items

- Add a small cross-repo contract document, e.g. `docs/contracts/matmul-shape.md`, owned by Sanhedrin or both repos, defining canonical fields: quant type, rows, cols, `k_block_count`, lhs/rhs block capacities, lhs/rhs strides, output stride, output format Q16/Q32, and status codes.
- If TempleOS must emit inference-shape readiness, add separate field names such as `matmul_rows`, `matmul_cols`, `matmul_k_blocks`, `matmul_lhs_stride`, `matmul_rhs_stride`, `matmul_out_stride`, `matmul_status`.
- Do not reuse the existing threshold/sweep "matrix-shape" vocabulary as a proxy for inference tensor validity.

## LAWS.md Assessment

- Law 1 HolyC Purity: no violation found in audited core source surfaces.
- Law 2 Air-Gap Sanctity: no networking action performed; no VM/QEMU run performed.
- Law 4 Identifier Compounding Ban: drift pressure remains relevant, but this report is a cross-repo contract audit, not a fresh enforcement pass.
- Law 5 North Star Discipline: warning applies because telemetry that looks like inference shape readiness but cannot validate inference geometry risks busywork-style progress.

Finding count: 5
