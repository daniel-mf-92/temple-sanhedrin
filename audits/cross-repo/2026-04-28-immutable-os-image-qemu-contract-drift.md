# Cross-Repo Immutable OS Image QEMU Contract Drift Audit

- Audit angle: cross-repo invariant checks
- Repos inspected: `TempleOS`, `holyc-inference`, `temple-sanhedrin`
- Audit time: `2026-04-28T04:29:19+02:00`
- Scope: read-only review of current QEMU launch surfaces, benchmark artifact auditing, and Law 10 immutable-image evidence. No TempleOS or holyc-inference files were modified, and no QEMU or VM command was executed.

## Summary

Both repos are strong on the Law 2 air-gap invariant: QEMU launchers and benchmark tooling inject or require `-nic none`, and benchmark artifacts are audited for network arguments. The Law 10 immutable OS image invariant is weaker and inconsistent.

TempleOS doctrine says a QEMU OS image must be launched with `-drive readonly=on`, with writable user data on a separate disk. Current TempleOS disk-image helpers and holyc-inference benchmark tooling still treat `TempleOS.img` as a writable `-drive file=...,format=raw,if=ide`. The result is a cross-repo proof gap: a benchmark or smoke run can be air-gapped and still mutate the OS image.

## Findings

### Finding CRITICAL-001: TempleOS disk-image QEMU helpers do not make `TempleOS.img` read-only

Laws implicated:
- Law 10: Immutable OS Image
- Law 2 remains protected by separate `-nic none` enforcement

