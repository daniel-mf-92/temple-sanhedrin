# Cross-Repo QEMU Input Injection Contract Drift Audit

Timestamp: 2026-04-29T04:09:28+02:00

Audit owner: gpt-5.5 sibling, retroactive / historical scope only

Repos examined:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `6a6ee0bb104e6b13614d0953bcc1d4163e036240`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `ce09228422dae06e86feb84925d51df88d67821b`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at `39491bd6b9fc4b8f16c8388d39eb3aedc02ba318`

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source code was modified. No QEMU or VM command was executed.

## Summary

Found 5 findings: 4 warnings and 1 info.

This pass rechecked the prompt/input side of the cross-repo QEMU contract after TempleOS commit `6a6ee0bb104e` updated `automation/north-star-e2e.sh` with a stdio fallback path. The repos still do not share one input-injection ABI for air-gapped guest runs:

- TempleOS primary North Star input uses a QEMU monitor Unix socket and `sendkey`.
- TempleOS fallback input writes HolyC commands to QEMU stdio.
- holyc-inference benchmark input writes prompt text to the QEMU process stdin and host environment variables.
- holyc-inference North Star delegates to a future `automation/run-holyc-forward.sh` without defining which of those transports is canonical.

This is not a live liveness audit and not an air-gap breach finding. The reviewed QEMU launch surfaces still explicitly disable networking. The drift is that the input/control plane is underspecified enough that a future forward-pass runner could pass local tests while using a different guest-visible transport than TempleOS automation expects.

## Finding WARNING-001: TempleOS North Star now has two different command injection transports

Applicable laws:
- Law 5: North Star Discipline
- Law 11: Book of Truth Local Access Only

Evidence:
- `TempleOS/automation/north-star-e2e.sh:35-65` sends monitor commands through a Unix monitor socket using `socat` or `nc -U`.
- `TempleOS/automation/north-star-e2e.sh:90-104` translates `BOT_CMD` into keyboard scan-code `sendkey` operations.
- `TempleOS/automation/north-star-e2e.sh:108-123` launches the primary path with `-monitor unix:$MON,server,nowait` and `-serial file:$LOG`.
- `TempleOS/automation/north-star-e2e.sh:145-172` falls back to `-serial stdio`, `-monitor none`, and pipes repeated `BOT_CMD` lines plus `q` into QEMU stdin.

Assessment:
The primary and fallback paths are both local and air-gapped, but they are not equivalent guest contracts. One path injects keyboard scan codes via the QEMU monitor; the other writes command text to stdio. A North Star pass can therefore depend on host tooling availability (`socat`/`nc -U`, monitor socket binding, stdio console behavior) instead of proving a stable guest command ingress ABI.

Required remediation:
- Classify the accepted ingress method in the North Star output, for example `input_transport=monitor_sendkey|serial_stdio|shared_img`.
- Add a contract assertion that both paths produce the same guest-visible command transcript before accepting the same `BoT:` serial result.
- Treat `monitor_sendkey` as a local automation mechanism, not as the eventual inference prompt ABI.

## Finding WARNING-002: holyc-inference benchmark prompt input is host stdin/env, not a proven TempleOS guest ABI

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- `holyc-inference/bench/qemu_prompt_bench.py:244-248` sets `HOLYC_BENCH_PROMPT` and `HOLYC_BENCH_PROMPT_ID` in the host environment.
- `holyc-inference/bench/qemu_prompt_bench.py:251-259` passes `prompt_case.prompt` as stdin to the launched QEMU command.
- `holyc-inference/bench/qemu_prompt_bench.py:146-160` builds a QEMU command with `-serial stdio`, `-display none`, and a disk image, but no guest-side prompt file path or serial command protocol is declared.
- `holyc-inference/bench/README.md:30-35` describes capture and metric extraction, but not how the prompt becomes guest-visible HolyC input.

Assessment:
The benchmark harness has a host process input mechanism, but it does not prove that a TempleOS guest consumes that prompt. Host environment variables are not guest state, and raw QEMU stdin is ambiguous without a specified serial-console or monitor protocol. This leaves a gap between benchmark smoke success and the actual HolyC inference control path.

Required remediation:
- Define one guest-visible prompt ingress contract, such as `shared.img:/BENCH/PROMPTS.JSONL` plus a manifest hash, or a labelled serial command protocol.
- Keep host env/stdin only as fixture support unless the QEMU runner proves those bytes are delivered to the guest console.
- Emit the prompt id/hash back over serial from guest HolyC so benchmark reports can tie results to guest-consumed input.

## Finding WARNING-003: Future holyc-inference North Star runner can drift from both existing QEMU paths

