# Law 2 Network Source Surface Backfill

Timestamp: 2026-04-28T06:16:38+02:00

Audit owner: gpt-5.5 sibling, retroactive scope only

Repos examined:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`

Audit angle: compliance backfill for Law 2 network-source surfaces outside the already-covered QEMU flag and WS8 task audits.

No TempleOS or holyc-inference source was modified. No QEMU, VM, or live liveness command was executed.

## Scope

Checked historical and current evidence for:
- Guest networking stack or NIC implementation tokens in TempleOS core source paths.
- Host-side build or test commands that can reach the network as a runtime dependency.
- Dependency-manifest/package-ecosystem surfaces that could reintroduce network-dependent build steps.
- holyc-inference QEMU benchmark command construction, since it can launch a TempleOS guest image.

Excluded as non-violations:
- Static legacy TempleOS `.DD` documents containing `HTML="http://..."` metadata.
- Policy docs and harness tests that mention forbidden network flags as denylist evidence.
- `bridge` occurrences meaning software adapter/Book-of-Truth bridge or the Span game object, not VM tap/bridge networking.

## Summary

Backfill verdict: no current TempleOS guest networking implementation was found in scoped executable/core source. Current holyc-inference QEMU benchmark code rejects network QEMU args and injects `-nic none`.

Findings: 4 total, with 1 critical, 1 warning, and 2 informational findings.

## Findings

### CRITICAL: TempleOS compile harness still has a host-side remote ISO download path

Applicable rule: Law 2, network-dependent build steps are violations.

Evidence:
- `TempleOS/automation/qemu-compile-test.sh:13` defines `ISO_URL="https://templeos.org/Downloads/TempleOS.ISO"`.
- `TempleOS/automation/qemu-compile-test.sh:23-29` downloads the ISO with `curl -sL "$ISO_URL" -o "$ISO_FILE"` when the local ISO is absent.
- `git log --all --diff-filter=A -- automation/qemu-compile-test.sh` shows the harness was introduced in `d231ad137c7818f566ae8561194891ff5e2c0fb3` on 2026-04-12T15:54:08+02:00.
- The same current QEMU command uses `-nic none` at lines 67-73, so this is a host-side network dependency, not a guest NIC enablement.

Impact: Historical and current compile validation can depend on a remote HTTP/TLS fetch path. Even though the script skips QEMU on download failure, the success path still violates Law 2's ban on network-dependent build steps.

Required remediation: remove automatic download behavior, require a pre-provisioned local ISO path, and fail closed when the local artifact is missing.

### WARNING: TempleOS air-gap guard claims package-manifest enforcement but currently skips manifests

Applicable rule: Law 2, network-dependent package managers or build steps are violations.

Evidence:
- `TempleOS/automation/enforce-templeos-airgap.sh:15-20` defines `is_code_like` without package manifests such as `package.json`, `requirements.txt`, `pyproject.toml`, `Cargo.toml`, or `go.mod`.
- `TempleOS/automation/enforce-templeos-airgap.sh:34-36` continues early for non-code-like files.
- `TempleOS/automation/enforce-templeos-airgap.sh:38-41` contains a dependency-manifest violation check, but it is unreachable for the listed manifest filenames because of the earlier `continue`.
- `git log --all -S'Network-dependent package ecosystems' -- automation/enforce-templeos-airgap.sh` traces this guard text through `2ff2b0b4a52731b3fea927b2331d5b437eeaf195` and later `f81e6ee5b94111d00a67d1b56ec8dd114b5270cc`.
- Current `find` scans found no package manifests in the top three levels of either audited repo, so this is a guard coverage gap, not a present manifest violation.

Impact: A future package manifest could bypass the current guard despite the guard printing a policy for exactly that case.

Required remediation: move the manifest check before the `is_code_like` early continue or classify known package manifests as policy-scanned files.

### INFO: Current TempleOS scoped core source does not show guest networking implementation

Evidence:
- Current scoped search over `Kernel`, `Adam`, `Apps`, `Compiler`, `0000Boot`, `automation`, and `.github`, excluding logs/docs/static `.DD` files, found no executable guest TCP/UDP/DNS/DHCP/TLS/socket stack additions.
- Remaining executable matches were benign: `automation/codex-modernization-loop.sh` injects the hard no-network guard, and `automation/enforce-templeos-airgap.sh` scans for forbidden network tokens and QEMU network devices.
- Core source false positives were non-network uses of `Bridge`, such as `Kernel/Sched.HC` comments and `Apps/Span/SpanMain.HC` game text.

Impact: No current evidence of a TempleOS guest networking stack, NIC driver, or socket surface was found in this pass.

### INFO: Current holyc-inference QEMU benchmark rejects guest networking flags

Evidence:
- `holyc-inference/bench/qemu_prompt_bench.py:146-160` builds QEMU commands with `-nic none`.
- `holyc-inference/bench/qemu_prompt_bench.py:120-141` rejects non-`none` `-nic`/`-net`, `-netdev`, and common virtual NIC devices.
- `holyc-inference/tests/test_qemu_prompt_bench.py:36-51` exercises those forbidden args as rejection cases.
- `git log --all --diff-filter=A -- bench/qemu_prompt_bench.py tests/test_qemu_prompt_bench.py` shows the benchmark/test surface was introduced in `842e667a8fa4a152c96fd97d691dc49181609ca5` and `9e836f893b7f486cea81f4f609ca54ba4dee2d0b` on 2026-04-27.

Impact: The inference-side benchmark currently preserves Law 2's guest air-gap expectation for QEMU networking. Separate immutable-image concerns remain covered by the prior Law 10/QEMU contract audits.

## Backfill Score

- TempleOS guest networking implementation: PASS for current scoped source.
- TempleOS host build/test network dependency: FAIL, due to `automation/qemu-compile-test.sh` remote ISO download path.
- TempleOS package-ecosystem guard coverage: PARTIAL, due to unreachable manifest check.
- holyc-inference QEMU guest networking args: PASS for current benchmark command construction.

## Commands Run

```bash
rg -n -i '\b(socket|sockaddr|tcp|udp|dns|dhcp|tls|ethernet|e1000|rtl8139|virtio-net|netdev|hostfwd|tap|bridge|curl|wget|npm|pip|cargo|apt-get|brew install)\b' ...
git log --all -G'\b(socket|sockaddr|tcp|udp|dns|dhcp|tls|ethernet|e1000|rtl8139|virtio-net|netdev|hostfwd|tap|bridge|curl|wget|npm|pip|cargo|apt-get|brew install)\b' ...
git log --all --diff-filter=A -- automation/qemu-compile-test.sh
git log --all -S'curl -sL' -- automation/qemu-compile-test.sh
git log --all -S'Network-dependent package ecosystems' -- automation/enforce-templeos-airgap.sh
git log --all --diff-filter=A -- bench/qemu_prompt_bench.py tests/test_qemu_prompt_bench.py
find . -maxdepth 3 \( -name package.json -o -name package-lock.json -o -name requirements.txt -o -name pyproject.toml -o -name Cargo.toml -o -name go.mod -o -name yarn.lock -o -name pnpm-lock.yaml \) -print
nl -ba automation/qemu-compile-test.sh
nl -ba automation/enforce-templeos-airgap.sh
nl -ba bench/qemu_prompt_bench.py
nl -ba tests/test_qemu_prompt_bench.py
```
