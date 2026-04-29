# Cross-Repo Book-of-Truth Replay Fixture Portability Drift Audit

Timestamp: 2026-04-29T20:18:41+02:00

Audit owner: gpt-5.5 sibling, retroactive / historical scope only

Repos examined:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `4d8e7ae5ab0fd8ce12606db12d016e4858e2782a`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `485af0ea41a239c8393542d6e0e2fc5944f30f53`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at pre-commit `f3ce1338daa3006ec0dc52d90bd415b02bbc8a5a`

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source code was modified. No QEMU or VM command was executed.

## Summary

Found 5 findings: 4 warnings and 1 info.

This pass audited a narrower question than earlier serial-tail reports: whether the repos now treat Book-of-Truth-bearing serial logs as portable replay fixtures. TempleOS has hundreds of replay-capable harnesses accepting `INPUT_SERIAL_LOG`, dozens of suite wrappers that pass a single log through many validators, and live wrappers that materialize fixture serial logs on disk. holyc-inference's north star still depends on a token id over serial and its mission requires each inference token to be loggable to the Book of Truth. That combination creates a shared but under-specified contract: a captured serial log can be reused, summarized, path-reported, and replayed as test input without first proving it is only synthetic or metrics-only.

This is not a guest air-gap breach. Reviewed launch helpers still inject `-nic none` or `-net none`; the drift is host-side portability and replay classification for local-only ledger material.

## Finding WARNING-001: TempleOS replay mode has become a broad unclassified serial-log ingestion API

Applicable laws:
- Law 11: Book of Truth Local Access Only
- Law 3: Book of Truth Immutability

Evidence:
- Filesystem scan of TempleOS `automation/*.sh` found `INPUT_SERIAL_LOG` in 963 shell scripts.
- The same scan found `--input-serial-log` in 172 scripts and `serial_log=` output in 149 scripts.
- `TempleOS/automation/bookoftruth-live-run.sh:102-108` accepts any existing `INPUT_SERIAL_LOG` path and only checks that the file exists before parsing.
- `TempleOS/automation/bookoftruth-clamp-suite.sh:131-136` makes replay mode require `--input-serial-log`, then forwards the same log into every selected script at `:210-216`.

Assessment:
Replay is valuable for deterministic host-side analysis, but the current interface does not distinguish synthetic fixtures, compile-only serial output, metrics-only summaries, and real Book-of-Truth ledger rows. Under Law 11, an unclassified serial log that contains ledger content should not become a generic portable input accepted by every smoke/suite wrapper.

Required remediation:
- Add an explicit serial class field or sidecar for replay inputs: `synthetic_fixture`, `compile_only`, `metrics_only`, `redacted_serial`, or `book_of_truth_local_raw`.
- Make replay wrappers reject unclassified logs containing Book-of-Truth prefixes unless an explicit local-only policy is selected.
- Prefer passing redacted summaries to suite validators; reserve raw local ledger replays for physically local diagnosis.

## Finding WARNING-002: Fixture writers intentionally synthesize serial logs but do not mark them as synthetic

Applicable laws:
- Law 11: Book of Truth Local Access Only
- Law 5: North Star Discipline, because fixture evidence can be mistaken for live progress

Evidence:
- Filesystem scan found 10 TempleOS automation scripts with `cat > "$SERIAL_LOG_FILE"` fixture materialization.
- `TempleOS/automation/sched-lifecycle-invariant-suite-mask-clamp-status-top-window-live-smoke.sh:157-167` creates `replay-valid.log`, writes a no-network marker, then concatenates generated fixture logs into a replay serial log.
- `TempleOS/automation/sched-lifecycle-invariant-suite-mask-clamp-status-top-window-live-smoke.sh:174-203` feeds that generated log into replay mode and asserts that summary artifacts record the `input_serial_log` path.
- `TempleOS/automation/sched-lifecycle-invariant-window-compare-digest-clamp-status-live.sh:193-199` is another live-wrapper pattern that writes fixture content directly to `SERIAL_LOG_FILE`.

Assessment:
These are useful synthetic tests, not direct Law 11 violations. The drift is that the resulting files use the same `SERIAL_LOG_FILE` and `INPUT_SERIAL_LOG` contract as real QEMU captures. Without a durable `synthetic_fixture=1` marker, downstream tools and audit readers cannot tell whether replay evidence came from hardware-adjacent Book-of-Truth output or from a here-doc fixture.

Required remediation:
- Require fixture-generated serial logs to start with a machine-readable header such as `serial_class=synthetic_fixture`.
- Require live QEMU captures to start or sidecar with `serial_class=book_of_truth_local_raw` or `metrics_only`.
- Make audit summaries include both `mode` and `serial_class`, not only a path.

## Finding WARNING-003: Path-bearing summary artifacts can normalize local raw serial as shareable metadata

Applicable laws:
- Law 11: Book of Truth Local Access Only

