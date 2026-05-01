# Cross-Repo QEMU Control Socket and Include Air-Gap Drift Audit

- Audit angle: cross-repo invariant checks
- Timestamp: 2026-05-01T08:06:40Z
- TempleOS HEAD inspected: `87a8f6e3d71518355903d19b8063f5c714984425`
- holyc-inference HEAD inspected: `a70776642a09de7ed01eb75aaaebbdd3243f84c2`
- Scope note: read-only source inspection and host-only parser calls. No TempleOS guest, QEMU, VM, networking command, WS8 task, or builder-repo write was executed.

## Invariant Under Audit

Law 2 and Law 11 require QEMU launch proof to be effective, not merely textual. A launch path that says `-nic none` must also reject adjacent QEMU surfaces that can reopen remote/local control channels or hide unaudited device policy:

- `-serial tcp:...`, `-monitor tcp:...`, `-qmp tcp:...`, `-chardev socket,...`, `-gdb tcp:...`
- `-vnc`, `-spice`, and VNC-backed display strings
- `-readconfig ...` and `@response-file` includes

holyc-inference has moved toward this stronger structured argv invariant. TempleOS has a shared shell guard for NIC devices, but several QEMU launch surfaces still accept socket/control/config include arguments.

## Findings

### 1. WARNING: TempleOS shared QEMU guard accepts control sockets and remote display endpoints

Evidence:
- `TempleOS/automation/qemu-airgap-lib.sh:15-90` rejects `-nic`, `-net`, `-netdev`, NIC devices, `hostfwd=`, `guestfwd=`, and `netdev=`.
- The same function has no cases for `-serial tcp:...`, `-monitor tcp:...`, `-qmp tcp:...`, `-chardev socket,...`, `-gdb tcp:...`, `-vnc`, `-spice`, or VNC display strings.
- Host-only probe results after sourcing `qemu-airgap-lib.sh`: `ACCEPT -serial tcp:127.0.0.1:4444,server=on`, `ACCEPT -monitor tcp:127.0.0.1:5555,server=on`, `ACCEPT -vnc :1`, and `ACCEPT -chardev socket,id=s0,host=127.0.0.1,port=4444`.

Assessment:
This is not evidence that a builder executed a networked VM. It is an enforcement drift: a future TempleOS `EXTRA_ARGS` value can preserve `-nic none` while adding a QEMU socket/control endpoint. For Law 11, a remote serial/control surface is sensitive even when no emulated NIC exists.

### 2. WARNING: TempleOS shared QEMU guard accepts QEMU config and response-file includes

Evidence:
- `TempleOS/automation/qemu-airgap-lib.sh:15-90` does not reject `-readconfig` or `@...` response files.
- Host-only probe results after sourcing the guard: `ACCEPT -readconfig /tmp/qemu.conf` and `ACCEPT @/tmp/qemu.args`.
- `TempleOS/automation/qemu-headless.sh:97-104` and `TempleOS/automation/qemu-smoke.sh:88-95` parse `EXTRA_ARGS`, call the shared guard, append those args, and then require a disabled-network token in the final argv.

Assessment:
`-readconfig` and response files can hide device or socket policy outside the visible final shell text. The final argv can still contain `-nic none`, so a token-presence check is not enough to prove the full launch configuration is air-gapped.

### 3. WARNING: TempleOS host-side report tooling still models forbidden QEMU networking narrower than holyc-inference

Evidence:
- `TempleOS/automation/qemu-command-manifest.py:65-73` and `TempleOS/automation/qemu-airgap-report.py:26-32` define forbidden patterns for NIC/network backends and forwarding tokens.
- Those report regexes do not include `-serial tcp:`, `-monitor tcp:`, `-qmp tcp:`, `-chardev socket`, `-gdb tcp:`, `-vnc`, `-spice`, `-readconfig`, or `@response-file`.
- The report code still counts `-nic none` / runtime guard evidence as enough for the no-network axis in files such as `qemu-command-manifest.py:520-591` and `qemu-airgap-report.py:387-420`.

Assessment:
Even if launchers are hardened later, the report layer can continue green-lighting stale or partial proof because its forbidden surface vocabulary is narrower than the current holyc-inference audit vocabulary.

### 4. INFO: holyc-inference already encodes the stricter cross-repo target contract

Evidence:
- `holyc-inference/bench/qemu_args_policy_audit.py:43-55` defines socket endpoint and remote display markers, and `:168-263` rejects response files, `-readconfig`, socket transports, VNC, SPICE, and forwarded endpoints.
- `holyc-inference/tests/test_qemu_args_policy_audit.py:29-52` asserts rejection for `@hidden-networking.args`, `-readconfig`, `-chardev socket`, `-vnc`, VNC display, and SPICE.
- `holyc-inference/tests/test_qemu_prompt_bench.py:83-104` asserts benchmark launcher rejection for `-chardev socket`, `-serial tcp`, `-monitor udp`, `-vnc`, and networked `-nic` extras.
- Host-only probe through `qemu_args_policy_audit.audit_args(...)` returned `socket endpoint`, `qemu config include`, or `nested qemu args include` for the same cases TempleOS accepted.

Assessment:
The holyc-inference side has the better invariant for Law 2 and Law 11: QEMU argv proof is parsed as a structured launch contract and denies hidden includes/control sockets, not only guest NICs.

## Non-Findings

- TempleOS `qemu-headless.sh`, `qemu-smoke.sh`, and `qemu-holyc-load-test.sh` do call `qemu_airgap_require_disabled_network` on constructed argv today.
- TempleOS `qemu-airgap-extra-args-smoke.sh` covers runtime rejection for `-nic user,hostfwd=...` and `-netdev user,id=...`; the gap is the untested control-socket/config-include surface.
- No current evidence from this pass shows WS8 networking task execution or a TempleOS guest TCP/IP stack addition.

## Recommended Backlog

- Extend `qemu_airgap_reject_network_args` to reject socket transports, remote displays, `-readconfig`, and `@response-file` includes, matching holyc-inference's `qemu_args_policy_audit.py` vocabulary.
- Add TempleOS host-only smoke cases for `-serial tcp:...`, `-monitor tcp:...`, `-chardev socket,...`, `-vnc :1`, `-readconfig`, and `@args`.
- Update `qemu-command-manifest.py` and `qemu-airgap-report.py` so reports flag the same forbidden control/socket/include surfaces as the runtime guard.

## Read-Only Verification Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55 rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55 rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/qemu-airgap-lib.sh | sed -n '1,160p'
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/qemu-airgap-extra-args-smoke.sh | sed -n '1,120p'
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/qemu-command-manifest.py | sed -n '1,80p;520,610p'
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/qemu-airgap-report.py | sed -n '1,70p;380,420p'
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/qemu_args_policy_audit.py | sed -n '1,220p'
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/tests/test_qemu_args_policy_audit.py | sed -n '1,70p'
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/tests/test_qemu_prompt_bench.py | sed -n '83,104p'
```
