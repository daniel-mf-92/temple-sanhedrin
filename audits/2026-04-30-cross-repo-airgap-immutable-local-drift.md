# Cross-Repo Air-Gap / Immutable-Image / Local-Only Drift Audit

- Audit angle: cross-repo invariant checks
- Timestamp: 2026-04-30T00:39:02+02:00
- Repos inspected: `TempleOS` and `holyc-inference`
- TempleOS HEAD: `d84df3da3e8c241f43882f76493e1ae5a2f03b9e`
- holyc-inference HEAD: `485af0ea41a239c8393542d6e0e2fc5944f30f53`
- Scope note: read-only inspection only; no builder repo files were modified or executed.

## Invariant Under Audit

The TempleOS modernization side promises an air-gapped guest, immutable OS image, and local-only Book-of-Truth access. The inference side assumes it can load local model artifacts under `secure-local`, with trust delegated back to the TempleOS control plane. These contracts must line up before the two repos can share a trusted runtime path.

Relevant law anchors:
- `LAWS.md:27-35` requires no guest networking and forbids network-dependent package managers or build steps.
- `LAWS.md:140-149` requires immutable installed OS images and `readonly=on` on QEMU OS-image drives.
- `LAWS.md:151-159` forbids remote Book-of-Truth viewing or serial forwarding/proxying.

## Findings

### 1. CRITICAL: TempleOS compile smoke still downloads the ISO on demand

Evidence:
- `TempleOS/automation/qemu-compile-test.sh:12-13` defines `ISO_URL=https://templeos.org/Downloads/TempleOS.ISO`.
- `TempleOS/automation/qemu-compile-test.sh:23-29` downloads the ISO with `curl -sL` when the local ISO is missing.
- `LAWS.md:31-35` treats network-dependent build steps as air-gap violations.

Impact:
- A host-side compile helper can silently depend on network availability before booting the guest.
- The inference loop depends on compile validation against TempleOS; this makes the validation path non-reproducible under the same air-gap contract that inference documents as mandatory.

Recommendation:
- Require a preseeded local ISO path or fail closed when absent.
- Record the expected ISO hash in a local manifest instead of fetching from the network.

### 2. CRITICAL: TempleOS QEMU wrappers boot writable OS disk images

Evidence:
- `TempleOS/automation/qemu-headless.sh:84-86` appends `-drive file=$DISK_IMAGE,format=raw,if=ide`.
- `TempleOS/automation/qemu-smoke.sh:75-77` appends `-drive file=$DISK_IMAGE,format=raw,if=ide`.
- `LAWS.md:144-149` explicitly flags QEMU launch commands missing `-drive readonly=on` for the OS image.

Impact:
- Any DISK_IMAGE boot path can mutate the installed OS image in-place.
- This breaks the immutable-image assumption that inference-side trusted sessions rely on when treating TempleOS as the control plane.

Recommendation:
- Split OS and data drives explicitly.
- Add `readonly=on` to OS image drives and only attach separate scratch/model drives as writable when required.

### 3. WARNING: `EXTRA_ARGS` can re-open QEMU networking after `-nic none`

Evidence:
- `TempleOS/automation/qemu-headless.sh:16` exposes `EXTRA_ARGS`.
- `TempleOS/automation/qemu-headless.sh:76-82` adds `-nic none` or `-net none`.
- `TempleOS/automation/qemu-headless.sh:92-96` appends unfiltered `EXTRA_ARGS` after the no-network flag.
- `TempleOS/automation/qemu-smoke.sh:14`, `69-73`, and `83-87` have the same pattern.

Impact:
- The helper prints that it is enforcing the air-gap, but a later `EXTRA_ARGS='-nic user'` or equivalent can add a second NIC.
- Inference-side testing guidance relies on TempleOS QEMU wrappers as policy-preserving infrastructure; this weakens that assumption.

Recommendation:
- Reject `EXTRA_ARGS` containing `-nic`, `-net`, `-netdev`, `socket`, `tap`, `user`, or equivalent network device options.
- Prefer an allowlist of known-safe debug/display/storage flags.

### 4. WARNING: holyc-inference still describes remote TempleOS validation via Azure

Evidence:
- `holyc-inference/LOOP_PROMPT.md:81-87` documents an Azure VM and SSH endpoint for TempleOS compilation testing.
- `holyc-inference/LOOP_PROMPT.md:89-94` instructs agents to boot TempleOS there and use serial output for compile results.
- `LAWS.md:151-159` forbids remote viewing, forwarding, or proxying of Book-of-Truth/serial contents.

Impact:
- Even when the guest itself is booted with no NIC, serial evidence and TempleOS execution results are intentionally consumed over SSH on a remote VM.
- This is at least a policy ambiguity for Book-of-Truth local-only access and should not be part of the trusted `secure-local` validation path.

Recommendation:
- Classify Azure compile validation as legacy/dev-only and outside trusted `secure-local` release evidence.
- Require local physical-host validation for any run whose serial output contains Book-of-Truth entries.

### 5. WARNING: holyc-inference model-prep workstreams still point at remote model sources

Evidence:
- `holyc-inference/MASTER_TASKS.md:20` says air-gapped means no downloading, HTTP, or networking.
- `holyc-inference/MASTER_TASKS.md:181-186` describes host-side preparation from Hugging Face / Ollama sources, including "download from Hugging Face" and "pull Ollama blob".
- `holyc-inference/MASTER_TASKS.md:199-204` includes ecosystem compatibility tasks that parse Ollama manifests and model cards.

Impact:
- The repo distinguishes runtime from host tooling, but the cross-repo policy now says network-dependent build/package steps are out of scope for trusted paths.
- Without an explicit offline-import boundary, model provenance can drift from "preseeded local artifact verified by TempleOS" to "builder pulled a remote blob".

Recommendation:
- Rewrite WS12/WS15 trusted-path wording around offline-imported artifacts only.
- If remote acquisition remains useful for developer experiments, mark it `dev-local` only and exclude it from trusted release or Book-of-Truth evidence.

## Summary

Findings: 5 total.

- Critical: 2
- Warning: 3

The main drift is not that the inference runtime has added networking. It has not in the inspected files. The drift is that host-side validation and artifact-prep pathways still encode network or remote-machine assumptions while TempleOS is being hardened around permanent air-gap, immutable image, and local-only evidence.
