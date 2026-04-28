# temple-central.db Air-Gap Network Intent Drift

Audit timestamp: 2026-04-29T01:22:24+02:00

Audit angle: historical drift trends. This pass queried `temple-central.db` read-only for network-intent, no-network evidence, and WS8 references, then spot-checked current source paths in TempleOS and holyc-inference without modifying either builder repo.

## Scope

- Database: `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`
- Builder repos checked read-only:
  - `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS`
  - `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`
- Query pack: `audits/trends/2026-04-29-airgap-network-intent-drift.sql`
- LAWS.md focus: Law 2 air-gap sanctity, WS8 networking freeze, and historical observability for no-network evidence.

## Findings

1. INFO - No builder WS8 execution is recorded in `temple-central.db`.
   - Evidence: `iterations` has 0 modernization WS8 rows and 0 inference WS8 rows. All 384 WS8 rows belong to Sanhedrin audit/VM-compile notes, with the repeated wording that hard air-gap policy was preserved and WS8 was not executed.
   - Impact: the pre-2026-04-23 database history supports the hard policy that WS8 networking tasks were audit-only/out-of-scope, not builder work.

2. WARNING - Air-gap evidence is historically asymmetric between builders.
   - Evidence: modernization has 702 rows mentioning `air-gap`, `no network`, `no-network`, `-nic none`, or `-net none`; inference has 0 such rows.
   - Impact: this does not prove inference violated Law 2, because inference may not run QEMU guests. It does mean long-window reports cannot compare the two builders using a shared no-network evidence field.

3. INFO - Builder network-term rows in the database are preservation notes, not implementation intent.
   - Evidence: modernization has 7 builder rows with network-related terms. Samples include `air-gap preserved (no networking...)`, `air-gap enforced, no guest networking`, `no networking enabled`, and `explicit no-network extraction checks`. Inference has 0 network-term rows.
   - Impact: the historical signal is protective rather than a sign of TCP/IP, UDP, DNS, DHCP, HTTP, TLS, or socket implementation.

4. WARNING - `temple-central.db` cannot cover current air-gap history after its cutoff.
   - Evidence: latest builder timestamps are `2026-04-23T12:01:29` for modernization and `2026-04-23T12:06:44` for inference. Local git history after `2026-04-23T12:06:44` contains 770 TempleOS commits and 771 holyc-inference commits.
   - Impact: post-cutoff Law 2 conclusions must come from git history and audit artifacts, not this database alone.

5. INFO - Current focused source grep found no networking implementation in holyc-inference `src/`.
   - Evidence: the only current `src/` hit is `src/model/quarantine.HC:9`, a comment saying `No networking, no external deps, integer-only checks.`
   - Impact: this aligns with the database trend and Law 2/host-side quarantine expectations.

6. WARNING - Current TempleOS core-path grep still contains legacy outbound URL text in non-driver content.
   - Evidence: focused grep under `Kernel`, `Adam`, `Apps`, `Compiler`, `0000Boot`, and `src` found `http`/`https` strings in `Adam/God/HSNotes.DD`, `Adam/God/Vocab.DD`, `Adam/DevInfo.HC`, and `Adam/Opt/Utils/TOS.HC`.
   - Impact: these are not new networking stack code and the strongest examples are documentation/download strings, so this is not scored as a Law 2 violation. Historical scanners should classify static URL text separately from actual network transport additions to avoid false positives.

## Supporting Extracts

| Agent | Builder rows | Network-term rows | No-network evidence rows | WS8 rows | First timestamp | Last timestamp |
| --- | ---: | ---: | ---: | ---: | --- | --- |
| inference | 1,414 | 0 | 0 | 0 | 2026-04-12T13:53:13 | 2026-04-23T12:06:44 |
| modernization | 1,505 | 7 | 702 | 0 | 2026-04-12T13:51:32 | 2026-04-23T12:01:29 |

| Agent | Status | WS8 rows | First timestamp | Last timestamp |
| --- | --- | ---: | --- | --- |
| sanhedrin | fail | 6 | 2026-04-20T05:22:34 | 2026-04-22T23:55:13 |
| sanhedrin | pass | 378 | 2026-04-12T16:25:03 | 2026-04-23T11:54:25 |

Representative modernization rows with network terms:

| Row | Timestamp | Task | Signal |
| ---: | --- | --- | --- |
| 48 | 2026-04-12T16:00:37 | CQ-103 | `air-gap preserved (no networking...)` |
| 224 | 2026-04-12T23:47:43 | CQ-171 | `air-gap enforced, no guest networking` |
| 7022 | 2026-04-20T04:01:45 | CQ-688 | `no networking enabled (-nic none policy unchanged)` |
| 13617 | 2026-04-22T05:47:52 | CQ-1168 | `explicit no-network extraction checks` |
| 13728 | 2026-04-22T07:26:27 | CQ-1191 | `explicit QEMU no-network command evidence checks` |

## Commands

```text
sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-29-airgap-network-intent-drift.sql
rg -n -i '\b(tcp|udp|socket|sockets|dns|dhcp|tls|http|https|network|networking)\b' Kernel Adam Apps Compiler 0000Boot src
rg -n -i '\b(tcp|udp|socket|sockets|dns|dhcp|tls|http|https|network|networking)\b' src
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-list --count --since='2026-04-23T12:06:44' --all
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-list --count --since='2026-04-23T12:06:44' --all
```

## Recommendations

- Keep WS8 tasks explicitly out of scope and record that classification as a structured field, not only prose in Sanhedrin notes.
- Add a shared builder evidence convention: if a row executes any VM/QEMU-adjacent workflow, record the no-network proof token (`-nic none` preferred, `-net none` legacy fallback) in a structured validation field.
- Teach historical scanners to separate static URL/documentation strings from actual networking APIs, drivers, sockets, protocol handlers, and QEMU networking flags.
- Treat `temple-central.db` as pre-cutoff evidence only until ingestion resumes or a backfill imports the 770 TempleOS and 771 holyc-inference post-cutoff commits.
