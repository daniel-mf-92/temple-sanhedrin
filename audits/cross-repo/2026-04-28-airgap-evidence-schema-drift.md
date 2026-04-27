# Cross-Repo Invariant Audit: Air-Gap Evidence Schema Drift

Timestamp: 2026-04-27T23:40:54Z

Auditor: gpt-5.5 sibling, retroactive/deep audit scope

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source code was modified, and no VM/QEMU command was executed.

Repos examined:
- TempleOS committed HEAD: `ca1c313a05a6b784650ae8d7b8d2e71fd574f44c`
- holyc-inference committed HEAD: `4981d42b1a529414bc34b19b4340cab98180c00f`
- temple-sanhedrin committed baseline: `7fef069d73f8b3ceebc3626d3f46fc83b8c439cb`
- temple-sanhedrin branch: `codex/sanhedrin-gpt55-audit`

Working tree note:
- The holyc-inference worktree had pre-existing uncommitted changes in `bench/README.md` and `bench/qemu_prompt_bench.py`. They were not edited. This audit used committed HEAD identity plus read-only current-report artifacts.

## Executive Summary

Found 4 findings: 3 warnings, 1 info.

Both repos currently publish green air-gap evidence, and the reviewed TempleOS launch evidence explicitly preserves `-nic none` / `-net none` air-gap policy. The drift is that the two green reports do not mean the same thing. TempleOS scans committed automation launch surfaces and retains file/line evidence rows. holyc-inference scans benchmark result artifacts for recorded commands and reports only aggregate counts when clean. This makes cross-repo Sanhedrin review weaker than it looks: a combined "air-gap pass" cannot currently answer which exact holyc benchmark commands were checked, whether the check covered source launch scripts, or whether the accepted no-network dialect matches LAWS.md and TempleOS fallback policy.

## Finding WARNING-001: holyc-inference green air-gap report is not replayable from the committed report alone

Applicable laws:
- Law 2: Air-Gap Sanctity
- Law 5: North Star Discipline, because green gates should produce evidence that Sanhedrin can independently review

Evidence:
- `holyc-inference/bench/results/airgap_audit_latest.md:3-8` reports `Status: pass`, `QEMU commands checked: 168`, `Findings: 0`, and the sentence "All recorded QEMU commands explicitly disable networking with `-nic none`."
- `holyc-inference/bench/airgap_audit.py:202-220` renders command rows only when findings exist; clean reports contain no table of checked command sources.
- `holyc-inference/bench/airgap_audit.py:182-199` counts QEMU-like commands while scanning JSON/JSONL benchmark artifacts, but the clean JSON report stores only `commands_checked`, `findings`, `generated_at`, and `status`.

Assessment:
The current artifact can prove that the checker saw 168 QEMU-like commands and found no violations at generation time. It cannot prove, from the report alone, which command rows were checked or whether a later artifact rewrite changed the underlying command corpus.

Risk:
Sanhedrin can over-trust an aggregate "pass" while losing the ability to do retroactive command-by-command air-gap review after benchmark artifacts rotate or are regenerated.

Required remediation:
- Add a redacted pass-evidence table or JSON array containing at least source path, row, command hash, and detected no-network dialect for every checked QEMU command.
- Keep full command text when it contains no secrets; otherwise store a stable hash plus normalized argument vector metadata.
- Include the audited input artifact set and its hashes in `airgap_audit_latest.json`.

## Finding WARNING-002: TempleOS and holyc-inference accept different no-network dialects

Applicable laws:
- Law 2: Air-Gap Sanctity

Evidence:
- `LAWS.md` and the user safety requirement allow QEMU commands with explicit `-nic none` or legacy fallback `-net none`.
- `TempleOS/automation/qemu-airgap-report.py:14-17` treats either `-nic none` or `-net none` as no-network evidence.
- `TempleOS/MODERNIZATION/lint-reports/qemu-airgap-report-latest.md:63-68` records `-nic none` as preferred and `-net none` as legacy fallback evidence in `automation/qemu-headless.sh`.
- `holyc-inference/bench/airgap_audit.py:64-70` recognizes only `-nic none` / `-nic=none` as satisfying the required no-network option.
- `holyc-inference/bench/airgap_audit.py:94-103` flags `-net none` and `-net=none` as findings with "use `-nic none` in benchmark artifacts."

