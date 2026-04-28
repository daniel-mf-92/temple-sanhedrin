# Cross-Repo Audit: Resource Pressure and Inference Memory Drift

Timestamp: 2026-04-28T13:16:47+02:00

Scope: cross-repo invariant check across read-only TempleOS and holyc-inference worktrees.

Repos inspected:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`
- Sanhedrin audit branch: `codex/sanhedrin-gpt55-audit`

Audit angle: whether TempleOS' Book-of-Truth resource-supremacy commitments are strong enough to govern holyc-inference memory growth surfaces: model weights, KV cache, prefix cache, staged matmul buffers, GPU partitions, and persistent cache data.

## Summary

TempleOS and holyc-inference agree on the high-level intent: local-only inference, default `secure-local`, Book-of-Truth evidence, and fail-closed security gates. The drift is at the memory-pressure boundary. TempleOS' laws and workstreams say the Book of Truth outranks process memory, file cache, user files, and swap, but the current runtime integration surface does not yet define how inference allocations, caches, model blobs, GPU partitions, and persistent KV files are classified or reclaimed when ledger pressure rises.

Finding count: 5 warnings, 0 critical findings.

## Findings

### WARNING-001: Ledger-pressure APIs are declared and scheduled, but current source lookup did not find their definitions

Relevant laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy and Hardware Proximity
- Law 9: Resource Supremacy / Crash on Log Failure

Evidence:
- TempleOS declares `BookTruthPressureSet`, `BookTruthPressureStatus`, `BookTruthPressureEscalationStatus`, and `BookTruthPressureTick` externs in `Kernel/KExts.HC:90-93` and `Kernel/KExts.HC:933`.
- `TaskBookTruthPressureTick` calls `BookTruthPressureTick(now)` and is wired into `TaskKillDying` in `Kernel/KTask.HC:815-831` and `Kernel/KTask.HC:865-872`.
- `Kernel/BookOfTruth.HC` still defines `BOT_EVENT_LEDGER_PRESSURE` and pressure-related globals at `Kernel/BookOfTruth.HC:20` and `Kernel/BookOfTruth.HC:200-213`.
- A repo-wide source search found declarations, task calls, smoke fixtures, and task-history claims, but no current implementation of `BookTruthPressureTick`, `BookTruthPressureSet`, or `BookTruthPressureStatus`.

Impact:

This creates an auditability gap before inference memory pressure is even considered. The repo history says CQ-125/CQ-221 added ledger-pressure runtime commands, but the current source surface visible to this audit does not contain the matching definitions. If this is not generated elsewhere, the pressure watchdog may be stale or uncompilable, weakening Law 9 evidence.

Recommended closure:

Restore or locate the pressure API definitions, then add a Sanhedrin-readable source check that declarations, task calls, and implementations are present together. Treat missing implementation evidence as a release blocker for any memory-heavy inference integration.

### WARNING-002: Inference cache classes are not mapped to TempleOS resource priority order

Relevant laws:
- Law 9: Resource Supremacy / Crash on Log Failure
- Law 10: Immutable OS Image

Evidence:
- TempleOS' WS13 doctrine says memory reclamation priority is `Book of Truth > kernel core > process memory > file cache > user files > swap`, with unsealed log pages never reclaimed: `MODERNIZATION/MASTER_TASKS.md:187-205`.
- TempleOS also says user data, Book-of-Truth logs, and LLM models live on a separate writable partition from the immutable OS image: `MODERNIZATION/MASTER_TASKS.md:206-219`.
- holyc-inference defines KV cache layout as preallocated for `max_context`, O(1) append, bounds checked, deterministic, and without hidden indirection: `docs/LLAMA_ARCH.md:104-115`.
- holyc-inference has persistent KV cache header support with `token_capacity`, `used_tokens`, and `total_cells_per_cache` fields in `src/model/kv_cache.HC:14-27` and `src/model/kv_cache.HC:172-188`.
- holyc-inference prefix cache explicitly says the caller owns profile gates and attestation before reuse: `src/runtime/prefix_cache.HC:4-9`.

Impact:

KV caches, prefix caches, persistent cache files, loaded weights, and GPU partitions can all consume memory or writable-disk budget, but the repos do not classify them in the TempleOS resource-priority hierarchy. Under ledger pressure, a future implementation could preserve inference caches while the Book of Truth needs memory or disk, contradicting Law 9 without an obvious source-level violation.

Recommended closure:

Define an `InferenceMemoryClass` contract shared by both repos: `model_weight_ro`, `model_quarantine`, `kv_cache_live`, `kv_cache_persistent`, `prefix_cache`, `workspace_stage`, `gpu_partition`, and `bot_log`. Assign each class a reclaim order, persistence permission, and Book-of-Truth event tuple.

### WARNING-003: The 256 MB north-star memory budget is not bound to the runtime's capacity formulas

Relevant laws:
- Law 5: North Star Discipline
- Law 9: Resource Supremacy / Crash on Log Failure

Evidence:
- holyc-inference north star requires memory peak below 256 MB: `NORTH_STAR.md:16-20`.
- The forward pass uses caller-provided capacities and computes dense and doubled-dense workspace requirements from `row_count * lane_count`: `src/model/model.HC:114-120` and `src/model/model.HC:188-219`.
- Q4_0 matmul no-partial wrappers allocate private staging buffers sized from required output cells: `src/matmul/q4_0_matmul.HC:459-464`.
- The benchmark README says memory fields such as `memory_bytes` and `max_rss_bytes` are optional, and its documented regression command is host-side: `bench/README.md:61-75`.

Impact:

The memory limit is a north-star property, but it is not yet a loader/runtime admission rule. A trusted model can satisfy local parser checks while its derived tensor/workspace/KV cache footprint exceeds the intended guest budget or forces the ledger into pressure. Optional host benchmark memory fields are not enough to enforce the guest-side Law 9 boundary.

Recommended closure:

Add a pure HolyC preflight estimator that computes `weights_bytes`, `workspace_bytes`, `kv_cache_bytes`, `prefix_cache_bytes`, and `staging_peak_bytes` from GGUF metadata before trusted load. Book-of-Truth should log the estimate and reject or CPU-safe-fallback before allocation if the ledger reserve would be threatened.

### WARNING-004: GPU partition and scrub contracts do not name the Book-of-Truth reserve

Relevant laws:
- Law 8: Book of Truth Immediacy and Hardware Proximity
- Law 9: Resource Supremacy / Crash on Log Failure

Evidence:
- TempleOS WS14 requires bounded DMA leases, GPU reset/scrub, deterministic dispatch transcript capture, and fail-closed CPU fallback: `MODERNIZATION/MASTER_TASKS.md:267-280`.
- holyc-inference WS9 names a GPU memory partition that never overlaps kernel/log pages, bounce buffers, KV-cache residency manager, chunked prefill under memory pressure, and fail-closed runtime gate: `MASTER_TASKS.md:120-165`.
- `GPUResetScrubContext` tracks prerequisites and total scrub bytes, and `GPUResetScrubPlanChecked` computes blocks and bytes from `partition_nbytes`, but the helper does not take a ledger reserve, host memory budget, or TempleOS memory-class input: `src/gpu/reset_scrub.HC:22-39` and `src/gpu/reset_scrub.HC:147-189`.

Impact:

GPU isolation work can prove "the GPU partition is scrubbed" without proving "the partition was sized beneath the Book-of-Truth reserve." This is a cross-repo contract hole: TempleOS owns resource supremacy, while holyc-inference owns throughput surfaces that can dominate memory use.

Recommended closure:

Require every GPU partition plan to include `bot_reserved_bytes`, `kernel_reserved_bytes`, `guest_total_bytes`, and `max_inference_bytes`. A plan should fail closed if `partition_nbytes + live_cpu_buffers + cache_bytes` would encroach on the Book-of-Truth reserve.

### WARNING-005: Persistent KV cache conflicts with local-only and immutable-image policy unless its storage class is explicit

Relevant laws:
- Law 2: Air-Gap Sanctity
- Law 10: Immutable OS Image
- Law 11: Book of Truth Local Access Only

Evidence:
- holyc-inference WS13 includes persistent KV cache save/load to disk: `MASTER_TASKS.md:221-227`.
- `KVCacheQ16PersistHeaderCheckedNoPartial` defines a disk/header grammar for persisted cache geometry: `src/model/kv_cache.HC:172-188`.
- TempleOS says no log export is allowed and the Book of Truth is local-console/host-serial only: `MODERNIZATION/MASTER_TASKS.md:222-233`.
- TempleOS says LLM models live on a separate writable partition, but current policy text does not assign persistent KV cache to a partition, retention class, privacy class, or deletion priority: `MODERNIZATION/MASTER_TASKS.md:213-219`.

Impact:

Persistent KV cache can contain prompt-derived state. Without an explicit storage class and retention policy, it could become a de facto user-data/log-adjacent artifact with unclear deletion priority, unclear audit events, and unclear local-only reading semantics.

Recommended closure:

Classify persistent KV cache as volatile user inference state, never OS-image content and never Book-of-Truth content. Define whether it is disabled in `secure-local`, encrypted behind the key-release gate, or purged before promotion. Log save/load/delete decisions locally in Book of Truth without adding export paths.

## Law Compliance Notes

- No trinity source code was modified.
- No VM or QEMU command was executed.
- Air-gap posture was preserved; no networking work was performed.
- Findings are warning-level cross-repo contract drift and historical/source-surface inconsistencies, not a live liveness audit.

## Evidence Commands

```bash
rg -n "BookTruthPressureTick|BookTruthPressureSet|BookTruthPressureStatus|BookTruthPressureEscalationStatus" -S /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KTask.HC | sed -n '815,872p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '1,80p;180,220p;1680,1735p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '187,280p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/NORTH_STAR.md | sed -n '1,30p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/docs/LLAMA_ARCH.md | sed -n '104,155p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/kv_cache.HC | sed -n '1,260p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/prefix_cache.HC | sed -n '1,240p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/model.HC | sed -n '106,220p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/matmul/q4_0_matmul.HC | sed -n '459,501p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/reset_scrub.HC | sed -n '1,220p'
```
