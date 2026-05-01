# Cross-Repo QEMU Readonly/Air-Gap Contract Drift Audit

Timestamp: 2026-05-01T11:15:23+02:00

Scope: historical/current cross-repo invariant check across `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` and `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`.

TempleOS head inspected: `a070ae63` (`codex/modernization-loop`)

holyc-inference head inspected: `2799283c` (`main`)

No QEMU, VM, network, or live liveness command was executed. This was a read-only source audit against committed host automation and benchmark surfaces.

## Invariant Under Audit

LAWS.md requires:

- Law 2: any QEMU/VM command must explicitly disable networking with `-nic none` or `-net none`, and network-dependent package managers/build steps are violations.
- Law 10: QEMU launch commands must include `-drive readonly=on` for the OS image.

The cross-repo invariant is stricter than either repo alone: every TempleOS guest launch surface, including holyc-inference benchmark launches that boot TempleOS images, must simultaneously prove `no NIC` and `readonly OS image`.

## Findings

### CRITICAL 1. TempleOS headless runner disables NIC but does not mark the disk image readonly

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/qemu-headless.sh:76` chooses `-nic none` when supported.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/qemu-headless.sh:84` appends `-drive file=$DISK_IMAGE,format=raw,if=ide`.
- No `readonly=on` appears in that `DISK_IMAGE` drive argument.

Impact: Law 2 air-gap evidence exists, but Law 10 immutable OS image evidence is absent for the main reusable headless runner. Any caller that supplies an installed TempleOS disk image boots it writable unless QEMU defaults or external flags happen to prevent writes.

### CRITICAL 2. TempleOS smoke runner has the same no-network/readonly split

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/qemu-smoke.sh:69` appends `-nic none`, with `-net none` fallback at line 72.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/qemu-smoke.sh:75` appends `-drive file=$DISK_IMAGE,format=raw,if=ide`.
- No `readonly=on` appears in that smoke runner drive argument.

Impact: the repo's quick validation path proves air-gap but not immutable-image semantics. This lets validation pass while still exercising a mutable installed OS disk.

### CRITICAL 3. holyc-inference QEMU prompt benchmark boots a writable TempleOS image by construction

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py:146` builds the QEMU command.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py:150` hard-codes `-nic none`.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py:156` emits `-drive file={image},format=raw,if=ide`.
- No `readonly=on` is included in the image drive argument.

Impact: holyc-inference now has an independent TempleOS guest launch surface that satisfies Law 2 but violates the Law 10 QEMU-image contract. This is cross-repo drift because inference benchmarking assumes it can boot the TempleOS image, while TempleOS policy requires the installed OS image to be immutable.

### WARNING 4. holyc-inference tests encode the missing-readonly command as the expected contract

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_qemu_prompt_bench.py:19` tests the QEMU command builder.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_qemu_prompt_bench.py:23` asserts the air-gap prefix.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_qemu_prompt_bench.py:32` asserts `file={image},format=raw,if=ide` is present, with no assertion for `readonly=on`.

Impact: the test suite will preserve the drift unless updated. This is not a runtime breach by itself, but it hardens a command shape that is incomplete under Law 10.

### CRITICAL 5. TempleOS compile QEMU helper still contains a network-dependent ISO acquisition path

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/qemu-compile-test.sh:13` defines `ISO_URL=https://templeos.org/Downloads/TempleOS.ISO`.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/qemu-compile-test.sh:23` enters "Download ISO if missing".
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/qemu-compile-test.sh:26` invokes `curl -sL "$ISO_URL"`.
- The same QEMU launch later includes `-nic none` at line 71, so the guest remains air-gapped; the violation is the host-side network-dependent validation path.

Impact: the script can silently rely on network availability for a validation artifact. Under the hard safety requirement and Law 2's "network-dependent package managers or build steps" prohibition, validation should fail closed with an explicit missing-local-ISO message instead of attempting a remote fetch.

## Healthy Observations

- TempleOS `qemu-headless.sh`, `qemu-smoke.sh`, and `qemu-compile-test.sh` all include explicit no-network flags for the guest launch paths inspected.
- holyc-inference `qemu_prompt_bench.py` rejects user-supplied network QEMU args and hard-codes `-nic none`.
- No evidence of TCP/IP, UDP, DNS, DHCP, HTTP, TLS, socket, NIC-driver, or WS8 guest implementation work was found in the inspected launch/benchmark surfaces.

## Recommended Remediation

- Add `readonly=on` to every QEMU OS image drive argument that boots an installed TempleOS disk.
- Preserve writeable scratch/shared disks only when they are clearly separate from the OS image and named as non-OS data media.
- Replace the `curl` fallback in `qemu-compile-test.sh` with a local-only preflight error.
- Update holyc-inference's QEMU benchmark test to require `readonly=on` in the `--image` drive string.

Finding count: 5
