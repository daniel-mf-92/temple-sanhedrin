# Cross-Repo Audit: QEMU Control Channel Local-Access Drift

- Audit angle: cross-repo invariant check
- Audit time: `2026-04-29T19:49:33Z`
- TempleOS HEAD: `00d1bdcd92c1af0b5c10b5ccc25cc1503f98937e`
- holyc-inference HEAD: `485af0ea41a239c8393542d6e0e2fc5944f30f53`
- Sanhedrin HEAD at audit start: `ea98f4ead5d56fdd76cf02340d823ce8d0d44f5b`
- Scope: read-only review of QEMU serial, monitor, QMP, and user extension arguments. No TempleOS or holyc-inference source was modified. No QEMU/VM command was executed. No WS8 networking task, socket, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, package fetch, or live liveness check was executed.

## Summary

Found 3 findings: 2 critical and 1 warning.

The prior QEMU argument audit covered guest NIC/network escape hatches. This audit checks a different invariant: local-only Book-of-Truth access and QEMU control/serial channels. Both TempleOS and holyc-inference can still build QEMU command lines that contain `-nic none` while also accepting extra `-serial`, `-qmp`, or monitor-like channels after the default local serial configuration. That means "guest networking disabled" can be true while Book-of-Truth-bearing serial or VM control surfaces are forwarded to host sockets.

## Findings

### CRITICAL-001: holyc-inference rejects NIC arguments but accepts serial/QMP TCP channels

Applicable laws:
- Law 11: Book of Truth Local Access Only
- Law 2: Air-Gap Sanctity, because socket-capable QEMU host channels are outside the air-gap evidence model even when guest NICs are disabled

Evidence:
- `holyc-inference/bench/qemu_prompt_bench.py:114-143` rejects `-nic`, `-net`, `-netdev`, and common network devices only.
- `holyc-inference/bench/qemu_prompt_bench.py:146-159` prepends `-serial stdio` and then appends user-provided `qemu_args`.
- `holyc-inference/bench/qemu_prompt_bench.py:313-324` exposes the extension surface as repeated `--qemu-arg` values.
- A read-only Python import of `build_command()` accepted `['-serial', 'tcp:127.0.0.1:4555,server,nowait', '-qmp', 'tcp:127.0.0.1:4556,server,nowait']` and produced:
  `qemu-system-x86_64 -nic none -serial stdio -display none -drive file=/tmp/TempleOS.audit.img,format=raw,if=ide -serial tcp:127.0.0.1:4555,server,nowait -qmp tcp:127.0.0.1:4556,server,nowait`

Assessment:

The benchmark guard proves guest NIC disablement, not local-only serial/control confinement. QEMU serial backends and QMP can use TCP sockets independently of guest NIC devices. If future inference runs emit token, policy, attestation, or Book-of-Truth rows over serial, the current `--qemu-arg` boundary can move that stream to a socket while benchmark evidence still says `-nic none`.

Required remediation:
- Reject `-serial`, `-chardev`, `-monitor`, `-qmp`, `-qmp-pretty`, and socket backend tokens unless an explicit local-only safe list is defined.
- If alternate serial routing is needed, allow only local console/file modes that are classified under Law 11 and do not create TCP/UDP/unix listener surfaces.
- Add a dry-run gate that classifies the final QEMU argv as `guest_airgap_ok` and `local_access_ok` separately.

### CRITICAL-002: TempleOS QEMU wrappers append unchecked control/serial args after local serial defaults

Applicable laws:
- Law 11: Book of Truth Local Access Only
- Law 2: Air-Gap Sanctity, as a host-control-channel gap rather than a guest NIC gap

Evidence:
- `TempleOS/automation/qemu-headless.sh:67-73` configures `-monitor none` and `-serial file:$SERIAL_LOG_FILE`.
- `TempleOS/automation/qemu-headless.sh:92-95` splits `EXTRA_ARGS` and appends them after the local serial/default monitor configuration.
- `TempleOS/automation/qemu-headless.sh:98-100` reports only the selected air-gap flag, not whether later arguments added another serial, monitor, QMP, or socket backend.
- `TempleOS/automation/qemu-smoke.sh:58-64` configures `-monitor none` and `-serial stdio`.
- `TempleOS/automation/qemu-smoke.sh:83-86` appends unchecked `EXTRA_ARGS` after those defaults.

Assessment:

The TempleOS wrappers can be made to contain both local defaults and later conflicting control channels. Examples include a second `-serial tcp:...`, `-monitor tcp:...`, `-qmp tcp:...`, or `-chardev socket,...` argument. This is distinct from adding a NIC: the guest may remain air-gapped while the host exposes the VM's serial/control plane. That conflicts with TempleOS policy that the serial mirror has no forwarding, streaming, or remote access path.

Required remediation:
- Validate final QEMU argv for both guest-network and host-channel policy before launch.
- Fail closed on `-serial tcp:*`, `-serial udp:*`, `-serial telnet:*`, `-chardev socket*`, `-monitor tcp:*`, `-qmp tcp:*`, and any `server,nowait` socket channel unless a reviewed local-only exception exists.
- Keep `-monitor none` non-overridable for validation runs that can emit Book-of-Truth rows.

### WARNING-001: Policy text separates local-only serial doctrine from QEMU command validation

Applicable laws:
- Law 11: Book of Truth Local Access Only
- Law 5: North Star Discipline, because validation evidence can appear compliant while testing the wrong boundary

Evidence:
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:222-230` states that Book-of-Truth output requires direct physical access, that the QEMU host must be physically local, and that there is no forwarding, streaming, or remote access path for serial output.
- `holyc-inference/bench/README.md:30-35` documents serial capture and says the runner injects `-nic none` and rejects conflicting QEMU networking arguments, but does not define a local-only control-channel rule.
- `holyc-inference/bench/qemu_prompt_bench.py:51-53` still stores `command`, `stdout_tail`, and `stderr_tail` in benchmark records, so command-channel classification matters for artifact trust.

Assessment:

The docs and code mostly check "contains `-nic none`" or "rejects NIC/network device args." That is necessary but not sufficient for Law 11. A cross-repo evidence record should say whether serial/control channels are local-only, whether raw serial tails are persistable, and whether any socket/listener backend was present.

Required remediation:
- Extend Trinity policy sync or Sanhedrin static checks with a `qemu_local_channel_ok` dimension.
- Require benchmark/report artifacts to include `serial_backend_class` and `control_channel_class`, with any socket-backed channel marked release-blocking for Book-of-Truth-bearing runs.
- Treat remote serial/control channels as separate from guest NIC state so Law 2 and Law 11 can fail independently.

## Positive Observations

- The reviewed holyc-inference benchmark still injects `-nic none` and rejects common NIC/network-device arguments.
- The reviewed TempleOS QEMU wrappers still include `-nic none` or `-net none` fallback for guest networking.
- This audit did not find or execute any TempleOS guest networking stack, WS8 networking task, NIC driver, sockets, TCP/IP, UDP, TLS, DHCP, DNS, HTTP, package install, VM launch, or remote runtime service.

## Read-Only Verification

Commands run were limited to `git rev-parse`, `nl`/`sed` source reads, `rg` over local audit/source files, `date`, and one local Python import that called `reject_network_args()` / `build_command()` without launching QEMU.

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py | sed -n '1,180p;300,340p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/qemu-headless.sh | sed -n '1,130p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/qemu-smoke.sh | sed -n '1,120p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '210,240p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/README.md | sed -n '1,70p'
```