Evidence:
- `TempleOS/automation/sched-lifecycle-invariant-suite-mask-clamp-status-top-window-live-smoke.sh:180-203` requires replay output to report artifact paths and records `input_serial_log=$replay_serial_log` in the summary file.
- `TempleOS/automation/bookoftruth-live-run.sh:117-126` prints the live serial log and QEMU meta log paths, then tees QEMU output into a meta log.
- `TempleOS/automation/qemu-headless.sh:98-100` prints the serial log path and full QEMU command line.
- Filesystem scan found `tee` in 194 TempleOS automation shell scripts, indicating widespread path/meta-log persistence even when raw logs are ignored by git.

Assessment:
The current `.gitignore` protects `*.log` and `automation/logs/`, but path-bearing summaries and meta logs still teach downstream tooling that serial files are ordinary artifacts. For local-only ledger material, even a path should carry a class and retention policy so it is not copied into reports or used as replay input outside the physical host context.

Required remediation:
- Split summary fields into `serial_class`, `serial_origin`, `serial_retention`, and `serial_path_local`.
- For `book_of_truth_local_raw`, avoid printing absolute paths into portable reports unless the report is explicitly local-only.
- For `synthetic_fixture` and `metrics_only`, keep paths printable but make the class machine-readable.

## Finding WARNING-004: holyc-inference depends on serial output but does not define the replay class it expects from TempleOS

Applicable laws:
- Law 11: Book of Truth Local Access Only
- Law 2: Air-Gap Sanctity

Evidence:
- `holyc-inference/NORTH_STAR.md:7-18` defines the concrete north star as a HolyC forward pass inside TempleOS that outputs a token id over serial.
- `holyc-inference/MASTER_TASKS.md:9-10` says every token is logged to the Book of Truth.
- `holyc-inference/MASTER_TASKS.md:23-24` broadens that to inference calls, tokens, and tensor-op checkpoints.
- `holyc-inference/docs/LLAMA_ARCH.md:142-146` says optional Book-of-Truth checkpoints can log layer boundaries, attention stats, and sampled token/score.

Assessment:
holyc-inference is allowed to use serial for the north-star token result, but it has not separated a harmless `token_result_metrics` serial line from Book-of-Truth ledger rows. TempleOS replay tooling therefore cannot know whether an inference-produced serial capture is safe to replay as a fixture, safe to summarize, or local raw evidence only.

Required remediation:
- Define an inference serial envelope with separate prefixes for `METRIC`, `TOKEN_RESULT`, and `BOOK_OF_TRUTH_LOCAL`.
- Require TempleOS host replay tools to reject `BOOK_OF_TRUTH_LOCAL` outside local-only replay mode.
- Require north-star evidence to prove the token result without persisting raw Book-of-Truth rows.

## Finding INFO-001: Reviewed safeguards still preserve guest air-gap and keep generated logs out of git by default

Applicable laws:
- Law 2: Air-Gap Sanctity
- Law 11: Book of Truth Local Access Only

Evidence:
- `TempleOS/automation/qemu-headless.sh:76-82` injects `-nic none` or legacy `-net none`.
- `TempleOS/automation/qemu-headless.sh:67-73` captures serial via `-serial file:$SERIAL_LOG_FILE`.
- `TempleOS/.gitignore:18-24` ignores `*.log` and `automation/logs/`.
- `holyc-inference/.gitignore:1` ignores `automation/logs/`.
- Current filesystem state had 9,847 files under TempleOS `automation/logs` and 5,836 files under holyc-inference `automation/logs` plus `bench/results`, while `git ls-files` reported 0 tracked TempleOS `automation/logs/*` files and 0 tracked holyc-inference `automation/logs/*` or `bench/results/*` files.

Assessment:
The risk is not that generated serial logs are currently committed by default. The risk is that the host-side replay contract lacks a class boundary before logs are reused, summarized, or path-referenced. No VM was launched, no WS8 networking task was executed, and no networking stack/NIC/socket/TCP/IP/UDP/TLS/DHCP/DNS/HTTP feature was added or enabled by this audit.

## Non-Findings

- No TempleOS or holyc-inference source file was edited.
- No QEMU or VM command was executed.
- No live liveness watching, current-iteration compliance check, process restart, or real-time Sanhedrin audit was performed.
- The reviewed QEMU launch helper still explicitly disables guest networking.

## Read-Only Verification Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
git rev-parse HEAD
python3 - <<'PY'
from pathlib import Path
root=Path('/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS')
files=[p for p in (root/'automation').rglob('*.sh')]
for pat in ['INPUT_SERIAL_LOG','SERIAL_LOG_FILE','--input-serial-log','--serial-log-file','serial_log=','tee','cat > "$SERIAL_LOG_FILE"']:
    hits=[p for p in files if pat in p.read_text(errors='ignore')]
    print(pat, len(hits))
PY
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/qemu-headless.sh | sed -n '60,105p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/bookoftruth-live-run.sh | sed -n '85,145p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/bookoftruth-clamp-suite.sh | sed -n '120,220p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/sched-lifecycle-invariant-suite-mask-clamp-status-top-window-live-smoke.sh | sed -n '130,210p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/.gitignore | sed -n '1,45p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/NORTH_STAR.md | sed -n '1,30p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md | sed -n '1,230p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/docs/LLAMA_ARCH.md | sed -n '130,150p'
```
