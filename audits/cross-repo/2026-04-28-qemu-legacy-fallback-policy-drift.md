# Cross-Repo Audit: QEMU Legacy Fallback Policy Drift

Generated: 2026-04-28T15:43:39Z
Scope: TempleOS `../templeos-gpt55` and holyc-inference `../holyc-gpt55`
Audit angle: Cross-repo invariant check

## Question

Do the two repos enforce the same air-gap contract for QEMU no-network flags, especially the documented legacy fallback from `-nic none` to `-net none`?

## Evidence

- LAWS.md says any QEMU/VM command must explicitly disable networking with `-nic none`; legacy fallback is `-net none`.
- TempleOS modernization criteria document the fallback as valid only when `-nic none` is unavailable, require an explicit `-net none` command line, and require fallback reason evidence.
- TempleOS current static report recognizes both fallback forms with `AIRGAP_RE = ...-(nic|net)...none...`; latest report shows 1,238 scanned files, 16 files with QEMU mentions, 36 direct QEMU mentions, 73 no-network evidence lines, and 0 missing/forbidden network findings.
- holyc-inference `bench/qemu_prompt_bench.py` accepts user-supplied `-net none` and `-net=none` as disabled networking in `reject_network_args`, then prepends canonical `-nic none` to the built command.
- holyc-inference `bench/airgap_audit.py` treats the same `-net none` and `-net=none` tokens as findings: "legacy `-net none` present; use `-nic none` in benchmark artifacts".
- holyc-inference `bench/qemu_source_audit.py` states every source QEMU command must include `-nic none`, with no fallback language. Its latest source report checked 1 command with 0 findings; its latest artifact audit checked 536 commands with 0 findings.

Reproduction, read-only:

```text
qemu_prompt_bench.build_command("qemu-system-x86_64", Path("TempleOS.img"), ["-net", "none"])
=> qemu-system-x86_64 -nic none -serial stdio -display none -drive file=TempleOS.img,format=raw,if=ide -net none

airgap_audit.command_violations(command)
=> ["legacy `-net none` present; use `-nic none` in benchmark artifacts"]
```

## Findings

1. WARNING: Cross-repo policy mismatch on `-net none` fallback.
   TempleOS and the Sanhedrin law text treat `-net none` as a constrained valid fallback; holyc-inference benchmark/source audits encode `-nic none` as the only passing form. This can make a law-compliant legacy fallback appear as a holyc benchmark violation.

2. WARNING: Intra-repo launcher/auditor mismatch in holyc-inference.
   The holyc benchmark launcher permits `-net none` as a disabled-network argument, but the recorded-artifact auditor fails a command containing that permitted token. A future fallback run could be accepted at launch time and then fail its own audit after the fact.

3. INFO: Current committed benchmark artefacts are not exposing the mismatch.
   holyc-inference latest benchmark audit reports 536 recorded QEMU commands checked with 0 findings, and source audit reports 1 command checked with 0 findings. The drift is latent until a real legacy fallback path is exercised.

## LAWS.md Impact

- Law 2 remains materially satisfied for current artefacts: no evidence of guest networking enablement was found.
- The enforcement contract is ambiguous across repos: one side treats `-net none` as compliant fallback evidence, the other treats it as a policy finding.

## Recommended Remediation

- Decide whether `-net none` remains an allowed legacy fallback for both repos or whether Sanhedrin should tighten the law to require `-nic none` only for holyc-inference benchmarks.
- If fallback remains allowed, align holyc-inference `airgap_audit` and `qemu_source_audit` with TempleOS semantics: pass `-net none` only when no conflicting network backends/devices are present, and require fallback reason/provenance in recorded artefacts.
- Add one synthetic holyc-inference test for a legacy fallback command so launcher acceptance and audit classification cannot diverge again.
