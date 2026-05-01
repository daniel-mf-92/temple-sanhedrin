# Cross-Repo Audit: GPU Command Lease Proof Contract Drift

Audit timestamp: 2026-05-01T16:55:15+02:00

Audit owner: gpt-5.5 sibling, retroactive / historical scope only.

Repos examined:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `9f3abbf263982bf9344f8973a52f845f1f48d109`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554bea44c132137c590f02034c8f726`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at pre-commit `92943a354dafeb8be46fa921406b9295bdc433e5`

Audit angle: cross-repo invariant check. TempleOS and holyc-inference were read-only. No QEMU or VM command was executed. No WS8 networking task, socket, NIC, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, package download, live liveness watcher, or current-iteration compliance loop was executed.

## Expected Invariant

TempleOS is the secure-local trust/control plane. holyc-inference may own throughput-plane GPU command planning, but a trusted GPU command must be provable through a TempleOS-authoritative tuple: profile stage, DMA lease identity, descriptor verification result, MMIO submission proof, Book-of-Truth sequence/hash, and fail-closed key-release decision. Worker-side command validation, lease tokens, and transcript hashes are not sufficient unless they are bound to TempleOS records.

Finding count: 5 warnings, 0 critical violations.

## Findings

### WARNING-001: Command proof tuple is split between worker transcript fields and TempleOS range logs

Applicable laws:
- Law 5: North Star Discipline
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- holyc-inference transcript rows include descriptor identity fields `{descriptor_addr, descriptor_bytes, descriptor_type, descriptor_op}` plus status and chain hashes in `src/gpu/dispatch_transcript.HC:23-42`.
- holyc-inference `BOTGPUBridgeRecordDispatch(...)` records only `{queue_id, descriptor_addr, descriptor_bytes, fence_id}` for a dispatch event in `src/gpu/book_of_truth_bridge.HC:201-217`.
- TempleOS current GPU kernel surface records DMA windows and MMIO writes through `IOMMUGPUMap`, `IOMMUGPUAllow`, and `IOMMUGPUMMIOWrite` in `Kernel/IOMMU.HC:109-273`, but has no API that binds a descriptor type/op verification result to the DMA/MMIO Book-of-Truth record.
- TempleOS still lists control-plane vs worker-plane command contract and deterministic dispatch transcript capture as open WS14-14 and WS14-17 in `MODERNIZATION/MASTER_TASKS.md:272-275`.

Assessment:
The worker has the command semantics, while TempleOS has the hardware range/MMIO evidence. Those halves are not yet a single proof tuple. A secure-local report could show descriptor/transcript parity while the TempleOS ledger proves only that some range or MMIO write was allowed.

Required remediation:
- Define a canonical command proof tuple `{descriptor_hash, descriptor_type, descriptor_op, lease_id, domain_id, queue_id, fence_id, mmio_seq, bot_seq, bot_hash}`.
- Require both holyc-inference transcript rows and TempleOS Book-of-Truth records to carry or derive the same tuple before secure-local dispatch evidence is accepted.

### WARNING-002: Descriptor verifier is worker-side only; TempleOS can authorize pages without knowing descriptor type/op

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- holyc-inference `GPUCommandDescriptor` defines `desc_type`, `desc_op`, `src_offset_bytes`, `dst_offset_bytes`, `byte_count`, and `flags` in `src/gpu/command_verify.HC:43-51`.
- `GPUCommandVerifyDescriptorChecked(...)` rejects unknown type/op, bad type/op pairs, disallowed flags, bad range, overflow, and 16-byte alignment violations in `src/gpu/command_verify.HC:99-187`.
- `GPUCommandVerifyStreamChecked(...)` enforces a stream budget over all descriptors in `src/gpu/command_verify.HC:189-249`.
- TempleOS `IOMMUGPUAllow(...)` checks only `{dev, base, bytes}` against live mapped domains and emits a DMA record in `Kernel/IOMMU.HC:165-200`.

Assessment:
TempleOS can prove a byte range was within a GPU domain, but not that the command using the range was a QMATMUL/ATTN/ELEMENT descriptor with a valid op, flags, or stream budget. That leaves the command semantics in the untrusted worker plane.

Required remediation:
- Port or mirror the descriptor verifier contract into TempleOS HolyC, or have TempleOS verify a canonical descriptor digest whose schema includes type/op/flags/ranges.
- Gate MMIO submission on a TempleOS-verifiable descriptor result, not only worker-local `GPUCommandVerify*` success.

### WARNING-003: DMA lease-token vocabulary does not match TempleOS IOMMU domain state

Applicable laws:
- Law 5: North Star Discipline
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- holyc-inference leases are explicit capabilities with `{lease_id, lease_token, phys_addr, nbytes, iommu_domain, owner_tag}` in `src/gpu/dma_lease.HC:26-43`.
- `GPUDMALeaseAcquireChecked(...)` rejects overlapping active ranges and publishes a token after preflight in `src/gpu/dma_lease.HC:156-230`.
- `GPUDMALeaseAuthorizeChecked(...)` checks lease token, IOMMU domain, and requested range containment in `src/gpu/dma_lease.HC:265-307`.
- TempleOS IOMMU domains store `{dev, base, pages, exp_jiffy, live}` with no lease id/token/owner tag in `Kernel/IOMMU.HC:6-13`, and `IOMMUGPUMap(...)` records only `dev`, `base`, `pages`, and optional TTL in `Kernel/IOMMU.HC:109-142`.
- TempleOS still lists bounded DMA leases as open WS14-12 in `MODERNIZATION/MASTER_TASKS.md:270`.

Assessment:
The worker can prove a lease-token discipline internally, while TempleOS can prove a page window exists. Those proofs cannot be joined today because the lease identity, token, owner tag, and TempleOS domain identity are different vocabularies.

Required remediation:
- Make TempleOS issue the lease id/token or record the worker-submitted lease tuple in the Book of Truth before any trusted dispatch.
- Include `{lease_id, lease_token_hash, domain_id, owner_tag, base, bytes, expiry}` in both TempleOS DMA records and holyc-inference dispatch proofs.

### WARNING-004: Worker policy gate still accepts raw booleans for dispatch-log availability

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- holyc-inference `GPUPolicyAllowDispatchChecked(...)` accepts `iommu_enabled`, `bot_dma_log_enabled`, `bot_mmio_log_enabled`, and `bot_dispatch_log_enabled` as caller-supplied binary values in `src/gpu/policy.HC:34-40`.
- The same function allows dispatch once all four booleans are true and the profile id is valid in `src/gpu/policy.HC:76-94`.
- holyc-inference policy digest initializes `g_policy_bot_dispatch_log_enabled = 1` and mixes that worker-side bit into the digest in `src/runtime/policy_digest.HC:31-33` and `src/runtime/policy_digest.HC:136-159`.
- TempleOS says secure-local trusted load/key release requires attestation evidence plus policy digest match from the worker plane, and missing/invalid attestation or digest mismatch must fail closed in `MODERNIZATION/MASTER_TASKS.md:41-47`.

Assessment:
Dispatch-log availability is currently an assertion passed into the worker gate, not a TempleOS proof. This is especially risky for command fast-path switches: the worker can reason about descriptor, lease, and transcript parity before TempleOS has a command proof tuple to compare against.

Required remediation:
- Replace raw `bot_dispatch_log_enabled` and parity inputs with a TempleOS proof tuple: `{dispatch_log_seq, dispatch_log_hash, descriptor_hash, lease_id, policy_seq, policy_hash}`.
- Default dispatch-log proof bits to false until the tuple validates against a TempleOS Book-of-Truth record.

### WARNING-005: GPU workstream state can imply secure-local readiness ahead of TempleOS stage gates

Applicable laws:
- Law 5: North Star Discipline
- Law 9: Resource Supremacy / Crash on Log Failure

Evidence:
- TempleOS `secure-local` policy says GPU remains disabled unless IOMMU enforcement and Book-of-Truth GPU logging hooks are active in `MODERNIZATION/MASTER_TASKS.md:33-39`.
- TempleOS has completed WS14-10 and WS14-11 for IOMMU and MMIO scaffolds, but WS14-12 through WS14-20 remain open for leases, reset/scrub, transcript capture, fail-closed boot gate, control/worker contract, attestation verifier, policy digest handshake, and key-release gate in `MODERNIZATION/MASTER_TASKS.md:267-278`.
- holyc-inference marks the corresponding worker-side GPU tasks as code surfaces: command verifier, DMA lease manager, dispatch transcript recorder, policy gates, reset/scrub, and security/perf matrix helpers in `src/gpu/`.
- TempleOS initializes the IOMMU scaffold at boot with `IOMMUGPUInit(TRUE);` in `Kernel/KMain.HC:148`, but the boot-visible GPU stage task WS14-09 remains open in `MODERNIZATION/MASTER_TASKS.md:267-267`.

Assessment:
The repos are building toward the same shape, but secure-local readiness is not yet a shared state machine. Without a boot-visible TempleOS stage, worker command/lease/transcript helpers can be mistaken for release evidence instead of pre-release worker readiness.

Required remediation:
- Publish a TempleOS GPU stage status of `off`, `dev-local guarded`, or `secure-local candidate` and require every worker GPU report to include that stage.
- Treat worker GPU command, lease, and transcript helpers as non-release evidence until WS14-12 through WS14-20 have TempleOS-authoritative proofs.

## Non-Findings

- No HolyC purity violation was found in the reviewed surfaces; TempleOS kernel code and holyc-inference runtime GPU code are `.HC`.
- No air-gap violation was found; no QEMU/VM command was run and no networking path was inspected as executable work.
- holyc-inference descriptor, lease, and transcript helpers are positive worker-plane scaffolds; this audit focuses on command/lease proof ownership, not their local arithmetic or validation discipline.
- TempleOS IOMMU/MMIO work is a useful control-plane foundation, but it is not yet the dispatch proof contract required by secure-local GPU release.

## Read-Only Verification Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
git rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '31,55p;260,285p;4230,4245p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/IOMMU.HC | sed -n '1,330p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/policy.HC | sed -n '1,220p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/command_verify.HC | sed -n '1,270p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/dispatch_transcript.HC | sed -n '1,390p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/dma_lease.HC | sed -n '1,430p'
rg -n "Dispatch|descriptor|transcript|queue|fence|GPU" /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION -S --glob '!**/Kernel.MAP'
```
