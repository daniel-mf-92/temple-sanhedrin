# Cross-Repo Prefix/KV Cache Control-Plane Drift Audit

Timestamp: 2026-04-28T09:03:44+02:00

Audit angle: cross-repo invariant check between TempleOS secure-local trust-plane doctrine and holyc-inference prefix/KV cache reuse state.

Repositories audited:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55` at `274a26c7d7477a5d714a1de261ec501e6c1d3b6f`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55` at `94dc1c3b035c844f42fe6e6a9c4031c7b7fda4be`
- Sanhedrin audit repo: `/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55` at `7501c825b5d0597a125def8943d41892d493aba9`

Safety posture: read-only against TempleOS and holyc-inference. No QEMU/VM command was run. No networking task was executed.

## Scope

This audit checked whether holyc-inference's reusable prefix/KV-cache state carries enough control-plane evidence for TempleOS `secure-local` deployment assumptions.

Primary evidence reviewed:
- TempleOS `MODERNIZATION/MASTER_TASKS.md`
- TempleOS `MODERNIZATION/LOOP_PROMPT.md`
- holyc-inference `src/runtime/prefix_cache.HC`
- holyc-inference `src/model/kv_cache.HC`
- holyc-inference prefix/KV cache host tests

## Findings

### WARNING-1: prefix-cache reuse is intentionally caller-gated, but TempleOS has not defined the trusted cache-admission ABI

TempleOS says `secure-local` is the default, model quarantine/hash verification is mandatory, trusted-load/key-release requires attestation evidence plus policy digest match, and missing evidence must fail closed (`MODERNIZATION/MASTER_TASKS.md:31-47`). TempleOS also states the loop owns profile policy, model trust gates, audit authority, and key-release decisions while inference owns cache strategy (`MODERNIZATION/LOOP_PROMPT.md:36-57`).

holyc-inference's prefix cache explicitly says it is "pure data-path" and that the caller is responsible for profile gates and attestation before reuse (`src/runtime/prefix_cache.HC:1-9`). The replay guard accepts only `profile_id`, `entry_index`, and `access_tick`; it enforces monotonic ticks for `secure-local`, but it does not consume `attestation_ok`, `policy_digest_match`, model quarantine status, or key-release state (`src/runtime/prefix_cache.HC:228-285`).

Impact: the split is philosophically consistent, but the contract is incomplete. A TempleOS caller could treat a prefix-cache hit as an optimization under `secure-local` without a shared ABI proving that the cache entry was admitted under the same attestation, policy digest, model hash, tokenizer hash, and profile state.

Recommended closure: define a cache-admission tuple owned by TempleOS, e.g. `{profile_id, model_id/hash, tokenizer_hash, policy_digest, attestation_digest, quarantine_manifest_seq, bot_seq}`. holyc-inference can stay throughput-plane-only, but should return/cache only entries bound to that tuple.

### WARNING-2: prefix hashes are deterministic but not bound to model/tokenizer provenance

holyc-inference hashes prompt token bytes with a 64-bit FNV-1a domain tag and token-count mix (`src/runtime/prefix_cache.HC:24-28`, `:47-90`). The cache key stores `prefix_hash` and `prefix_tokens`, then maps that tuple to a KV window (`src/runtime/prefix_cache.HC:30-45`, `:164-223`).

TempleOS's trusted model manifest task calls for `model_id`, `sha256`, quant type, tokenizer hash, and provenance (`MODERNIZATION/MASTER_TASKS.md:260-264`). That means identical token IDs are not sufficient cross-repo identity: tokenizer drift, model revision drift, quant profile drift, or prompt-normalization drift can make the same numeric prefix unsafe to reuse.

Impact: this is not a Law 4 integer-purity problem, and the hash is adequate as an internal deterministic key. The drift is that TempleOS's trust plane needs cryptographic/provenance binding while the worker-plane cache exposes a compact runtime hash with no model/tokenizer namespace.

Recommended closure: make prefix-cache lookup take or validate a caller-supplied provenance namespace digest derived from the trusted model manifest. The 64-bit prefix hash can remain a fast local index inside that namespace.

