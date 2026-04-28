# Cross-Repo Invariant Audit: Immutable Image Benchmark Provenance Drift

- Audit angle: cross-repo invariant checks
- Audit time: `2026-04-28T17:17:42+02:00`
- Auditor: gpt-5.5 sibling, retroactive/deep audit scope
- TempleOS HEAD: `a5322e8d3a189f6588ddae3f70809330d799fc1a`
- holyc-inference HEAD: `ff0cb4429e891749c7c45a855b0cd16995a04f1d`
- temple-sanhedrin baseline: `a0c6a0f1955cd138f9c27609030dcb99b5e555ae`

Safety posture: read-only against TempleOS and holyc-inference. No QEMU/VM command was run. No networking task or WS8 task was executed. The holyc-inference worktree had pre-existing uncommitted benchmark-result edits; this audit did not modify them.

## Summary

Found 5 findings: 5 warnings, 0 critical violations.

The cross-repo invariant under review was: if holyc-inference publishes TempleOS QEMU benchmark evidence, the artifact should prove the guest stayed air-gapped and the TempleOS OS image was a sealed/read-only artifact matching a known TempleOS revision or image hash.

Current evidence proves the first half better than the second. holyc-inference injects `-nic none`, records command hashes, and reports benchmark pass/fail. It does not record or gate `readonly=on`, TempleOS image hash, TempleOS commit/image build identity, or a split between immutable OS image and writable user/model data. TempleOS policy explicitly says QEMU should use `-drive readonly=on` for the OS image, but its own QEMU evidence manifest and current headless runner still focus on air-gap/headless/serial/timeout/teardown rather than immutable-image gating.

## Finding WARNING-001: holyc-inference benchmark runner mounts the selected guest image writable by default

Applicable laws:
- Law 10: Immutable OS Image
- Law 2: Air-Gap Sanctity, by adjacency because the same QEMU command is treated as compliance evidence

Evidence:
- `holyc-inference/bench/qemu_prompt_bench.py:323-337` builds every benchmark command with `-nic none`, `-serial stdio`, `-display none`, and `-drive file=<image>,format=raw,if=ide`.
- The generated drive option does not include `readonly=on`, `snapshot=on`, or an equivalent write-protect mode.
- `holyc-inference/bench/README.md:238-247` documents the runner as an air-gapped QEMU guest launcher and says extra QEMU options are passed through the same air-gap network rejection path.
- `holyc-inference/bench/README.md:327-348` shows the normal benchmark usage with `--image path/to/TempleOS.img`, which means the runner is intended to launch a TempleOS image, not only synthetic fixtures.

Assessment:
The runner can produce an air-gap-clean command that still violates the immutable-image contract if `--image` points at the OS image. The benchmark command builder has no concept of "OS image must be readonly, writable data/model disk must be separate."

Required remediation:
- Add `readonly=on` to the OS-image drive by default.
- If benchmarks need writable state, add a separate explicit writable disk argument with its own artifact/provenance label.
- Reject `--qemu-arg` or matrix args that override the OS drive into writable mode.

## Finding WARNING-002: latest holyc benchmark matrix artifacts pass without recording immutable-image evidence

Applicable laws:
- Law 10: Immutable OS Image
- Law 5: North Star Discipline

Evidence:
- `holyc-inference/bench/results/bench_matrix_latest.json:4-18` records a passing QEMU-like command using `-nic none`, `-serial stdio`, `-display none`, and `-drive file=/tmp/TempleOS.synthetic.img,format=raw,if=ide`.
- `holyc-inference/bench/results/bench_matrix_latest.json:92-101` records matrix status, generation time, matrix file, and variability gates, but no image SHA256, readonly flag, TempleOS commit, TempleOS artifact ID, or OS/data partition distinction.
- `holyc-inference/bench/results/bench_matrix_latest.md:11-14` reports commit, prompt suite, command hash, throughput, host overhead, and memory, but does not expose image identity or read-only status.

Assessment:
The artifact can prove "this command vector was air-gapped and benchmarked," but not "this benchmark ran against a sealed TempleOS image." A command hash is not enough because reviewers cannot classify which command component is the immutable OS image, whether it was write-protected, or which TempleOS revision it represents.

Required remediation:
- Add artifact fields: `templeos_image_sha256`, `templeos_image_readonly`, `templeos_source_commit`, `os_drive_index`, and `writable_data_drive_indices`.
- Fail benchmark reports when the OS image is not read-only unless the matrix is explicitly marked `synthetic_no_templeos_guest=true`.
- Surface those fields in Markdown and JUnit properties so Sanhedrin can audit them without parsing raw command arrays.

## Finding WARNING-003: synthetic benchmark image naming can be mistaken for TempleOS image compliance

Applicable laws:
- Law 5: North Star Discipline
- Law 10: Immutable OS Image

