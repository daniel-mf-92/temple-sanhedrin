# Cross-Repo Audit: GPU Secure Throughput Acceptance Drift

Timestamp: 2026-05-01T21:51:58+02:00

Audit owner: gpt-5.5 sibling, retroactive / historical scope only.

Repos examined:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `9f3abbf263982bf9344f8973a52f845f1f48d109`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554bea44c132137c590f02034c8f726`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at pre-commit `27d63fc4147a8c48c17933093c7c4a0331d16fd0`

Audit angle: cross-repo invariant check for secure-local GPU throughput acceptance. TempleOS and holyc-inference were read-only. No QEMU or VM command was executed. No WS8 networking task, socket, NIC, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, package download, live liveness watcher, or current-iteration compliance loop was executed.

## Expected Invariant

Secure-local GPU performance can count only when TempleOS, as trust/control plane, proves the GPU stage, IOMMU state, Book-of-Truth hooks, dispatch transcript parity, policy digest parity, and overhead budgets. holyc-inference may compute worker-plane throughput and budget gates, but those results must not become release or promotion evidence without a TempleOS-origin proof tuple and a fail-closed release blocker.

Finding count: 5 warnings, 0 critical violations.

## Findings

### WARNING-001: Worker fast-path gate can pass from caller-supplied booleans

Applicable laws:
- Law 5: North Star Discipline
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- holyc-inference `GPUSecurityPerfFastPathSwitchCheckedAuditParity(...)` accepts raw `secure_local_mode`, `iommu_active`, `book_of_truth_gpu_hooks`, `policy_digest_parity`, and `dispatch_transcript_parity` inputs, then enables the fast path when each boolean is true at `src/gpu/security_perf_matrix.HC:470-523`.
- TempleOS doctrine says TempleOS in `secure-local` remains the trust/control plane, while the inference runtime is an untrusted worker plane at `MODERNIZATION/MASTER_TASKS.md:41-47`.
- TempleOS still has the control-plane contract, attestation verifier, policy-digest handshake, and key-release gate open at `MODERNIZATION/MASTER_TASKS.md:275-278`.

Assessment:
The worker-side function has useful fail-closed boolean semantics, but the booleans are not bound to TempleOS proof. A caller can satisfy the API contract with `1,1,1,1` even though the TempleOS-side authority for those facts is not implemented yet.

Required remediation:
- Replace raw worker evidence booleans with a TempleOS-generated tuple such as `{profile_id, gpu_stage, iommu_seq_hash, bot_dma_seq_hash, bot_mmio_seq_hash, dispatch_transcript_seq_hash, policy_digest}`.
- Keep worker fast-path output labeled as local simulation until TempleOS validates that tuple.

### WARNING-002: Overhead budget gate has no TempleOS-owned budget source

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- holyc-inference `GPUSecurityPerfFastPathSwitchSecureLocalOverheadBudgetCrossGateChecked(...)` rejects if `p50_overhead_q16` or `p95_overhead_q16` exceeds caller-supplied max thresholds at `src/gpu/security_perf_matrix.HC:526-604`.
- TempleOS lists GPU performance guardrails and secure-on performance acceptance matrix as open items at `MODERNIZATION/MASTER_TASKS.md:273` and `MODERNIZATION/MASTER_TASKS.md:279`.
- TempleOS policy says performance wins only count when measured with IOMMU, Book-of-Truth, and policy gates enabled at `MODERNIZATION/MASTER_TASKS.md:47`.

Assessment:
holyc-inference can compare overhead numbers against budgets, but the current TempleOS source does not define the canonical secure-local overhead budget or CPU baseline. This creates a false acceptance risk: worker-local thresholds can be mistaken for TempleOS release criteria.

Required remediation:
- Define TempleOS-owned secure-local budget constants and the baseline measurement identity.
- Include the TempleOS budget version/hash in holyc-inference gate inputs and snapshot digests.

### WARNING-003: Snapshot digest omits TempleOS ledger sequence and benchmark provenance

Applicable laws:
- Law 5: North Star Discipline
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- holyc-inference `GPUSecurityPerfFastPathSwitchSecureLocalOverheadBudgetCrossGateSnapshotDigestQ64Checked(...)` hashes nine local tuple values: profile, IOMMU flag, Book-of-Truth hook flag, policy parity flag, transcript parity flag, p50, p95, max p50, and max p95 at `src/gpu/security_perf_matrix.HC:607-760`.
- The digest tuple does not include TempleOS commit, boot profile transition sequence/hash, IOMMU/MMIO policy digest, Book-of-Truth sequence/hash, benchmark fixture identity, model identity, CPU baseline identity, or air-gap evidence.
- TempleOS requires trusted-load or key-release flows to use attestation evidence plus policy digest match at `MODERNIZATION/MASTER_TASKS.md:45-46`.

Assessment:
The worker snapshot digest detects mutation inside one local tuple, but it is not a release-grade proof. It cannot establish which TempleOS boot, ledger, model, or baseline produced the measurements.

Required remediation:
- Extend the accepted proof tuple with TempleOS head, Book-of-Truth sequence/hash range, model manifest hash, benchmark fixture id, CPU baseline id, and air-gap/QEMU evidence id when live validation is used.
- Treat local snapshot digests as subproofs, not final acceptance artifacts.

### WARNING-004: Runtime policy digest defaults external GPU guard bits to enabled

Applicable laws:
- Law 5: North Star Discipline
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- holyc-inference `policy_digest.HC` initializes `g_policy_iommu_enabled`, `g_policy_bot_dma_log_enabled`, `g_policy_bot_mmio_log_enabled`, and `g_policy_bot_dispatch_log_enabled` to `1` at `src/runtime/policy_digest.HC:27-33`.
- `InferencePolicyDigestChecked(...)` then mixes these caller/runtime guard bits into policy bits and digest state at `src/runtime/policy_digest.HC:135-170`.
- TempleOS still has policy-digest handshake validation before trusted dispatch open at `MODERNIZATION/MASTER_TASKS.md:277`.

Assessment:
Default-on worker guard bits are convenient for local tests, but they invert the trust default for externally evidenced facts. Until TempleOS signs or logs those facts, the worker digest can represent hoped-for GPU guard state rather than observed control-plane state.

Required remediation:
- Default externally evidenced GPU bits to `0` unless a TempleOS proof tuple verifies.
- Add a separate `dev-local fixture` mode for tests that need synthetic all-enabled guard bits.

### WARNING-005: Release blocker policy exists in TempleOS tasks but has no cross-repo executable join

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- TempleOS explicitly requires a release blocker when security gates pass but throughput floor fails, or vice versa, at `MODERNIZATION/MASTER_TASKS.md:280`.
- TempleOS has fail-closed boot gate and secure-on performance acceptance matrix still open at `MODERNIZATION/MASTER_TASKS.md:274` and `MODERNIZATION/MASTER_TASKS.md:279`.
- holyc-inference has extensive secure-local budget gate helpers and commit-only/preflight-only parity wrappers, including the repeated hardening chain around `src/gpu/security_perf_matrix.HC:775-930` and `src/gpu/security_perf_matrix.HC:1890-1960`, but those helpers are not joined to a TempleOS release-blocker artifact.

Assessment:
The worker has outpaced the control-plane acceptance path. That is not a direct Law violation while GPU remains gated, but it leaves secure-local throughput reports easy to overinterpret because no executable Trinity join says "security evidence and throughput evidence both passed for the same run."

Required remediation:
- Add a Sanhedrin or TempleOS-owned acceptance artifact schema: `{security_gate_result, throughput_gate_result, same_run_id, bot_seq_hash, policy_digest, model_id, baseline_id, release_blocker_status}`.
- Require holyc-inference throughput gates to emit only worker evidence until this join exists.

## Non-Findings

- No networking source, QEMU/VM command, or WS8 execution was used during this audit.
- No source modification was made in TempleOS or holyc-inference.
- The audited holyc-inference gate functions are integer-only and fail closed on bad boolean domains or over-budget local measurements.
- TempleOS current task state still marks the missing GPU release-blocker pieces as open, so this audit found drift risk rather than a completed-policy contradiction.

## Read-Only Verification Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
git rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '31,55p;259,282p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/security_perf_matrix.HC | sed -n '408,590p;590,606p;607,760p;775,930p;1880,1960p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/policy_digest.HC | sed -n '1,210p'
```
