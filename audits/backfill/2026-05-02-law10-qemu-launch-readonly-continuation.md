# Law 10 QEMU Launch Readonly Continuation Backfill

Timestamp: 2026-05-02T00:10:37+02:00

Audit angle: compliance backfill report. This pass continued the Law 10 immutable OS image audit with a stricter scan of executable TempleOS QEMU launch surfaces in `automation/` and `.github/`, excluding policy-only `MODERNIZATION/` prose from readonly scoring. It did not inspect live liveness, restart processes, run QEMU or any VM command, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

Evidence snapshots:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `9f3abbf26398`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554`
- Sanhedrin audit repo: `/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55` at `1e910464fa40`

Applicable rule: Law 10 says QEMU launch commands must use `-drive readonly=on` for the OS image. The backfill question was whether historical executable launch surfaces preserved that immutable-image evidence, independently from Law 2 air-gap evidence.

## Summary

The stricter executable-surface backfill found persistent Law 10 evidence failure. Since 2026-04-01, 77 TempleOS commits changed QEMU-related executable launch surfaces under `automation/` or `.github/`. Of those, 76 commits contained launch files with `-drive`, `-cdrom`, `qemu_args` drive construction, or raw image attachment patterns. Zero of those 76 commits had `readonly=on` in the executable launch files. The current head still has the same class in `automation/qemu-headless.sh`, `automation/qemu-smoke.sh`, `automation/qemu-compile-test.sh`, `automation/qemu-holyc-load-test.sh`, and `automation/north-star-e2e.sh`.

Findings: 5 total.

## Findings

### CRITICAL-1: Executable QEMU launch history has 0/76 readonly coverage

Evidence:
- Commits scanned with QEMU executable-surface changes: 77.
- Commits with drive/CD-ROM launch files: 76.
- Commits with `readonly=on` in those launch files: 0.
- Commits with launch files missing readonly evidence: 76.

Impact: prior backfills counted policy prose that mentioned `readonly=on`; this pass separated executable launch files from prose. The executable historical record does not show Law 10 enforcement for QEMU OS-image immutability.

### CRITICAL-2: Current canonical launcher files still attach mutable image surfaces

Evidence:
- Current launchers with drive or CD-ROM construction and no executable `readonly=on`: `automation/qemu-headless.sh`, `automation/qemu-smoke.sh`, `automation/qemu-compile-test.sh`, `automation/qemu-holyc-load-test.sh`, and `automation/north-star-e2e.sh`.
- Current `qemu-headless.sh` and `qemu-smoke.sh` append `-drive file=$DISK_IMAGE,format=raw,if=ide` when `DISK_IMAGE` is set.
- Current `qemu-compile-test.sh` attaches `shared.img` as a writable raw IDE drive while booting the ISO.

Impact: the present launcher contract still permits mutable disk images. If `DISK_IMAGE` is an installed OS image, the launch path violates the Law 10 requirement unless the launcher distinguishes read-only OS image drives from explicitly writable scratch/shared drives.

### WARNING-3: Air-gap checks are materially stronger than readonly checks

Evidence:
- In the 77 scanned commits, the executable-surface scan found air-gap evidence gaps in 50 commits, but readonly evidence was absent in all 76 drive-launch commits.
- Current launchers preserve `-nic none` / `-net none` logic, while none of the executable launch files include `readonly=on`.

Impact: Law 2 controls have been repeatedly represented and tested, while Law 10 readonly controls remain outside the executable gate vocabulary. A QEMU safety report can therefore pass air-gap checks while missing immutable-image enforcement.

### WARNING-4: Policy-only readonly mentions can mask launcher noncompliance

Evidence:
- A broader search including `MODERNIZATION/` prose finds `readonly=on` policy/task text, but the executable-only scan finds zero readonly launch-file hits.
- The older Law 10 backfills already identified policy examples and generated reports as insufficient; this continuation confirms the executable gap remained through current head.

Impact: future audits should not score `readonly=on` as compliant unless it appears in the actual launch command path or a manifest derived from that path. Prose-only evidence is useful policy context, not enforcement.

### INFO-5: The backfill can be reproduced without VM execution

Evidence:
- The scan used `git log`, `git grep`, and `git show` only.
- No QEMU binary was invoked and no VM command was executed.
- The audit did not touch TempleOS or holyc-inference source files.

Impact: this check is safe to run as a historical Sanhedrin gate and can be promoted into a recurring read-only audit without affecting the TempleOS guest or the trinity source repos.

## Key Aggregates

| Metric | Count |
| --- | ---: |
| TempleOS commits since 2026-04-01 | 2,430 |
| QEMU executable-surface commits scanned | 77 |
| Commits with drive/CD-ROM launch files | 76 |
| Commits with executable `readonly=on` evidence | 0 |
| Commits missing executable readonly evidence | 76 |
| Maximum missing launch files in one commit | 10 |

| Date | Missing-readonly launch commits |
| --- | ---: |
| 2026-04-11 | 1 |
| 2026-04-12 | 4 |
| 2026-04-17 | 1 |
| 2026-04-22 | 3 |
| 2026-04-23 | 1 |
| 2026-04-24 | 2 |
| 2026-04-26 | 1 |
| 2026-04-27 | 12 |
| 2026-04-28 | 23 |
| 2026-04-29 | 14 |
| 2026-04-30 | 7 |
| 2026-05-01 | 7 |

## Recommended Closure Criteria

- Split QEMU image semantics into read-only OS image drives and explicitly writable scratch/shared drives.
- Require `readonly=on` on any QEMU `-drive` that can contain the installed TempleOS OS image.
- Extend QEMU manifest/report gates to classify `os_image_drive_lines`, `scratch_drive_lines`, and `os_image_missing_readonly_count`.
- Treat prose-only `readonly=on` mentions as policy evidence, not executable compliance.

## Read-Only Verification Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-list --all --since='2026-04-01' --count
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS log --all --since='2026-04-01' --pretty=format:'%H' -G 'qemu-system|qemu_args|\-drive|\-cdrom|readonly=on' -- automation .github | sort -u | wc -l
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS grep -n -E 'qemu-system|qemu_args|-drive|-cdrom|readonly=on|-nic none|-net none' HEAD -- automation .github
```

Finding count: 5 total, 2 critical, 2 warnings, 1 info.
