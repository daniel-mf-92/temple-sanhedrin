# Cross-Repo Audit: Prefix/KV Cache Reuse Trust Drift

Audit timestamp: 2026-04-30T23:05:29+02:00

Audit angle: cross-repo invariant check for whether TempleOS control-plane commitments cover holyc-inference prefix/KV cache reuse assumptions.

Repos reviewed:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `636487f31f5867135112f2f6b7fc3df8b2924a69`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554bea44c132137c590f02034c8f726`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at `e2152c346e523fd8546cd03fadc82859278fb51d`

No TempleOS or holyc-inference source file was modified. No QEMU, VM, WS8 networking, networking, package-download, or live liveness command was executed.

## Expected Cross-Repo Invariant

Prefix/KV cache reuse is throughput-plane state, but in `secure-local` it affects which hidden activations are reused for a model, prompt, and session. TempleOS owns the trust/control plane, so cache reuse in a trusted run needs a joined proof that binds worker cache state to TempleOS policy, model quarantine, attestation, and Book-of-Truth evidence.

Finding count: 5 warnings.

## Findings

### WARNING-001: Prefix reuse state has no TempleOS event vocabulary

Applicable laws: Law 3, Law 5, Law 8.

Evidence:
- holyc-inference `PrefixCacheEntry` stores `prefix_hash`, `prefix_tokens`, `kv_start_token`, `kv_token_count`, and `last_used_tick` in `src/runtime/prefix_cache.HC:30-38`.
- The same module describes each entry as binding a prompt-token prefix hash to a KV cache window snapshot at `src/runtime/prefix_cache.HC:4-5`.
- TempleOS says the high-throughput inference runtime is an untrusted worker plane and trust decisions remain in TempleOS at `MODERNIZATION/MASTER_TASKS.md:41-46`.
- TempleOS completed Book-of-Truth events for profile changes/model promotions/gate failures, but the WS14 ledger has no explicit prefix-cache or KV-reuse event class at `MODERNIZATION/MASTER_TASKS.md:258-280`.

Assessment:
The worker has a cache identity tuple, but TempleOS has no canonical event vocabulary for `prefix_cache_hit`, `kv_window_reuse`, `cache_evict`, or `cache_reject`. A trusted run could reuse hidden state while the control-plane ledger only proves profile/model gates, not the specific reuse decision.

Required remediation:
- Define a TempleOS Book-of-Truth cache-reuse event tuple such as `{model_id, tokenizer_hash, policy_digest, prefix_hash, prefix_tokens, kv_start, kv_count, decision}`.
- Treat worker-only prefix-cache telemetry as advisory until it is joined to that ledger tuple.

### WARNING-002: Replay guard is local to worker tick/profile state

Applicable laws: Law 5, Law 8.

Evidence:
- holyc-inference documents that caller code is responsible for profile gates and attestation before enabling prefix reuse at `src/runtime/prefix_cache.HC:7-9`.
- `PrefixCacheReplayGuardChecked(...)` accepts `entry_index`, `access_tick`, and `profile_id`, and rejects secure-local rollback only when `access_tick < previous_tick` at `src/runtime/prefix_cache.HC:228-285`.
- `PrefixCacheReplayGuardCheckedNoPartialCommitOnly(...)` snapshots `entry_index`, `access_tick`, `profile_id`, capacity, and count, but not model ID, tokenizer hash, policy digest, attestation nonce, or Book-of-Truth sequence at `src/runtime/prefix_cache.HC:288-360`.
- TempleOS still lists control-plane/worker contract, attestation verifier, policy-digest handshake, and key-release gate as open WS14-17 through WS14-20 tasks at `MODERNIZATION/MASTER_TASKS.md:275-278`.

Assessment:
The replay guard is a useful data-path invariant, but it does not prove that a prefix hit belongs to the same trusted model, tokenizer, prompt policy, or attested worker session. In secure-local terms, monotonic local ticks are not a substitute for a TempleOS-owned reuse authorization.

Required remediation:
- Extend cache reuse authorization to require a TempleOS-approved session tuple before a secure-local hit can be consumed.
- Make Sanhedrin flag secure-local cache-hit evidence that lacks model/tokenizer/policy/attestation join fields.

### WARNING-003: KV persistence has geometry but not trust metadata

Applicable laws: Law 3, Law 5, Law 8.

Evidence:
- holyc-inference `kv_cache.HC` defines a fixed persistence header with magic, version, layer count, token capacity, KV heads, head dimension, used tokens, and total cells at `src/model/kv_cache.HC:17-27`.
- The header layout comments enumerate those eight I64 cells at `src/model/kv_cache.HC:172-180`.
- TempleOS requires model quarantine/hash verification and trusted model manifest fields in WS14-02 and WS14-03 at `MODERNIZATION/MASTER_TASKS.md:260-261`.
- holyc-inference says model files must pass quarantine and hash-manifest verification before trusted load at `MASTER_TASKS.md:26-29`.

Assessment:
The KV header is good for shape safety, but it does not bind a persisted cache to model identity, tokenizer identity, prompt template, policy digest, or session attestation. A shape-compatible stale cache could look structurally valid while being semantically wrong for the secure-local run.

Required remediation:
- Add a trust sidecar or header extension for persisted KV state that records model ID/hash, tokenizer hash, profile, policy digest, and session nonce.
- Require TempleOS to approve or reject persisted KV reuse before a secure-local run uses it.

### WARNING-004: Best-prefix and LRU decisions are deterministic but not auditable by the control plane

Applicable laws: Law 5, Law 8.

Evidence:
- `PrefixCacheLookupBestPrefixChecked(...)` chooses the longest matching prefix and uses the lowest slot as a stable tie-break at `src/runtime/prefix_cache.HC:1906-1960`.
- `PrefixCacheSelectVictimIndexLRUChecked(...)` chooses an empty slot or the entry with the oldest `last_used_tick` at `src/runtime/prefix_cache.HC:1962-2001`.
- TempleOS performance wins only count with IOMMU, Book-of-Truth, and policy gates enabled at `MODERNIZATION/MASTER_TASKS.md:47`.
- holyc-inference throughput claims must include `secure-local` measurements with audit hooks enabled at `MASTER_TASKS.md:30`.

Assessment:
The worker decision rules are deterministic, but the selected prefix and eviction victim are not part of the shared evidence contract. Sanhedrin can verify that the algorithms exist, but cannot retroactively prove which cache decision was applied during a secure-local benchmark.

Required remediation:
- Emit cache decision evidence for secure-local runs: selected entry, prefix length, hit/miss, victim, tick, and joined policy digest.
- Include those fields in benchmark evidence used for secure-on throughput claims.

### WARNING-005: Split-plane doctrine is aligned, but cache reuse remains an undefined boundary

Applicable laws: Law 5, Law 7.

Evidence:
- TempleOS guide says `secure-local` must keep Book of Truth always-on and that high-throughput workers remain untrusted until attestation and policy-digest checks pass at `MODERNIZATION/AGENT_HOLYC_MODERN_OS_GUIDE.md:17-22`.
- holyc-inference mirrors the split-plane trust model and says trust decisions remain in TempleOS via attestation and policy-digest handshake at `MASTER_TASKS.md:23-30`.
- holyc-inference WS16 still has open tasks for policy snapshot, policy digest, attestation bundle, and key-release handshake at `MASTER_TASKS.md:207-220`.
- TempleOS WS14 still has open tasks for control-plane/worker contract, attestation verifier, policy-digest validation, and key-release gate at `MODERNIZATION/MASTER_TASKS.md:275-278`.

Assessment:
Both repos agree on split-plane authority, which is healthy. The gap is that prefix/KV reuse is now concrete enough to affect secure-local outputs, but it is not named in either side's open trust-boundary tasks. That makes it easy for future work to harden model/load gates while leaving cache reuse outside the proof envelope.

Required remediation:
- Add cache reuse explicitly to the WS14/WS16 control-plane contract language.
- Track cache-reuse proof absence as a release-blocking ambiguity for secure-local benchmark promotion, not as a runtime source-code violation.

## Non-Findings

- No HolyC purity violation was found in the reviewed cache surfaces.
- No air-gap violation was found; this audit did not run QEMU or any VM command.
- The reviewed cache logic is deterministic and host/network independent.

## Evidence Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/prefix_cache.HC | sed -n '1,120p;220,360p;1880,2035p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/kv_cache.HC | sed -n '1,180p;740,900p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '31,58p;258,281p;2228,2242p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/AGENT_HOLYC_MODERN_OS_GUIDE.md | sed -n '14,24p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md | sed -n '23,34p;188,225p'
```
