# Cross-Repo Audit: QEMU Readonly Policy Audit Gap

Timestamp: 2026-05-01T21:13:37Z

Scope: historical cross-repo invariant check, read-only against committed `HEAD` in TempleOS and holyc-inference.

Repos examined:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55` at `842c1acd5f97b1323bee570e95ba7e9cc3227500f`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55` at `a70776642a09de7ed01eb75aaaebbdd3243f84c2`
- temple-sanhedrin: `/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55` at `5551291d09183f7ddf2cb06de8ec87b67e09d84c`

Audit angle: Cross-repo invariant checks.

Rules checked: Law 2 air-gap sanctity, Law 10 immutable OS image, hard QEMU safety requirement.

## Summary

Both repos have converged on strong `-nic none` enforcement for QEMU launch evidence, but they have not converged on equivalent machine-checkable enforcement for the Law 10 `-drive readonly=on` OS-image requirement. The result is a cross-repo blind spot: holyc-inference can build and audit air-gapped benchmark commands that still boot a writable TempleOS image, while TempleOS command/report auditors can pass launcher evidence without recording or gating readonly drive state.

Findings:
- 2 CRITICAL findings.
- 1 INFO finding.

No QEMU or VM command was executed during this audit.

## Findings

### CRITICAL 1: holyc-inference QEMU benchmark builder still emits writable OS-image drive args

Law impact: Law 10.

Evidence:
- `bench/qemu_prompt_bench.py:577-591` builds the launch command with `-nic none`, `-serial stdio`, `-display none`, and `-drive file=<image>,format=raw,if=ide`.
- `tests/test_qemu_prompt_bench.py:17-25` asserts the exact writable drive string and does not require `readonly=on`.
- A committed-HEAD grep for `readonly=on` under `bench/` and `tests/` returned no matches.

Cross-repo invariant violated:
- TempleOS Law 10 says QEMU launch commands for OS images must include `-drive readonly=on`.
- holyc-inference's committed benchmark launch path can boot a TempleOS raw image without that option.

Risk:
- A benchmark or dry-run artifact can look compliant on Law 2 while violating immutable-image policy.
- The test suite currently locks in the unsafe drive shape as expected output.

Expected invariant:
- Any holyc-inference command that boots a TempleOS OS image should emit `-drive file=<image>,format=raw,if=ide,readonly=on` or an equivalent QEMU readonly blockdev form.
- Tests should assert both `-nic none` and readonly drive evidence.

### CRITICAL 2: both repos' QEMU audit gates are air-gap-only and do not gate readonly drive state

Law impact: Law 10.

Evidence:
- TempleOS `automation/qemu-airgap-report.py:15-32` defines QEMU, air-gap, runtime guard, and forbidden network regexes only; no readonly drive regex or immutable-image gate is present in the reviewed header.
- TempleOS `automation/qemu-command-manifest.py:16-78` tracks no-network, preferred `-nic none`, legacy `-net none`, serial, timeout, teardown, and forbidden network evidence; its `FileManifest` fields at `:81-116` do not include readonly drive evidence.
- holyc-inference `bench/airgap_audit.py:75-118` and `bench/qemu_source_audit.py:139-176` flag missing `-nic none` and network devices/backends, but do not flag `-drive file=...,format=raw,if=ide` without `readonly=on`.
- TempleOS committed-HEAD grep found `readonly=on` only in `MODERNIZATION/MASTER_TASKS.md:218`; no reviewed automation or lint-report source enforces it.

Cross-repo invariant violated:
- TempleOS records immutable-image doctrine as a Law 10 requirement, but the active QEMU evidence surfaces in both repos are built around Law 2 only.
- holyc-inference can rely on those air-gap reports as safety evidence even though they do not prove image immutability.

Risk:
- Future reports can continue to show PASS for QEMU safety while silently omitting the readonly property.
- Sanhedrin and builder loops may over-count air-gap closure as full QEMU safety closure.

Expected invariant:
- QEMU source/artifact audits in both repos should parse drive arguments and report `{os_image_drive_seen, readonly_on_seen, writable_os_image_drive_count}`.
- Strict gates should fail if a TempleOS OS image drive lacks `readonly=on`.
- If a non-OS scratch/shared drive is intentionally writable, the command should label that drive separately so the OS-image invariant remains auditable.

### INFO 1: no-network enforcement is aligned and stricter in holyc-inference

Law impact: Law 2.

Evidence:
- holyc-inference `bench/qemu_prompt_bench.py:471-511` reports missing `-nic none`, rejects non-air-gapped `-nic`, `-net`, `-netdev`, and common virtual NIC devices.
- holyc-inference `bench/qemu_prompt_bench.py:524-554` rejects user-supplied network arguments before command construction.
- TempleOS reports show PASS/OK rows for forbidden network and missing no-network counters in `MODERNIZATION/lint-reports/bookoftruth-airgap-safety-rollup-latest.md:43-56`.

This is aligned with the hard air-gap requirement. The residual drift is not networking enablement; it is that readonly image enforcement has not been promoted to the same gate strength.

## Recommended Remediation

1. In holyc-inference, change the benchmark drive builder to add `readonly=on` for the TempleOS OS image and update tests to assert it.
2. In holyc-inference artifact/source audits, add a Law 10 check for QEMU commands that contain an OS-image `-drive` without readonly evidence.
3. In TempleOS, extend `qemu-airgap-report.py` or `qemu-command-manifest.py` with immutable-image fields instead of keeping readonly enforcement as prose-only doctrine.
4. Keep shared data drives separate from OS images in command metadata, because writable shared drives may be valid while writable OS images are not.

## Audit Method

Read-only commands used:

```text
git -C ../templeos-gpt55 rev-parse HEAD
git -C ../holyc-gpt55 rev-parse HEAD
git -C ../holyc-gpt55 show HEAD:bench/qemu_prompt_bench.py
git -C ../holyc-gpt55 show HEAD:tests/test_qemu_prompt_bench.py
git -C ../holyc-gpt55 show HEAD:bench/airgap_audit.py
git -C ../holyc-gpt55 show HEAD:bench/qemu_source_audit.py
git -C ../templeos-gpt55 show HEAD:automation/qemu-airgap-report.py
git -C ../templeos-gpt55 show HEAD:automation/qemu-command-manifest.py
git -C ../holyc-gpt55 grep -n 'readonly=on' HEAD -- bench tests
git -C ../templeos-gpt55 grep -n 'readonly=on' HEAD -- automation MODERNIZATION .github Makefile
```

No TempleOS or holyc-inference files were modified. No networking task or QEMU/VM command was executed.
