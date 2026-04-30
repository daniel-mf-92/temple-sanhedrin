# Cross-Repo Audit: Profile Policy Authority Drift

Timestamp: 2026-04-30T22:48:29+02:00

Audit angle: cross-repo invariant check for whether holyc-inference profile and GPU policy decisions are joinable to the TempleOS Book-of-Truth profile/policy authority.

Repos reviewed:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `636487f31f5867135112f2f6b7fc3df8b2924a69` on `codex/modernization-loop`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554bea44c132137c590f02034c8f726` on `main`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit`

No TempleOS or holyc-inference source file was modified. No QEMU, VM, WS8 networking, package-download, or data-modifying command was executed.

## Expected Cross-Repo Invariant

TempleOS is the trust/control plane for security profile state, model promotion, and Book-of-Truth authority. Any holyc-inference decision that depends on `secure-local`, `dev-local`, policy digest parity, or Book-of-Truth GPU hooks must be traceable to a TempleOS-local profile/policy event tuple, not only to same-valued local constants.

Finding count: 5 findings: 5 warnings.

## Findings

### WARNING-001: Profile IDs match by convention, not by shared attested contract

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity
- Law 11: Book of Truth Local Access Only

Evidence:
- TempleOS defines `BOT_PROFILE_SECURE_LOCAL=1` and `BOT_PROFILE_DEV_LOCAL=2`, then emits `BOT_PROFILE_PAYLOAD_MARKER` profile events from `BookTruthProfileSet` and `BookTruthProfileBoot` (`Kernel/BookOfTruth.HC:105-106`, `12848-12868`, `12885-12893`).
- holyc-inference independently defines the same numeric profile IDs in multiple domains: GPU policy (`src/gpu/policy.HC:22-23`), runtime profile (`src/runtime/profile.HC:10-11`), prefix cache (`src/runtime/prefix_cache.HC:18-19`), key release (`src/runtime/key_release_gate.HC:17-18`), policy digest (`src/runtime/policy_digest.HC:14-15`), quant profile (`src/runtime/quant_profile.HC:16-17`), batch scheduler (`src/runtime/batch_scheduler.HC:15-16`), and reset scrub (`src/gpu/reset_scrub.HC:19-20`).

Assessment:
The current numeric agreement is useful but informal. A profile-sensitive inference report can say `profile_id=1` without proving it came from the TempleOS Book-of-Truth profile event that owns the trust-plane state.

Required remediation:
- Define a shared `PROFILE_AUTH_V1` tuple: `profile_id`, `profile_name`, TempleOS `bot_seq`, `BOT_PROFILE_PAYLOAD_MARKER`, payload, entry hash, and local-only proof status.
- Treat unjoined inference profile IDs as runtime-local claims, not trust-plane proof.

### WARNING-002: holyc-inference GPU dispatch can accept `dev-local` while TempleOS GPU stage remains open work

Applicable laws:
- Law 2: Air-Gap Sanctity
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- holyc-inference `GPUPolicyAllowDispatchChecked` accepts both `GPU_POLICY_PROFILE_SECURE_LOCAL` and `GPU_POLICY_PROFILE_DEV_LOCAL` before checking IOMMU and Book-of-Truth hook booleans (`src/gpu/policy.HC:64-90`).
- The test harness confirms a `dev-local` profile is considered valid and then blocked or allowed only by IOMMU/Book hook flags (`tests/test_gpu_policy_allow_dispatch_checked.py:95-107`).
- TempleOS policy says GPU paths are disabled unless IOMMU enforcement and Book-of-Truth GPU logging hooks are active, while WS14 GPU stage transitions, IOMMU domain manager, BAR/MMIO allowlist, DMA lease model, dispatch transcript, fail-closed boot gate, and secure-on acceptance matrix remain open (`MODERNIZATION/AGENT_HOLYC_MODERN_OS_GUIDE.md:17-20`; `MODERNIZATION/MASTER_TASKS.md:267-279`).

Assessment:
Inference-side `dev-local` GPU dispatch has a boolean readiness shape, but TempleOS has not yet materialized the boot-visible GPU stage machine that would make those booleans authoritative. The safe interpretation is preflight-only until TempleOS owns and logs the stage transition.

Required remediation:
- Gate holyc-inference GPU dispatch on a TempleOS `gpu_stage` attestation once WS14-09 or equivalent exists.
- Until then, report `dev-local` GPU dispatch readiness as blocked/preflight when the TempleOS stage tuple is absent.

### WARNING-003: TempleOS policy payload does not encode GPU hook or IOMMU readiness bits

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- TempleOS `BookTruthPolicyCheck` currently tracks secure-local violations for W^X halt, tamper halt, serial mirror, I/O logging, disk logging, and W^X mode (`Kernel/BookOfTruth.HC:107-112`, `12907-12929`).
- Its emitted policy payload carries `profile`, `viol_pre`, `viol_post`, `fixes`, `enforce`, `mode_secure`, and `source` fields, but no IOMMU, GPU hook, MMIO, DMA lease, dispatch transcript, or policy-digest parity field (`Kernel/BookOfTruth.HC:12932-12939`).
- holyc-inference policy and performance gates require `iommu_enabled`, `bot_dma_log_enabled`, `bot_mmio_log_enabled`, `bot_dispatch_log_enabled`, `book_of_truth_gpu_hooks`, and `policy_digest_parity` (`src/gpu/policy.HC:34-40`, `82-90`; `src/gpu/security_perf_matrix.HC:410-459`).

