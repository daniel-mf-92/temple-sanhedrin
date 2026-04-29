# LAWS Serial Locality Ambiguity Research

Timestamp: 2026-04-29T23:21:16+02:00

Audit angle: deeper `LAWS.md` research.

Scope:
- Sanhedrin `LAWS.md` at `56631cf4be8f9d08ec28e70747a6d702b0b3da55`.
- TempleOS modernization policy/docs at `d84df3da3e8c241f43882f76493e1ae5a2f03b9e`.
- holyc-inference prompt at `485af0ea41a239c8393542d6e0e2fc5944f30f53`.

No TempleOS or holyc-inference source files were modified. No QEMU/VM command, SSH command, WS8 networking task, socket, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, package-manager, or remote-runtime action was executed.

## Question

How should auditors distinguish required Book-of-Truth serial emission from forbidden remote log access?

`LAWS.md` currently contains three clauses that are directionally compatible but easy to misread when combined:

- Law 3 says removal of "serial port exfiltration logic" violates Book-of-Truth immutability.
- Law 8 requires bytes to be emitted with `out 0x3F8` in the same instruction sequence as the event.
- Law 11 says the Book of Truth can only be read with direct physical access, forbids serial output being forwarded, streamed, or proxied to a remote host, and forbids any path making log contents available outside the local console.

The intended invariant appears to be:

> The guest must emit Book-of-Truth records to COM1 synchronously, and the capture endpoint must be physically local to the audited machine. Serial is a local evidence channel, not a remote telemetry channel.

## Evidence

1. `LAWS.md` uses the word "exfiltration" for required serial behavior in Law 3, but Law 11 forbids remote viewing and forwarding. The word can be read as "leave the guest" or as "export outside the local trust boundary"; those are different audit outcomes.

2. TempleOS `MODERNIZATION/MASTER_TASKS.md` clarifies the intended boundary more precisely: the serial mirror may go to the QEMU host, but that host must also be physically local; no forwarding, streaming, or remote access path is allowed.

3. TempleOS `MODERNIZATION/LOOP_PROMPT.md` still documents an Azure-hosted QEMU instance and tells builders to check serial output for compilation errors or Book-of-Truth log entries. That creates a hazardous edge case: remote compile-only serial output may be tolerable, but remote inspection of Book-of-Truth-bearing serial output contradicts the local-access rule.

4. holyc-inference `LOOP_PROMPT.md` also advertises the same Azure test VM. The inference repo has no Book-of-Truth runtime ownership, but its prompt can still steer work toward a remote TempleOS serial capture path.

## Findings

1. **WARNING - Law 3 and Law 11 need a shared term for the serial trust boundary.**
   Evidence: Law 3's "serial port exfiltration logic" is mandatory, while Law 11 forbids serial output being forwarded, streamed, proxied, or made available outside local access. Without a definition, auditors can disagree on whether a serial file on a remote QEMU host is required evidence, tolerated compile output, or a Law 11 violation.

2. **WARNING - Current builder prompt text can produce Law 11 drift even when Law 2 is satisfied.**
   Evidence: the documented Azure QEMU command includes `-nic none`, which preserves guest air-gap, but the same prompt instructs builders to check Book-of-Truth log entries in serial output over SSH. Guest air-gap does not prove local physical access to Book-of-Truth contents.

3. **WARNING - Retroactive audits should classify serial evidence by observer locality, not only by QEMU network flags.**
   Evidence: a validation row can contain `-nic none` and still involve remote `ssh`/`scp` access to serial capture files. That is Law 2-safe but potentially Law 11-unsafe if Book-of-Truth contents are observed remotely.

4. **INFO - The TempleOS task doctrine already contains the likely resolution.**
   Evidence: `MASTER_TASKS.md` says the host-side serial capture file is readable only while sitting at the host. This can be promoted into `LAWS.md` as the canonical distinction between local serial mirroring and remote serial forwarding.

## Proposed LAWS.md Refinement

Replace Law 3's ambiguous phrase:

```text
Removal of serial port exfiltration logic
```

with:

```text
Removal of synchronous local serial mirror logic: each Book-of-Truth record must still be emitted to COM1 (`out 0x3F8`) for physically local capture.
```

Add this note under Law 11:

```text
Local serial mirror exception: COM1/QEMU serial capture is allowed only when the capture endpoint is physically local to the audited machine and is not forwarded, streamed, proxied, copied to removable media, or inspected through SSH/remote desktop/cloud console. `-nic none` proves guest air-gap only; it does not prove Law 11 local access.
```

Add this audit rule:

```text
Any validation evidence that combines Book-of-Truth serial contents with SSH, SCP, cloud VM consoles, remote desktops, or non-local file transfer is not valid Law 11 proof and should be recorded as at least WARNING unless explicitly limited to compile-only output with Book-of-Truth contents absent or redacted.
```

## Local Issue Opened

See `audits/issues/2026-04-29-laws-serial-locality-issue.md`.