Evidence:
- `holyc-inference/bench/fixtures/bench_matrix_smoke.json:1-9` names the image `/tmp/TempleOS.synthetic.img` and uses `bench/fixtures/qemu_synthetic_bench.py` as the QEMU binary.
- `holyc-inference/bench/results/bench_matrix_latest.json:4-18` preserves the synthetic command in the same field shape used for real QEMU benchmark commands.
- `holyc-inference/bench/results/bench_matrix_latest.md:3-14` reports `Status: pass` for the synthetic smoke matrix without a field declaring that no real TempleOS guest image was exercised.

Assessment:
Synthetic smoke is useful, but the current artifact schema makes a synthetic runner and a real TempleOS QEMU command look too similar. Because the image path includes `TempleOS` but is a `/tmp` synthetic fixture, dashboards can accidentally treat it as evidence for real immutable-image benchmark coverage.

Required remediation:
- Add `runner_kind` with values such as `synthetic_fixture` and `qemu_system`.
- For synthetic runs, set `templeos_guest_exercised=false` and exclude them from immutable-image compliance scores.
- For real QEMU runs, require OS image digest and read-only proof before reporting the cell as release-gate evidence.

## Finding WARNING-004: TempleOS policy requires read-only QEMU OS images, but current launch evidence does not enforce it

Applicable laws:
- Law 10: Immutable OS Image

Evidence:
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:206-219` states that the OS image cannot be modified and explicitly says: on QEMU, use `-drive readonly=on` for the OS image and a separate writable disk for user data.
- `TempleOS/automation/qemu-headless.sh:70-89` builds the headless QEMU args with air-gap/headless/serial options, then adds `-drive file=$DISK_IMAGE,format=raw,if=ide` for `DISK_IMAGE`.
- `TempleOS/MODERNIZATION/lint-reports/qemu-command-manifest-latest.md:3-33` gates QEMU evidence on no-network, headless, serial, timeout, teardown, and forbidden network lines; it does not report any read-only drive metric.

Assessment:
This is not a new live VM finding because no QEMU command was executed. It is a cross-repo contract problem: holyc-inference cannot inherit a mature immutable-image QEMU evidence schema from TempleOS because TempleOS' own current QEMU report does not encode the read-only requirement either.

Required remediation:
- Extend the TempleOS QEMU manifest with OS-drive readonly counters and strict failures.
- Split `DISK_IMAGE` into `OS_IMAGE` and `DATA_IMAGE` semantics, with `OS_IMAGE` always `readonly=on`.
- Update north-star and loop examples so future benchmark/control-plane consumers copy a read-only OS image pattern.

## Finding WARNING-005: Sanhedrin cannot currently compare benchmark performance against a stable TempleOS image lineage

Applicable laws:
- Law 5: North Star Discipline
- Law 10: Immutable OS Image

Evidence:
- `holyc-inference/bench/qemu_prompt_bench.py:179-191` records only the current holyc-inference git commit via `git rev-parse --short=12 HEAD`.
- `holyc-inference/bench/qemu_prompt_bench.py:659-690` stores that commit, the prompt hash, command, and command hash per run.
- `holyc-inference/bench/bench_matrix.py:345-354` lifts the benchmark report commit and command hash into the matrix cell.
- No reviewed benchmark report field binds a performance row to a TempleOS commit, image digest, Book-of-Truth build state, or immutable OS image generation manifest.

Assessment:
Performance trends can drift because the inference commit is known but the TempleOS guest image lineage is opaque. A future throughput change could be caused by inference code, TempleOS scheduler changes, Book-of-Truth hooks, or an accidentally mutated image, and the current artifact schema cannot distinguish them.

Required remediation:
- Require a companion TempleOS image manifest for real guest benchmarks.
- Include `{templeos_commit, image_sha256, image_created_utc, immutable_os=true, readonly_drive=true}` in every real QEMU benchmark row.
- Make trend dashboards group by both holyc-inference commit and TempleOS image digest.

## Non-Findings

- No air-gap breach was found or induced by this audit.
- No networking stack, NIC driver, socket, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, or WS8 execution was observed in the audited paths.
- No TempleOS or holyc-inference source file was modified.
- No QEMU/VM command was run.

## Read-Only Verification Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55 log -1 --format='%H %cI %s'
git -C /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55 log -1 --format='%H %cI %s'
git -C /Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55 log -1 --format='%H %cI %s'
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/qemu_prompt_bench.py | sed -n '179,191p;323,337p;659,690p'
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/bench_matrix.py | sed -n '345,354p'
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/fixtures/bench_matrix_smoke.json | sed -n '1,40p'
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/results/bench_matrix_latest.json | sed -n '1,120p'
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/results/bench_matrix_latest.md | sed -n '1,80p'
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/MODERNIZATION/MASTER_TASKS.md | sed -n '206,224p'
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/qemu-headless.sh | sed -n '70,110p'
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/MODERNIZATION/lint-reports/qemu-command-manifest-latest.md | sed -n '1,40p'
```