Applicable laws:
- Law 2: Air-Gap Sanctity
- Law 5: North Star Discipline

Evidence:
- `holyc-inference/automation/north-star-e2e.sh:28-35` delegates the actual HolyC run to missing `automation/run-holyc-forward.sh`.
- `holyc-inference/automation/north-star-e2e.sh:35` extracts the first integer from the runner's final output line.
- `holyc-inference/bench/qemu_prompt_bench.py:114-160` has explicit network-argument rejection and injects `-nic none`.
- `TempleOS/automation/north-star-e2e.sh:108-172` has its own independent QEMU command construction and input-injection logic.

Assessment:
The future forward runner is the path that will matter for cross-repo proof, but its required QEMU flags and input transport are not constrained by either existing script. It could independently choose monitor input, stdio input, shared-disk input, or a host-only wrapper while still satisfying the current integer parser.

Required remediation:
- Make `run-holyc-forward.sh` call a shared guarded QEMU builder or copy the same rejection rules as `qemu_prompt_bench.py`.
- Require explicit `-nic none` or legacy `-net none` evidence in the runner output.
- Require a labelled result line that includes `input_transport`, `prompt_sha256`, `model_sha256`, and `token_id`; reject unlabelled integers.

## Finding WARNING-004: QEMU monitor control is local, but not yet policy-bounded as an automation-only channel

Applicable laws:
- Law 10: Immutable OS Image
- Law 11: Book of Truth Local Access Only

Evidence:
- `TempleOS/automation/north-star-e2e.sh:50-64` accepts arbitrary monitor command text through `send_mon`.
- `TempleOS/automation/north-star-e2e.sh:90-104` uses `send_mon "sendkey $key"` repeatedly to drive guest behavior.
- `TempleOS/automation/qemu-headless.sh:67-73` and `TempleOS/automation/qemu-smoke.sh:58-64` disable the QEMU monitor with `-monitor none`, so the top-level North Star harness is now the exception among TempleOS runner surfaces.
- `holyc-inference/bench/qemu_prompt_bench.py:146-160` does not expose a monitor socket and relies on stdio/serial for benchmark interaction.

Assessment:
The Unix monitor socket is local, so this is not a remote-access violation by itself. The risk is policy drift: once the monitor is part of the success path, future automation can grow non-keyboard control operations unless the allowed command set is explicitly bounded. That matters for immutable-image and local-only doctrine because QEMU monitor commands can affect VM state outside the guest's own audited HolyC path.

Required remediation:
- Restrict the North Star monitor helper to `sendkey` only, or rename/scope it so arbitrary monitor commands are not available to general harness logic.
- Emit `monitor_policy=sendkey_only` in logs when the monitor path is used.
- Keep benchmark/inference prompt injection independent from QEMU monitor control unless a separate law/policy document blesses the monitor as a local automation-only channel.

## Finding INFO-001: Reviewed launch surfaces preserve explicit guest air-gap flags

Applicable laws:
- Law 2: Air-Gap Sanctity

Evidence:
- `TempleOS/automation/north-star-e2e.sh:108-117` includes `-nic none` in the primary QEMU args.
- `TempleOS/automation/north-star-e2e.sh:149-158` includes `-nic none` in the stdio fallback args.
- `TempleOS/automation/qemu-headless.sh:76-82` uses `-nic none` or `-net none` fallback.
- `TempleOS/automation/qemu-smoke.sh:67-73` uses `-nic none` or `-net none` fallback.
- `holyc-inference/bench/qemu_prompt_bench.py:114-160` rejects network QEMU args and injects `-nic none`.

Assessment:
No WS8 networking task was executed, no network stack/NIC/socket/TCP/IP/UDP/TLS/DHCP/DNS/HTTP feature was added or enabled, and no VM was launched during this audit. The required invariant remains: any future runner must keep explicit `-nic none` or legacy `-net none` in the actual QEMU command.

## Non-Findings

- No TempleOS or holyc-inference source file was edited.
- No QEMU or VM command was executed.
- No live liveness watching, process restart, or current-iteration Sanhedrin audit was performed.
- No guest networking feature was recommended.
- The audit recommendations keep core guest implementation in HolyC; host-side bash/python remains tooling-only.

## Read-Only Verification Commands

```bash
git rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/north-star-e2e.sh | sed -n '1,260p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/qemu-headless.sh | sed -n '1,160p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/qemu-smoke.sh | sed -n '1,120p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/north-star-e2e.sh | sed -n '1,80p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py | sed -n '1,380p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/README.md | sed -n '1,80p'
```
