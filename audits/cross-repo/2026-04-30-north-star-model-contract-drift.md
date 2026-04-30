# Cross-Repo Audit: North-Star Model Contract Drift

Timestamp: 2026-04-30T19:07:15Z

Scope:
- TempleOS repo: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `928a49f0ab56`
- holyc-inference repo: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554`
- Sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at `cbd7b1a281d7`

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source files were modified.

## Summary

The high-level policy parity gate is green: `holyc-inference/automation/check-trinity-policy-sync.sh` reported `passed=21`, `failed=0`, `drift=false`.

That gate does not cover the north-star execution contract. The current TempleOS and holyc-inference docs/scripts disagree on the first supported model family, model storage surface, and VM disk immutability expectations. These are not live liveness findings; they are historical/deep cross-repo drift findings.

Findings: 5

## Findings

### 1. WARNING: First-model contract split between GPT-2 and LLaMA-family

Evidence:
- `holyc-inference/NORTH_STAR.md:7` says the concrete deliverable is one forward pass of a small GPT-2 model.
- `holyc-inference/NORTH_STAR.md:16-18` fixes the artifact and prompt to GPT-2 124M Q4_0 with token ids `[15496, 11, 995]`.
- `holyc-inference/MASTER_TASKS.md:18-22` says the first model architecture is the LLaMA family, with TinyLlama/Qwen small-model targets.
- `holyc-inference/MASTER_TASKS.md:41-46` defines the north-star outcomes around a LLaMA-family forward pass and TinyLlama benchmark.

Impact: the inference loop can pass or chase one north star while its own master task map and TempleOS integration expectations advance another. This weakens Law 5/North Star Discipline because the e2e target is not the same contract as the workstream target.

Recommended issue: pick one first architecture for the cross-repo north star, or explicitly define GPT-2 as a temporary bootstrapping target with exit criteria into the LLaMA-family target.

### 2. WARNING: Model storage contract split between `shared.img`, host file path, and TempleOS quarantine/trusted-load policy

Evidence:
- `holyc-inference/NORTH_STAR.md:16` says the Q4_0 GPT-2 blob lives on `shared.img`.
- `holyc-inference/automation/north-star-e2e.sh:6` instead reads `models/gpt2-124m-q4_0.bin` from the host repo path.
- `holyc-inference/automation/north-star-e2e.sh:28-35` delegates the guest run to a missing `automation/run-holyc-forward.sh` but does not define how `shared.img` is mounted or quarantined.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:34-39` requires model quarantine/hash verification and forbids any profile from enabling guest networking.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:43-47` makes TempleOS the trust/control plane for quarantine, key-release, attestation, and policy-digest decisions.

Impact: the north-star script can evolve as a host-file benchmark without proving the TempleOS control-plane invariant: untrusted model import, hash-manifest promotion, and trusted load inside the air-gapped guest.

Recommended issue: define a shared-image layout contract: read-only OS image, separate writable model/user image, quarantine directory, trusted manifest path, and exact HolyC command that consumes the trusted model.

### 3. WARNING: Immutable OS image contract is not represented in the QEMU launch interfaces used by both repos

Evidence:
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:206-219` defines the immutable image rule and requires QEMU OS images to use `-drive readonly=on` with a separate writable disk for user data.
- `TempleOS/automation/qemu-headless.sh:84-86` attaches `DISK_IMAGE` as `-drive file=$DISK_IMAGE,format=raw,if=ide` without `readonly=on`.
- `holyc-inference/bench/qemu_prompt_bench.py:146-158` builds a QEMU command with one raw IDE drive, also without `readonly=on` and without a separate writable data/model drive.

Impact: the two repos have converged on an air-gapped VM convention but not on the immutable-OS + writable-data split required by Law 10 and the TempleOS WS13 contract. This can mask unsafe e2e runs once the missing HolyC forward runner is added.

Recommended issue: add a cross-repo QEMU launch contract that distinguishes `OS_IMAGE` with `readonly=on` from `DATA_IMAGE`/`MODEL_IMAGE` with writable semantics.

### 4. INFO: Policy parity gate is green but has a coverage gap for north-star execution shape

Evidence:
- `holyc-inference/automation/check-trinity-policy-sync.sh` passed all 21 configured checks.
- The configured checks cover secure-local default, dev-local guardrails, quarantine/hash, GPU IOMMU/Book-of-Truth, attestation digest, and Trinity drift guard.
- The same gate does not inspect `holyc-inference/NORTH_STAR.md`, `holyc-inference/automation/north-star-e2e.sh`, TempleOS QEMU drive readonly semantics, or model-family consistency.

Impact: this is not a violation by itself. It is a guardrail coverage gap: a future change can preserve policy text parity while still drifting on the executable e2e contract.

Recommended issue: add a second gate or extend the existing one with north-star contract checks for model family, shared image, read-only OS image, separate writable data image, and serial token output.

### 5. WARNING: TempleOS top-level North-Star still lists networking while WS8 and hard policy freeze it

Evidence:
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:15` still lists `Network stack (IPv4/IPv6, TCP/UDP, TLS strategy)` as a North-Star outcome.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:123-128` freezes WS8 and marks the networking tasks as `WON'T DO under air-gap policy`.
- The user hard rule for this audit requires all WS8 networking tasks to be recorded out of scope due to air-gap policy.

Impact: the lower-level WS8 section is safe, but the top-level outcome still advertises a forbidden direction. This creates recurring ambiguity for future queue generation and for cross-repo policy readers.

Recommended issue: reword the top-level networking outcome as an explicitly frozen/non-goal entry, or move it to an archived/future-out-of-scope section.

## Validation

Commands run:
- `bash /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/check-trinity-policy-sync.sh`
- `nl -ba` inspections of the cited TempleOS and holyc-inference files.

No QEMU or VM command was executed.
