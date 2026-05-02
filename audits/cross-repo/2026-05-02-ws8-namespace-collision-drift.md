# Cross-Repo Audit: WS8 Namespace Collision Drift

Timestamp: 2026-05-02T03:53:33+02:00

Scope: Cross-repo invariant check across TempleOS and holyc-inference. TempleOS and holyc-inference were read-only. No QEMU or VM command was executed. No live liveness watching, process restart, current-iteration compliance check, WS8 networking task, socket, NIC, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, package install, or remote fetch was executed.

Audited heads:
- TempleOS: `9f3abbf26398`
- holyc-inference: `2799283c9554`
- Sanhedrin audit branch: `84f398562ac2`

Relevant laws and audit rules:
- Law 2: TempleOS guest must remain air-gapped; WS8 networking tasks are frozen.
- Law 5 / North Star Discipline: audit work must surface concrete implementation risk, not bookkeeping.
- User hard safety requirement: do not execute WS8 networking tasks; record them as out-of-scope due to air-gap policy.

## Summary

The air-gap guard correctly freezes TempleOS WS8 because TempleOS defines WS8 as networking. The same unqualified "WS8 networking tasks" phrase is also injected into the holyc-inference loop, where WS8 is not networking at all: it is integration and polish, including Book-of-Truth token logging and TempleOS console streaming. That creates a cross-repo namespace collision. A literal or automated enforcement pass can either over-freeze valid inference WS8 work or, if it tries to special-case inference, lose the precise TempleOS networking prohibition.

Findings: 4 total; 0 CRITICAL, 4 WARNING.

## Evidence

TempleOS still carries a top-level networking north-star line:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:15`

TempleOS policy then correctly freezes its WS8 networking stream:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:123`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:124`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:125`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:126`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:127`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:128`

holyc-inference defines WS8 as non-networking integration work:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:112`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:113`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:115`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:116`

holyc-inference policy separately forbids networking and HTTP:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:20`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/LOOP_PROMPT.md:66`

But holyc-inference loop automation injects the same TempleOS-oriented guard text:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/codex-inference-loop.sh:30`

Sanhedrin law text also scopes the frozen WS8 rule to "WS8 networking tasks" rather than repo-qualified task IDs:
- `/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55/LAWS.md:34`

Recent completed inference queue items prove that valid inference work is already tagged to `WS8-03`:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:3916`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:3917`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:3918`

## Findings

### WARNING 1. The same WS8 identifier means opposite things in the two builder repos

In TempleOS, `WS8` is networking and is frozen. In holyc-inference, `WS8` is integration/polish and includes Book-of-Truth token hooks, console streaming, and performance tuning. The law text and loop guard say "WS8 networking tasks", but the branch-local task IDs are not namespace-qualified.

Impact: Sanhedrin, builder prompts, or simple regex audits can misclassify inference `WS8-03` Book-of-Truth work as forbidden networking work even though it is directly on the trusted local inference path.

Recommended closure: qualify the frozen stream as `TempleOS/MODERNIZATION WS8 networking` or `TempleOS WS8-*` in Sanhedrin and loop guard text. Separately state that holyc-inference WS8 remains allowed when it preserves disk-only, no-HTTP, no-network execution.

### WARNING 2. Inference loop automation imports a TempleOS-specific WS8 guard without a repo disambiguator

`holyc-inference/automation/codex-inference-loop.sh` injects the hard safety text that says "Do not execute WS8 networking tasks". The same prompt also tells the inference loop to pick queue items from `MASTER_TASKS.md`, where unchecked WS8 items are valid inference tasks.

Impact: the inference loop can be pulled in two directions: advance its own WS8 integration work, or treat WS8 as frozen because the guard does not name the TempleOS repo. This is an avoidable source of skipped Book-of-Truth integration and noisy "out-of-scope" records.

Recommended closure: change the inference loop guard wording to "Do not execute TempleOS/MODERNIZATION WS8 networking tasks; holyc-inference WS8 integration tasks are allowed only if they remain disk-only and no-network."

### WARNING 3. TempleOS top-level networking north-star still amplifies the collision

TempleOS `MASTER_TASKS.md` still lists "Network stack (IPv4/IPv6, TCP/UDP, TLS strategy)" in top-level north-star outcomes while the detailed WS8 section marks all networking tasks as won't-do under air-gap policy.

Impact: an automated cross-repo planner that sees top-level north-star text plus unqualified WS8 guard text can simultaneously infer that networking is desired and forbidden. That weakens audit signal: the right invariant is "networking is a frozen non-goal until the air-gap policy is explicitly reversed."

Recommended closure: replace the top-level networking line with a frozen/non-goal note while Law 2 remains active, or attach an explicit "frozen by air-gap policy" suffix to the line.

### WARNING 4. Existing inference WS8 backfill can be scored as a false violation

Recent completed inference queue items are tagged `(WS8-03, WS16-06)` and implement Book-of-Truth token-event emit paths with secure-local gating and policy-digest checks. Those are exactly the kind of local audit hooks the trinity needs, but they match the same `WS8` token used by the frozen TempleOS networking workstream.

Impact: retroactive scoring that only keys on `WS8` can report false Law 2 violations for inference commits, hiding real air-gap concerns under false positives.

Recommended closure: update retro/backfill audit scripts and issue templates to classify by repo plus workstream title, not by `WS8` alone. For holyc-inference, require an additional networking token such as HTTP, socket, TCP, UDP, DNS, DHCP, TLS, downloader, remote service, or QEMU NIC before flagging Law 2.

## Commands Run

- `git status --short --branch` in Sanhedrin audit worktree.
- `git rev-parse --short=12 HEAD` in TempleOS, holyc-inference, and Sanhedrin audit worktree.
- `rg -n "WS8|networking stack|network stack|NIC|TCP|UDP|DNS|DHCP|HTTP|TLS|socket|OpenAI-compatible|serial-port accessible|no HTTP"` across TempleOS, holyc-inference, and Sanhedrin audit policy files.
- `nl -ba ... | sed -n ...` evidence reads for the cited files.

No source code in TempleOS or holyc-inference was modified.