Evidence:
- `LAWS.md:140-149` defines the immutable OS image rule and names QEMU launch commands missing `-drive readonly=on` for the OS image as violations.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:206-219` says the OS image cannot be modified after installation and says QEMU must use `-drive readonly=on` for the OS image with a separate writable disk for user data.
- `TempleOS/automation/qemu-headless.sh:28-30` documents `DISK_IMAGE=/absolute/path/to/TempleOS.img` as a required input option.
- `TempleOS/automation/qemu-headless.sh:87-88` launches that disk as `-drive "file=$DISK_IMAGE,format=raw,if=ide"` with no `readonly=on`.
- `TempleOS/automation/qemu-smoke.sh:26-28` documents the same `DISK_IMAGE=/absolute/path/to/TempleOS.img` mode.
- `TempleOS/automation/qemu-smoke.sh:78-79` also launches it as `-drive "file=$DISK_IMAGE,format=raw,if=ide"` with no `readonly=on`.

Impact:

These helpers are the modernization repo's generic boot/smoke surfaces. When `DISK_IMAGE` is a TempleOS OS image, the command line violates the current Law 10 launch contract even though it remains air-gapped. This can make Book-of-Truth and kernel-integrity evidence non-reproducible across repeated smoke runs because the OS disk is not protected from guest writes.

Recommendation:

Split the launch contract into explicit roles: `OS_IMAGE` must be mounted with `readonly=on`; `DATA_IMAGE` or `SHARED_IMG` may be writable. For backwards compatibility, either make `DISK_IMAGE` read-only by default or rename it so callers cannot accidentally treat an OS image as writable.

### Finding CRITICAL-002: holyc-inference benchmark runner boots the declared TempleOS image writable

Laws implicated:
- Law 10: Immutable OS Image
- Law 5: North Star Discipline, because benchmark evidence can be accepted from a mutable OS image

Evidence:
- `holyc-inference/bench/qemu_prompt_bench.py:251-265` builds the benchmark command with `-drive f"file={image},format=raw,if=ide"` and no `readonly=on`.
- `holyc-inference/bench/qemu_prompt_bench.py:960-963` exposes this as `--image`, described as the "TempleOS disk image to boot in QEMU".
- `holyc-inference/bench/README.md:229-239` and `bench/README.md:243-248` document examples using `--image path/to/TempleOS.img`.
- `holyc-inference/tests/test_qemu_prompt_bench.py:17-25` asserts the generated command includes `file={image},format=raw,if=ide`, but has no assertion for `readonly=on`.

Impact:

The inference repo's benchmark evidence can satisfy the local air-gap contract while booting a mutable TempleOS OS image. That drifts from TempleOS's role as the trust/control plane and from Law 10's requirement that installed OS changes require a full reinstall rather than in-place mutation.

Recommendation:

Teach `qemu_prompt_bench.py` to distinguish read-only OS images from writable payload/model disks. The default `--image` path should either become `--os-image` and include `readonly=on`, or the runner should require a separate `--data-image` for writable model/prompt payloads.

### Finding WARNING-001: Air-gap artifact audits can report pass on commands that fail the immutable-image contract

Laws implicated:
- Law 10: Immutable OS Image
- Law 2 is covered, but currently overshadows Law 10 in benchmark artifact checks

Evidence:
- `holyc-inference/bench/airgap_audit.py:60-80` treats commands with `qemu-system` or `-drive` as QEMU-like, then checks only for explicit `-nic none`.
- `holyc-inference/bench/airgap_audit.py:82-117` rejects non-air-gapped `-nic`, `-net`, `-netdev`, and network devices, but never checks whether a `TempleOS.img`/OS image drive contains `readonly=on`.
- `holyc-inference/tests/test_airgap_audit.py:17-54` uses a "safe" benchmark command with `-nic none` and `-drive file=TempleOS.img,format=raw,if=ide`; the test expects only the unsafe networked command to produce findings.
- `holyc-inference/tests/test_bench_result_index.py:18-54` indexes a `TempleOS.img` command with `-nic none` and no `readonly=on` as `command_airgap_status == "pass"`.

Impact:

An artifact can be green in holyc-inference dashboards while still failing the TempleOS immutable-image launch contract. The naming says "airgap", so this is not a bug in that narrow checker; it is a cross-repo evidence gap if Sanhedrin or release reports treat air-gap pass as sufficient QEMU safety proof.

Recommendation:

Add a separate immutable-image artifact audit rather than overloading the air-gap audit name. The new check should parse QEMU `-drive` arguments, classify likely OS images by role/path/argument name, and require `readonly=on` for OS image drives while permitting writable data/model drives.

### Finding WARNING-002: North-star documentation still shows a writable `shared.img` drive without explicitly separating it from the OS image role

Laws implicated:
- Law 10: Immutable OS Image

Evidence:
- `TempleOS/MODERNIZATION/NORTH_STAR.md:17-22` boots from `-cdrom TempleOS.ISO` and attaches `-drive file=shared.img,format=raw,if=ide`; because the OS source is an ISO, the writable drive can be interpreted as data-only and is not itself a Law 10 violation.
- `TempleOS/MODERNIZATION/LOOP_PROMPT.md:88-94` shows the same ISO plus `shared.img` workflow and says TempleOS can include files from the second drive at runtime.
- `holyc-inference/NORTH_STAR.md:15-20` says the Q4_0 GPT-2 weight blob lives on `shared.img`, but does not state that the OS image remains read-only and separate from that writable payload disk.

Impact:

The intended two-disk model exists in TempleOS doctrine but is not carried through the north-star examples. That ambiguity makes it easy for holyc-inference benchmark tooling to collapse "OS image to boot" and "writable payload disk" into one mutable `TempleOS.img` argument.

Recommendation:

Document the invariant in both north-star surfaces: OS image is read-only (`-cdrom` or `-drive ...,readonly=on`), and `shared.img`/model data is the only writable disk. This keeps Law 10 visible without weakening the existing air-gap requirement.

## Positive Observations

- `TempleOS/automation/qemu-headless.sh:79-85` and `TempleOS/automation/qemu-smoke.sh:70-76` still force `-nic none` or legacy `-net none`.
- `holyc-inference/bench/qemu_prompt_bench.py:251-265` injects `-nic none` before benchmark launches.
- `holyc-inference/bench/airgap_audit.py` is a useful Law 2 artifact gate; it simply does not cover Law 10.

## Safety Notes

- No TempleOS guest networking stack, NIC driver, socket, TCP/IP, UDP, TLS, DHCP, DNS, HTTP, or remote runtime service was added or enabled.
- No WS8 networking task was executed or recommended.
- No QEMU or VM command was executed. This audit only read committed files and reports.
- No TempleOS or holyc-inference source code was modified.

## Commands Run

Read-only commands only:

```bash
git -C ../templeos-gpt55 rev-parse HEAD
git -C ../holyc-gpt55 rev-parse HEAD
git rev-parse HEAD
rg -n --glob '*.sh' --glob '*.py' --glob '*.md' --glob '!MODERNIZATION/lint-reports/**' -- '-drive[^\n]*file=.*(TempleOS|DISK_IMAGE|SHARED_IMG|image|shared|\.img)' ../templeos-gpt55/automation ../templeos-gpt55/MODERNIZATION ../templeos-gpt55/README.md
rg -n 'readonly=on|read-only|immutable|OS image|image' ../holyc-gpt55/bench/README.md ../holyc-gpt55/bench/qemu_prompt_bench.py ../holyc-gpt55/bench/airgap_audit.py ../holyc-gpt55/bench/perf_ci_smoke.py ../holyc-gpt55/automation/north-star-e2e.sh ../holyc-gpt55/automation/*.sh ../holyc-gpt55/NORTH_STAR.md ../holyc-gpt55/LOOP_PROMPT.md
nl -ba LAWS.md | sed -n '80,150p'
nl -ba ../templeos-gpt55/MODERNIZATION/MASTER_TASKS.md | sed -n '205,224p'
nl -ba ../templeos-gpt55/automation/qemu-headless.sh | sed -n '1,130p'
nl -ba ../templeos-gpt55/automation/qemu-smoke.sh | sed -n '1,115p'
nl -ba ../holyc-gpt55/bench/qemu_prompt_bench.py | sed -n '251,265p'
nl -ba ../holyc-gpt55/bench/qemu_prompt_bench.py | sed -n '960,1035p'
nl -ba ../holyc-gpt55/bench/airgap_audit.py | sed -n '60,117p'
nl -ba ../holyc-gpt55/tests/test_airgap_audit.py | sed -n '1,130p'
nl -ba ../holyc-gpt55/tests/test_qemu_prompt_bench.py | sed -n '1,42p'
nl -ba ../holyc-gpt55/tests/test_bench_result_index.py | sed -n '16,58p'
```

Finding count: 4 total, 2 critical and 2 warnings.