### WARNING-3: KV-cache persistence header carries geometry only, not trust or audit provenance

holyc-inference's KV persistence header stores only `{magic, version, layer_count, token_capacity, kv_heads, head_dim, used_tokens, total_cells}` (`src/model/kv_cache.HC:14-27`, `:172-187`). The write/read helper validates geometry and total-cell consistency, then publishes the tuple (`src/model/kv_cache.HC:188-320`).

TempleOS requires Book-of-Truth events for profile changes, model promotions, and gate failures, and separates OS image, user data, Book-of-Truth logs, and LLM models into explicit storage domains (`MODERNIZATION/MASTER_TASKS.md:206-219`, `:260-278`). It also says any inference/model/GPU task must preserve Book-of-Truth logging and model quarantine/promotion gates (`MODERNIZATION/LOOP_PROMPT.md:36-67`).

Impact: a persisted or restored KV header can prove shape, but cannot prove whether the cache belongs to a trusted model, a promoted manifest entry, a specific tokenizer, or a Book-of-Truth-recorded admission event. That creates a future integration hazard where "valid KV geometry" is mistaken for "trusted reusable KV state."

Recommended closure: either keep KV persistence strictly dev-local and mark it untrusted, or extend the persisted header/sidecar contract with trust-plane fields such as manifest digest, tokenizer digest, profile, policy digest, and Book-of-Truth sequence anchor.

### WARNING-4: cache capacity failures do not expose a resource-priority signal TempleOS can map to Book-of-Truth supremacy

TempleOS Law 9 doctrine says Book of Truth has absolute resource priority and the OS must die before the log dies; memory pressure must reclaim from other subsystems first, and continued execution after log-write failure is forbidden (`MODERNIZATION/MASTER_TASKS.md:187-205`). holyc-inference's KV init helpers validate capacity and return `KV_Q16_ERR_BAD_PARAM` when the K/V slabs are too small (`src/model/kv_cache.HC:728-846`, especially `:808-810`).

Impact: ordinary worker-cache capacity pressure is not a Law 9 violation by itself. The gap is that TempleOS cannot distinguish "worker cache too small; throttle inference" from pressure near Book-of-Truth resource boundaries. In secure-local integration, cache pressure should be low-priority and should never compete with ledger memory.

Recommended closure: add a worker-plane status taxonomy for cache resource pressure, and have the TempleOS caller map it to "drop/rebuild worker cache before touching Book-of-Truth or trusted-control resources."

### WARNING-5: prefix-cache wrapper tests can miss HolyC compile breakage in policy-sensitive paths

`PrefixCacheReplayGuardCheckedNoPartialCommitOnlyPreflightOnlyParity` references `snapshot_entries_ptr` and `snapshot_entry_valid` but does not declare or assign them in that function (`src/runtime/prefix_cache.HC:522-610`). Later wrappers and tests do check for those symbols in other functions, but the host tests are primarily string/behavior harnesses and can assert that these guard fragments exist without proving every HolyC wrapper compiles (`tests/test_runtime_prefix_cache_replay_guard_nopartial_commit_only_preflight_only_parity.py:452+`, related follow-on tests).

Impact: this is not a cross-repo policy violation, but it weakens the release evidence TempleOS would rely on before trusting prefix-cache replay guards. A secure-local cache path that cannot compile, or whose compile gate is not represented in shared evidence, makes cache reuse a fragile integration point.

Recommended closure: add a HolyC source syntax/compile gate specifically for policy-sensitive runtime files (`src/runtime/prefix_cache.HC`, `src/runtime/key_release_gate.HC`, `src/runtime/attestation_manifest.HC`, `src/model/kv_cache.HC`) and surface the result in the cross-repo promotion evidence.

## Summary

Findings: 5 warnings, 0 critical violations.

The audited files remain air-gap-safe and the core runtime code is HolyC-only. The drift is contractual: TempleOS has a strong trust-plane doctrine for model admission, Book-of-Truth evidence, and resource supremacy, while holyc-inference cache reuse currently proves local deterministic data-shape properties but not trusted provenance or control-plane admission.
