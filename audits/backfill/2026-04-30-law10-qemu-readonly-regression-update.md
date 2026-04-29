# Law 10 QEMU Readonly Regression Update

Timestamp: 2026-04-30T00:29:44+02:00

Scope: retroactive compliance backfill update for Law 10 QEMU image immutability after the earlier 2026-04-27 and 2026-04-28 Law 10 reports. This audit was read-only against TempleOS, did not inspect live loop liveness, did not run QEMU or any VM command, did not execute WS8 networking tasks, and did not modify TempleOS or holyc-inference source code.

Repos referenced read-only:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `d84df3da3e8c241f43882f76493e1ae5a2f03b9e`
- Sanhedrin audit branch: `codex/sanhedrin-gpt55-audit`

Applicable rule: Law 10 requires QEMU launch commands to use `-drive readonly=on` for the OS image. Law 2 air-gap was also checked only to ensure this backfill did not mask a networking regression.

## Backfill Delta

Baseline: `audits/backfill/2026-04-28-law10-postrule-qemu-readonly-backfill.md` referenced TempleOS at `0a1df95f6ff5ebc9ce370db06adc1d4288a76f5f`.

Current delta:
- 41 first-parent TempleOS commits landed after that baseline through `d84df3da3e8c241f43882f76493e1ae5a2f03b9e`.
- 5 post-baseline commits touched the scoped QEMU/Law 10 command surfaces: `5f891583`, `6a6ee0bb`, `23b7a9cc`, `63780d21`, `4d8e7ae5`.
- Current executable/policy scan still found only 1 `readonly=on` occurrence, and it is policy text in `MODERNIZATION/MASTER_TASKS.md`, not executable launcher enforcement.
- Current scan found 7 `-drive file=...` command surfaces without `readonly=on`.
- Current scan found 138 shell files exposing `DISK_IMAGE` and 689 shell files referencing `automation/qemu-headless.sh`, so the mutable OS-image runner remains a high-fanout contract.

## Findings

### 1. CRITICAL: Direct OS-image runners still launch `DISK_IMAGE` without `readonly=on`

Evidence:
- `automation/qemu-headless.sh:84-85` appends `-drive "file=$DISK_IMAGE,format=raw,if=ide"`.
- `automation/qemu-smoke.sh:75-76` appends `-drive "file=$DISK_IMAGE,format=raw,if=ide"`.

Backfill assessment: this is the same executable Law 10 violation class reported on 2026-04-27 and 2026-04-28. The post-baseline history did not close it. Because many live wrappers delegate to `qemu-headless.sh`, the inherited mutable-image behavior persists across Book-of-Truth and scheduler live validation harnesses.

### 2. WARNING: Post-baseline commits touched QEMU command surfaces without adding readonly enforcement

Evidence:
- `git log 0a1df95f..d84df3da -- automation/qemu-headless.sh automation/qemu-smoke.sh automation/qemu-compile-test.sh automation/north-star-e2e.sh automation/qemu-holyc-load-test.sh MODERNIZATION/NORTH_STAR.md MODERNIZATION/LOOP_PROMPT.md` reports `5f891583`, `6a6ee0bb`, `23b7a9cc`, `63780d21`, and `4d8e7ae5`.
- Current `readonly=on` occurrence count remains 1, still non-executable policy text only.

Backfill assessment: these commits were chances to remediate or at least classify the Law 10 drive contract. They preserved air-gap evidence but did not add OS-image immutability evidence.

### 3. WARNING: Scratch-drive QEMU commands remain unclassified from OS-image drives

Evidence:
- `automation/qemu-compile-test.sh:67-71` boots an ISO and attaches `-drive file="$SHARED_DISK",format=raw,if=ide`.
- `automation/qemu-holyc-load-test.sh:120-124` boots an ISO and attaches `-drive file="$SHARED_IMG",format=raw,if=ide`.
- `automation/north-star-e2e.sh:101-114` boots an ISO and optionally attaches `-drive "file=$SHARED_IMG,format=raw,if=ide"`.
- `MODERNIZATION/NORTH_STAR.md:17` and `MODERNIZATION/LOOP_PROMPT.md:89` show QEMU examples with a writable `shared.img`.

Backfill assessment: these are probably writable scratch-media cases rather than OS-image drives, so this report does not mark them as direct Law 10 OS-image violations. The risk is that the command shape is indistinguishable to simple static checks and future agents from the mutable OS-image pattern. The remediation should classify drives explicitly: OS image drives require `readonly=on`; scratch drives require an explicit scratch variable/name and must not be documented as the installed image.

### 4. WARNING: Law 10 executable gates still appear absent

Evidence:
- Current scan found 7 `-drive file=...` surfaces without `readonly=on`.
- Current scan found no executable `readonly=on` in `automation/`, `.github/`, or launcher docs beyond the task text occurrence.

Backfill assessment: Law 2 gates are mature enough to preserve `-nic none`, but Law 10 has not been promoted to an equivalent executable/static gate. A future Sanhedrin pass can still see QEMU safety evidence and miss installed-image mutability.

### 5. INFO: Reviewed QEMU command surfaces preserved air-gap evidence

Evidence:
- `qemu-headless.sh`, `qemu-smoke.sh`, `qemu-compile-test.sh`, `qemu-holyc-load-test.sh`, `north-star-e2e.sh`, `NORTH_STAR.md`, and `LOOP_PROMPT.md` all include `-nic none` or explicit no-network fallback logic in the reviewed launch examples.

Backfill assessment: no Law 2 guest-network regression was found in this Law 10 pass. The open issue is image mutability and drive-role ambiguity, not networking.

## Compliance Score

- TempleOS direct OS-image QEMU readonly compliance: fail.
- Post-baseline regression closure: fail; 41 commits landed after the prior Law 10 baseline and the executable readonly gap remains open.
- Scratch-drive classification: warning; writable scratch media may be legitimate but is not clearly distinguished from OS-image drives.
- Air-gap preservation in reviewed QEMU surfaces: pass.
- Backfill result: 5 findings total, 1 critical, 3 warnings, 1 info.

## Read-Only Verification Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-list --count 0a1df95f6ff5ebc9ce370db06adc1d4288a76f5f..HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS log --oneline 0a1df95f6ff5ebc9ce370db06adc1d4288a76f5f..HEAD -- automation/qemu-headless.sh automation/qemu-smoke.sh automation/qemu-compile-test.sh automation/north-star-e2e.sh automation/qemu-holyc-load-test.sh MODERNIZATION/NORTH_STAR.md MODERNIZATION/LOOP_PROMPT.md
rg -n --hidden 'readonly=on' /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS
rg -n --hidden --glob '*.sh' --glob '*.py' --glob '*.md' -- '-drive[^\n]*file=|qemu_args\+=\(.*-drive' /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/.github /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION | rg -v 'readonly=on'
rg -l --glob '*.sh' 'DISK_IMAGE' /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation | wc -l
rg -l --glob '*.sh' 'qemu-headless\.sh' /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation | wc -l
```