Assessment:
The inference gates ask for proof dimensions the TempleOS profile/policy payload cannot currently provide. That creates a join gap: an inference "policy digest parity" or "Book-of-Truth GPU hooks active" bit cannot be verified against the current TempleOS policy event alone.

Required remediation:
- Extend the TempleOS policy event schema or add a separate GPU policy event with IOMMU, DMA, MMIO, dispatch, and digest-parity bits.
- Require inference evidence to cite that TempleOS tuple before claiming secure-local GPU readiness.

### WARNING-004: Model promotion has TempleOS Book-of-Truth fail evidence; GPU/throughput gate failures do not

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 5: North Star Discipline
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- TempleOS model promotion emits `BOT_EVENT_VERIFY_FAIL` when secure-local gates fail for deterministic eval or build evidence (`Kernel/BookOfTruth.HC:13395-13418`).
- holyc-inference GPU and throughput gates return local reason codes such as `GPU_POLICY_REASON_BOOK_HOOKS_MISS`, `GPU_SEC_PERF_ROW_GATE_REASON_BOOK_GUARD`, and `GPU_SEC_PERF_FAST_PATH_DISABLE_REASON_POLICY_DIGEST_MISMATCH` (`src/gpu/policy.HC:17-20`, `82-90`; `src/gpu/security_perf_matrix.HC:21-37`, `453-459`, `491-509`).

Assessment:
TempleOS has a durable fail tuple for model promotion, but the analogous GPU/throughput denials remain inference-local reason codes. This weakens historical auditability because a failed or skipped GPU fast path cannot be replayed from the Book-of-Truth ledger the same way a secure-local promotion failure can.

Required remediation:
- Define a TempleOS `BOT_MODEL_GPU_GATE_FAIL` or `BOT_POLICY_GPU_FAIL` payload marker covering IOMMU, Book hooks, digest parity, transcript mismatch, and overhead-budget breach.
- Require inference to include the matching TempleOS fail tuple when reporting denied GPU/throughput work as policy evidence.

### WARNING-005: Multiple inference subsystems duplicate profile constants and drift independently

Applicable laws:
- Law 5: No Busywork / North Star Discipline
- Law 6: Queue Health

Evidence:
- holyc-inference repeats profile constants in GPU policy, prefix cache, key-release gate, policy digest, quant profile, batch scheduler, reset scrub, and host test harnesses (`src/gpu/policy.HC:22-23`; `src/runtime/prefix_cache.HC:18-19`; `src/runtime/key_release_gate.HC:17-18`; `src/runtime/policy_digest.HC:14-15`; `src/runtime/quant_profile.HC:16-17`; `src/runtime/batch_scheduler.HC:15-16`; `src/gpu/reset_scrub.HC:19-20`; `tests/test_gpu_policy_allow_dispatch_checked.py:20-21`; `tests/test_runtime_prefix_cache_replay_guard_nopartial_commit_only_preflight_only_parity_commit_only_preflight_only_parity.py:13-14`).
- TempleOS already centralizes trust-plane profile naming and defaulting through `BookTruthProfileName`, `BookTruthProfileSet`, and `BookTruthProfileStatus` (`Kernel/BookOfTruth.HC:12837-12882`).

Assessment:
This is not a current Law 1 or Law 2 violation. It is a drift risk: a future subsystem can change semantics around `dev-local` or `secure-local` without creating a TempleOS-visible policy event, and Sanhedrin would need to rediscover every duplicate constant surface.

Required remediation:
- Add one inference-side profile header/module as the only local source for profile IDs, then require all profile-sensitive modules to import or reference it.
- Add a Sanhedrin parity check that compares inference profile constants to TempleOS `BOT_PROFILE_*` definitions and fails if any duplicated domain diverges.

## Non-Findings

- No guest networking, QEMU, VM, WS8 networking task, or remote package flow was executed during this audit.
- No non-HolyC implementation language was found in the reviewed inference runtime files; Python evidence was limited to host-side test harnesses.
- The matching numeric IDs `1=secure-local` and `2=dev-local` are currently consistent across reviewed TempleOS and holyc-inference files.

## Suggested Sanhedrin Follow-Up

Add a cross-repo evidence rule: any inference result that depends on profile, policy digest, GPU hooks, IOMMU, or fast-path security must include either a TempleOS Book-of-Truth tuple (`bot_seq`, event type, source, payload marker, payload, entry hash) or must be explicitly labeled `preflight-only`.

## Evidence Commands

- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD`
- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD`
- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS branch --show-current`
- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference branch --show-current`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '100,115p;12835,12945p;13380,13420p;13680,13700p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/policy.HC | sed -n '1,180p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/security_perf_matrix.HC | sed -n '1,260p;400,520p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_gpu_policy_allow_dispatch_checked.py | sed -n '1,160p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_runtime_prefix_cache_replay_guard_nopartial_commit_only_preflight_only_parity_commit_only_preflight_only_parity.py | sed -n '1,120p'`
- `rg -n "BOT_PROFILE|BOT_POLICY|BookTruthProfile|BookTruthPolicy|secure-local|dev-local|IOMMU|GPU|Book.*Truth" /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/AGENT_HOLYC_MODERN_OS_GUIDE.md`
- `rg -n "InferenceProfileStatusChecked|PROFILE_SECURE_LOCAL|PROFILE_DEV_LOCAL|book_of_truth_gpu_hooks|policy_digest_parity" /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_gpu_policy_allow_dispatch_checked.py /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_runtime_prefix_cache_replay_guard_nopartial_commit_only_preflight_only_parity_commit_only_preflight_only_parity.py`
