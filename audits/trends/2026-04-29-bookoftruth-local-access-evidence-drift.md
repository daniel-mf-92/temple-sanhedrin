# temple-central.db Book of Truth Local-Access Evidence Drift

Audit timestamp: 2026-04-29T06:11:17Z

Audit angle: historical drift trends. This pass queried `temple-central.db` read-only for Book-of-Truth local-access, export, remote, USB, streaming, and forwarding evidence, then spot-checked current TempleOS and holyc-inference source paths without modifying either builder repo.

## Scope

- Database: `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`
- Builder repos checked read-only:
  - `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS`
  - `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`
- Query pack: `audits/trends/2026-04-29-bookoftruth-local-access-evidence-drift.sql`
- LAWS.md focus: Law 11 Book of Truth Local Access Only, with secondary Law 3 serial-output preservation context.

## Findings

1. WARNING - Historical scanners conflate HolyC `extern` exposure with forbidden Book-of-Truth log export.
   - Evidence: modernization has 93 Book-of-Truth rows containing export/dump/copy/USB/remote/stream/proxy/forward terms. Of those, 72 are `exported extern`, `extern export`, `export in Kernel/KExts`, or similar CLI/API exposure wording.
   - Impact: a naive Law 11 scanner will over-report violations because `exported extern` means exposing a local HolyC symbol in `Kernel/KExts.HC`, not exporting log contents off-machine.

2. WARNING - Remote compile/test evidence is mixed into Book-of-Truth local-access signals.
   - Evidence: 14 of the modernization Book-of-Truth access-term rows contain `remote`; samples are remote QEMU compile validations over SSH/SCP with `-nic none`, not guest log viewing or network export.
   - Impact: the central DB records host-side remote validation next to Book-of-Truth work but lacks a structured field distinguishing host compile transport from guest log access. This creates Law 11 ambiguity in long-window reports.

3. INFO - No current focused grep evidence of Book-of-Truth remote viewing, streaming, proxying, or USB export was found in core paths.
   - Evidence: focused TempleOS grep found Law 11 doctrine in `MODERNIZATION/MASTER_TASKS.md` and many local CLI/extern references, plus host-side SSH/SCP validation records in historical task notes. It did not find a current Book-of-Truth network API, stream/proxy path, or USB dump implementation in `Kernel/BookOfTruth.HC`, `Kernel/BookOfTruthSerialCore.HC`, or `Kernel/KExts.HC`.
   - Impact: this pass did not identify a Law 11 source violation. The primary finding is evidence-quality drift, not a builder source-code breach.

4. WARNING - The central DB has no first-class Law 11 classification for local-only serial capture.
   - Evidence: modernization has 646 serial rows and 1,466 Book-of-Truth rows, but the schema only stores free-text validation/notes. It cannot say whether a serial reference is local console capture, host fixture replay, remote compile output, or forbidden forwarding without prose parsing.
   - Impact: retroactive local-access audits remain brittle. A dedicated field for `bot_access_mode` would let Sanhedrin distinguish `local-console`, `local-serial-capture`, `fixture-replay`, `host-remote-compile`, and `forbidden-log-export`.

5. INFO - holyc-inference does not appear to carry Book-of-Truth local-access risk in the historical DB window.
   - Evidence: inference has 3 Book-of-Truth rows, 0 serial rows, and 0 Book-of-Truth access-term rows in `temple-central.db`. Current focused grep shows serial capture in `bench/qemu_prompt_bench.py` and `bench/README.md`, plus comments designed for Book-of-Truth export/offline replay in HolyC inference artifacts, but no Book-of-Truth log remote-viewing mechanism.
   - Impact: inference-side signals should still be audited when QEMU benchmark output is ingested, but this DB window does not show Law 11 drift.

## Supporting Extracts

| Agent | Rows | Book-of-Truth rows | Serial rows | Access-term rows | Book-of-Truth access rows | First timestamp | Last timestamp |
| --- | ---: | ---: | ---: | ---: | ---: | --- | --- |
| inference | 1,414 | 3 | 0 | 51 | 0 | 2026-04-12T13:53:13 | 2026-04-23T12:06:44 |
| modernization | 1,505 | 1,466 | 646 | 99 | 93 | 2026-04-12T13:51:32 | 2026-04-23T12:01:29 |
| sanhedrin | 11,687 | 110 | 27 | 5 | 0 | 1776539926 | 2026-04-23T11:54:59 |

Modernization Book-of-Truth access-term breakdown:

| Rows | Extern-export rows | Remote rows | USB rows | Forward/stream/proxy rows |
| ---: | ---: | ---: | ---: | ---: |
| 93 | 72 | 14 | 1 | 1 |

Daily modernization shape:

| Day | Book-of-Truth access rows | Serial mentions | Remote mentions | Export/dump mentions |
| --- | ---: | ---: | ---: | ---: |
| 2026-04-12 | 4 | 2 | 0 | 4 |
| 2026-04-13 | 8 | 2 | 0 | 8 |
| 2026-04-16 | 3 | 0 | 0 | 3 |
| 2026-04-17 | 22 | 5 | 0 | 22 |
| 2026-04-18 | 16 | 3 | 0 | 16 |
| 2026-04-19 | 11 | 7 | 8 | 4 |
| 2026-04-20 | 14 | 1 | 2 | 11 |
| 2026-04-21 | 9 | 1 | 3 | 5 |
| 2026-04-22 | 6 | 6 | 1 | 5 |

Representative rows needing semantic classification:

| Row | Timestamp | Task | Signal |
| ---: | --- | --- | --- |
| 87 | 2026-04-12T17:51:54 | CQ-117 | `BookOfTruthTail wrapper command with filter args + extern export` |
| 5985 | 2026-04-19T18:25:49 | CQ-603 | `remote QEMU compile pass with -nic none` |
| 6228 | 2026-04-19T20:57:18 | CQ-628 | `remote QEMU compile passed with air-gap flag enforcement` |
| 11373 | 2026-04-21T18:08:37 | CQ-988 | `-nic none preserved; queue depth 38 unchecked` |
| 13472 | 2026-04-22T04:10:29 | CQ-1144/CQ-1145 | `remote TempleOS compile under -nic none policy` |

## Commands

```text
sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-29-bookoftruth-local-access-evidence-drift.sql
rg -n -i '\b(remote|stream|proxy|forward|forwarding|ssh|scp|http|https|usb|export|dump to|print-to-file|copy to)\b' Kernel/BookOfTruth.HC Kernel/BookOfTruthSerialCore.HC Kernel/KExts.HC automation MODERNIZATION/MASTER_TASKS.md MODERNIZATION/BOOK_OF_TRUTH.md MODERNIZATION/LOOP_PROMPT.md
rg -n -i '\b(remote|stream|proxy|forward|forwarding|ssh|scp|http|https|usb|export|dump to|print-to-file|copy to|serial)\b' src bench automation README.md LOOP_PROMPT.md
```

## Recommendations

- Add structured central-DB fields for `bot_access_mode`, `bot_serial_scope`, `host_validation_transport`, and `law11_export_risk`.
- Teach Law 11 scanners to ignore `extern export` unless paired with file/USB/network/remote log-content transfer semantics.
- Keep host-side SSH/SCP validation distinct from guest capability analysis; remote host compile evidence is not the same as remote Book-of-Truth viewing.
- Preserve the current hard boundary: no Book-of-Truth network API, USB dump, print-to-file export, stream, proxy, or forwarded serial path.

Finding count: 5 total, 3 warnings and 2 info.
