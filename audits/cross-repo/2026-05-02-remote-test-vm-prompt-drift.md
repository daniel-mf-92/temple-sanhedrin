# Cross-Repo Audit: Remote Test VM Prompt Drift

Timestamp: 2026-05-02T09:55:29+02:00

Scope: cross-repo invariant check across current TempleOS and holyc-inference heads. TempleOS and holyc-inference were read-only. No live liveness watching, process restart, QEMU/VM command, SSH/SCP command, network command, WS8 networking task, socket, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, package install, remote fetch, or trinity source edit was executed.

Repos inspected:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `9f3abbf263982bf9344f8973a52f845f1f48d109` on `codex/modernization-loop`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554bea44c132137c590f02034c8f726` on `main`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at `5919e204e0aa7e7e2c4f9c7a3178346ea3bd9fd0`

Audit angle: cross-repo invariant check. Do the current builder prompts keep validation local, provenance-strong, and air-gap compatible after the historical host-key-bypass drift finding?

Findings: 5 warning findings

## Summary

Both builder prompts still present the public Azure VM at `52.157.85.234` as the preferred real TempleOS validation path and both embed `ssh -o StrictHostKeyChecking=no azureuser@52.157.85.234`. TempleOS additionally embeds a remote QEMU example with `-nic none`, which preserves guest air-gap in the sample, but the validation channel itself is still a remote runtime service with explicitly disabled host-key verification. This is not evidence of guest networking, and no remote command was executed in this audit. The drift is evidence provenance: future builder iterations can keep producing remote compile/QEMU claims whose host identity is not authenticated in the prompt contract.

## Findings

### WARNING-001: TempleOS prompt still prescribes public remote validation with host-key checking disabled

Evidence:
- `TempleOS/MODERNIZATION/LOOP_PROMPT.md:79-82` presents a real TempleOS compilation VM on Azure as available and says the builder can and should test `.HC` code on it.
- `TempleOS/MODERNIZATION/LOOP_PROMPT.md:84` gives `ssh -o StrictHostKeyChecking=no azureuser@52.157.85.234`.
- `TempleOS/MODERNIZATION/LOOP_PROMPT.md:85-89` names the remote ISO, cloned repos, and a remote QEMU command.

Impact: the prompt normalizes accepting validation from a public remote host while disabling host-key verification. For Law 2 and Book-of-Truth evidence, this weakens provenance even when the guest QEMU command itself includes `-nic none`.

Recommended issue: replace the raw SSH recipe with a local-first validation path and, if remote validation remains allowed, require a pinned host-key fingerprint plus a structured `remote_unverified=false` evidence field.

### WARNING-002: holyc-inference prompt duplicates the same unverified remote-host contract

Evidence:
- `holyc-inference/LOOP_PROMPT.md:81-83` states the same Azure VM has QEMU and a TempleOS ISO ready for testing.
- `holyc-inference/LOOP_PROMPT.md:85` gives `ssh -o StrictHostKeyChecking=no azureuser@52.157.85.234`.
- `holyc-inference/LOOP_PROMPT.md:89-94` instructs builders to SSH in, create a FAT disk image, boot TempleOS, and capture serial output.

Impact: the throughput-plane builder can generate trusted-looking HolyC compile or inference evidence from the same unauthenticated remote host channel. That can later be merged with TempleOS secure-local claims even though the host identity proof was bypassed.

Recommended issue: align the inference prompt with the same remote validation provenance requirements as TempleOS: pinned host key, no host-key bypass, explicit local/remote provenance in final evidence, and fail-closed classification when host identity is not verified.

### WARNING-003: Guest air-gap evidence and remote-host provenance are conflated

Evidence:
- `TempleOS/MODERNIZATION/LOOP_PROMPT.md:61` requires `-nic none` on all QEMU commands.
- `TempleOS/MODERNIZATION/LOOP_PROMPT.md:89` includes `-nic none` in the remote QEMU example.
- The same prompt block still reaches that QEMU command through `StrictHostKeyChecking=no` on line 84.

Impact: a row can honestly show `-nic none` and still have weak host provenance. Those are separate claims: guest networking disabled is a QEMU argv property; remote validation authenticity is a host transport property. Current prompt wording does not force builders or auditors to record the distinction.

Recommended issue: require validation evidence to split `guest_network=disabled` from `host_transport=local|remote_verified|remote_unverified`, and treat `remote_unverified` as warning-grade evidence for Law 2/Law 11 historical scoring.

### WARNING-004: The prompt contract conflicts with the no remote-runtime-services safety direction

Evidence:
- The current hard language requirement for this Sanhedrin sibling says to reject tasks requiring network-dependent package ecosystems or remote runtime services.
- `TempleOS/MODERNIZATION/LOOP_PROMPT.md:81-84` and `holyc-inference/LOOP_PROMPT.md:83-85` make a remote runtime service look like a normal builder validation path.

Impact: builder prompts can pull future iterations toward remote validation even when the safer invariant is local, air-gapped, provenance-strong host execution. This is especially risky for Book-of-Truth, key-release, and policy-digest work where validation evidence becomes part of the trust story.

Recommended issue: demote remote VM use to an explicit exception path that requires human approval or a pinned-host proof, and keep ordinary builder validation local/host-only.

### WARNING-005: Historical trend already showed this pattern becoming normalized, but current prompts still seed it

Evidence:
- `audits/trends/2026-05-02-remote-host-key-bypass-validation-drift.md` found 165 of 194 historical remote modernization validation rows used `StrictHostKeyChecking=no`, with zero rows recording host-key pinning.
- Current TempleOS and holyc-inference prompts still contain the same `StrictHostKeyChecking=no azureuser@52.157.85.234` recipe.

Impact: the historical issue is not only old ledger debt; the current prompt text can keep regenerating the same low-provenance evidence pattern.

Recommended issue: add a Sanhedrin prompt/source check that flags builder prompt text containing `StrictHostKeyChecking=no` for validation hosts unless paired with explicit non-authoritative classification.

## Law Mapping

- Law 2: no guest networking was added or executed in this audit. The remote QEMU example includes `-nic none`; the warning is host-validation provenance, not a discovered guest air-gap breach.
- Law 5 / North Star Discipline: validation evidence must be meaningful enough to support secure-local claims; unauthenticated remote host evidence is weaker than the prompt implies.
- Law 11: Book-of-Truth local-only semantics are easier to audit when validation capture remains local or the remote host boundary is explicitly authenticated and classified.

## Validation

Host-only read commands used:
- `git rev-parse HEAD && git branch --show-current` in TempleOS, holyc-inference, and Sanhedrin.
- `rg -n "Azure VM|StrictHostKeyChecking=no|52\\.157\\.85\\.234|ssh .*azureuser|QEMU command|Real TempleOS" ...` against builder prompt files and automation paths.
- `nl -ba ... | sed -n ...` for the cited prompt ranges.

No TempleOS or holyc-inference source was modified. No QEMU, VM, SSH, SCP, or network command was executed.