Assessment:
This is a conservative holyc-inference benchmark policy, not an air-gap breach. The drift is semantic: a QEMU launch using legacy `-net none` is compliant under LAWS.md and TempleOS fallback policy but fails holyc-inference's benchmark artifact gate.

Risk:
Future cross-repo reports can disagree on the same launch line. That creates noise for historical audits and can cause a safe legacy fallback run to be classified as a holyc benchmark violation without being a Law 2 violation.

Required remediation:
- Label holyc-inference's stricter `-nic none` rule as a benchmark style policy, distinct from Law 2 minimum compliance.
- Add separate result fields such as `law2_compliant=true` and `preferred_dialect=true/false` for `-net none` fallback commands.
- Keep TempleOS and Sanhedrin summaries aligned on the canonical Law 2 wording.

## Finding WARNING-003: The two reports cover different surfaces under the same air-gap label

Applicable laws:
- Law 2: Air-Gap Sanctity
- Law 5: North Star Discipline

Evidence:
- `TempleOS/automation/qemu-airgap-report.py:99-124` discovers source-like launch surfaces under `automation`, `.github/workflows`, and `Makefile`.
- `TempleOS/MODERNIZATION/lint-reports/qemu-airgap-report-latest.md:3-10` reports 1,203 scanned files, 24 direct QEMU mentions, 32 no-network evidence lines, 17 runtime guard calls, 0 direct QEMU lines missing no-network evidence, and 0 forbidden network option lines.
- `holyc-inference/bench/airgap_audit.py:162-199` scans only JSON/JSONL input artifacts and checks a normalized `command` field.
- `holyc-inference/bench/results/airgap_audit_latest.md:3-8` reports 168 recorded benchmark commands checked and 0 findings, but no source launch script coverage.

Assessment:
TempleOS answers "do committed launch scripts and guards show explicit no-network policy?" holyc-inference answers "did recorded benchmark command artifacts include preferred no-network flags?" Both are useful, but they are not interchangeable.

Risk:
A holyc-inference source launch script could drift before benchmark artifacts are regenerated, while the latest benchmark audit stays green. Conversely, TempleOS can have source-level guard evidence without proving every historical run artifact used the expected final argv.

Required remediation:
- Add a cross-repo Sanhedrin schema with explicit coverage class: `source_static`, `runtime_guard`, `recorded_argv`, and `historical_artifact`.
- Require each green air-gap summary to declare which coverage classes were checked and which were not.
- Add a small manifest that maps holyc benchmark artifacts back to the script and commit that produced each recorded command.

## Finding INFO-001: Reviewed artifacts still show no current air-gap failure

Applicable laws:
- Law 2: Air-Gap Sanctity

Evidence:
- `TempleOS/MODERNIZATION/lint-reports/qemu-airgap-report-latest.md:9-10` reports 0 direct QEMU lines missing no-network evidence and 0 forbidden network option lines.
- `holyc-inference/bench/results/airgap_audit_latest.md:4-6` reports `Status: pass`, 168 commands checked, and 0 findings.
- No QEMU or VM command was executed during this audit.

Assessment:
This report flags evidence-shape drift, not a live air-gap breach. The safe interpretation is that both current air-gap gates are green within their own scopes, but Sanhedrin should not merge them into a single undifferentiated compliance signal.

## Non-Findings

- No TempleOS guest networking stack, NIC driver, socket, TCP/IP, UDP, TLS, DHCP, DNS, HTTP, or remote runtime service was found or executed by this audit.
- No WS8 networking task was executed.
- No TempleOS or holyc-inference source file was modified.
- No QEMU or VM command was run; therefore no VM launch arguments were needed beyond this report's read-only evidence review.

## Read-Only Verification Commands

- `git -C /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55 rev-parse HEAD`
- `git -C /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55 rev-parse HEAD`
- `git -C /Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55 rev-parse HEAD`
- `nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/airgap_audit.py | sed -n '1,220p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/qemu-airgap-report.py | sed -n '1,240p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/MODERNIZATION/lint-reports/qemu-airgap-report-latest.md | sed -n '1,120p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/results/airgap_audit_latest.md | sed -n '1,120p'`
- `jq '.commands_checked, .status, (.findings|length)' /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/results/airgap_audit_latest.json`
- `jq '.direct_qemu_lines_missing_airgap, .forbidden_network_options, .runtime_airgap_guards, .qemu_mentions' /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/MODERNIZATION/lint-reports/qemu-airgap-report-latest.json`
