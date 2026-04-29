# Cross-Repo Audit: Progress Ledger Timestamp Contract Drift

- Audit time: `2026-04-29T18:05:16Z`
- Audit angle: cross-repo invariant check
- TempleOS head inspected: `5ab31f809a1f1a349344b8b64bf96f9e52e523eb`
- holyc-inference head inspected: `10b1d978c719903458e29ed67adac2033aeb10c6`
- Sanhedrin branch: `codex/sanhedrin-gpt55-audit`

## Scope

Read-only comparison of committed `HEAD:path` evidence for GPT55 progress ledgers and validation surfaces:

- TempleOS: `MODERNIZATION/GPT55_PROGRESS.md`
- TempleOS report: `MODERNIZATION/lint-reports/gpt55-progress-ledger-latest.{md,json}`
- holyc-inference: `GPT55_PROGRESS.md`

Both builder worktrees had unrelated dirty files during this audit, so all counted evidence was read with `git show HEAD:<path>` to avoid incorporating concurrent uncommitted builder work. No TempleOS or holyc-inference source was modified. No live liveness checks were performed. No QEMU or VM command was executed. No WS8 or network task was executed.

## Expected Invariant

The two GPT55 builder ledgers should be reliable historical evidence for Law 5 north-star progress and retroactive audit ordering. At minimum, each committed ledger should have:

- parseable ISO timestamps,
- monotonically nondecreasing timestamps after UTC normalization,
- one documented timestamp-zone convention or an enforced normalization rule,
- a gate that fails when ordering evidence is ambiguous, and
- internally consistent machine-readable report fields.

## Findings

### WARNING-001: holyc-inference GPT55 progress ledger is non-monotonic in 5 places

The committed holyc-inference ledger has 258 parseable entries, all using `Z`, but 5 adjacent line pairs move backward in UTC time:

| Lines | Previous timestamp | Next timestamp | Backward delta |
| ---: | --- | --- | ---: |
| 81 -> 82 | `2026-04-28T05:43:50Z` | `2026-04-28T03:21:49Z` | 8,521s |
| 82 -> 83 | `2026-04-28T03:21:49Z` | `2026-04-28T03:01:36Z` | 1,213s |
| 121 -> 122 | `2026-04-29T00:31:55Z` | `2026-04-28T22:12:06Z` | 8,389s |
| 122 -> 123 | `2026-04-28T22:12:06Z` | `2026-04-28T11:10:38Z` | 39,688s |
| 161 -> 162 | `2026-04-29T01:45:48Z` | `2026-04-28T19:27:43Z` | 22,685s |

Evidence:
- `GPT55_PROGRESS.md:81-83`
- `GPT55_PROGRESS.md:121-123`
- `GPT55_PROGRESS.md:161-162`

Impact:
Retroactive Law 5 scoring that treats ledger order as iteration order will mis-sequence progress, freshness, and regression windows. This is not a direct HolyC purity or air-gap breach, but it weakens historical audit evidence.

### WARNING-002: TempleOS committed progress report is stale relative to the committed ledger

The committed TempleOS ledger has 201 parseable entries, but the committed Markdown report says `Lines: 192`, `Entries: 192`, and `Last timestamp: 2026-04-29T14:01:48Z`. The ledger continues through line 201, ending at `2026-04-29T17:40:44Z`.

Evidence:
- `MODERNIZATION/GPT55_PROGRESS.md:193-201`
- `MODERNIZATION/lint-reports/gpt55-progress-ledger-latest.md`
- `MODERNIZATION/lint-reports/gpt55-progress-ledger-latest.json`

Impact:
A committed report consumer can conclude the ledger gate covers the latest 9 committed entries when it does not. This weakens Law 5 and Law 7 historical evidence because the report's `Gate: PASS` status is not tied to the current committed ledger contents.

### WARNING-003: TempleOS has a progress-ledger checker, but it permits mixed timestamp-zone conventions

The committed TempleOS ledger has 201 parseable entries across 2 timestamp-zone conventions:

| Zone | Entries |
| --- | ---: |
| `+02:00` | 98 |
| `Z` | 103 |

The committed Markdown report also records `Timestamp zones: 2` and still reports `Gate: PASS`.

Impact:
The report observes mixed zones but does not define whether mixed zones are allowed, warning-only, or gate-failing. That differs from holyc-inference's de facto all-`Z` convention and leaves retro audits to infer chronology policy themselves.

### WARNING-004: TempleOS progress-ledger report has internally inconsistent max-gap fields

The committed Markdown report says `Max entry gap: 101m` and identifies line 107 -> 108 as a 101-minute gap. The committed JSON companion records the same source data and `max_entry_gap_seconds: 6081`, but records `max_entry_gap_minutes: 0`.

Evidence:
- `MODERNIZATION/lint-reports/gpt55-progress-ledger-latest.md`
- `MODERNIZATION/lint-reports/gpt55-progress-ledger-latest.json`

Impact:
Consumers that read the JSON field instead of recomputing seconds can under-report cadence gaps. That can distort Law 5 and Law 7 historical trend analysis even when the human Markdown report looks correct.

### WARNING-005: holyc-inference lacks an equivalent committed progress-ledger integrity report

TempleOS has a committed progress-ledger report with entry counts, duplicate checks, zone counts, monotonicity counts, future-date checks, and cadence gaps. A committed-tree search in holyc-inference found timestamp handling in benchmark tooling and loop logs, but no equivalent committed `GPT55_PROGRESS.md` integrity report or gate.

Evidence:
- `MODERNIZATION/lint-reports/gpt55-progress-ledger-latest.md` exists in TempleOS.
- `git grep -n -E "GPT55_PROGRESS|progress ledger|timestamp|zone|monotonic|inversion" HEAD -- bench automation` in holyc-inference found benchmark/report timestamp handling, not a progress-ledger gate.

Impact:
The two builders do not share the same historical evidence contract. TempleOS can at least surface ledger defects, while holyc-inference currently ships non-monotonic ledger history without a committed report that makes the defect visible.

## Assessment

Found 5 warnings and 0 critical violations.

The drift is historical-evidence drift, not a direct source-code violation. It matters because Sanhedrin retroactive audits frequently need to answer "what happened in which iteration?" If one ledger is non-monotonic, another ships stale validation reports, and the two repos do not share a timestamp-zone policy, audit conclusions about Law 5 progress cadence, repeated blockers, and freshness windows become less reproducible.

## Recommended Remediation

- Add a holyc-inference `GPT55_PROGRESS.md` integrity checker mirroring TempleOS fields: entries, malformed lines, duplicate timestamps, UTC monotonicity, zone counts, future timestamps, and cadence gaps.
- Make non-monotonic ledger entries gate-failing in both repos.
- Make progress-ledger report generation fail or mark stale when report entry counts and last timestamps do not match the committed ledger.
- Decide whether mixed timestamp zones are allowed; if allowed, reports should say `mixed zones allowed after UTC normalization`, otherwise make zone-count >1 a warning or failure.
- Fix TempleOS `max_entry_gap_minutes` in the JSON report so it agrees with `max_entry_gap_seconds` and the Markdown report.
- Prefer appending ledger entries in UTC `Z` format across both GPT55 branches.

## Read-Only Verification Commands

```text
python3 - <<'PY'
from datetime import datetime, timezone
import subprocess, json, re

repos = {
    'TempleOS': ('/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55', 'MODERNIZATION/GPT55_PROGRESS.md'),
    'holyc-inference': ('/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55', 'GPT55_PROGRESS.md'),
}
for name, (repo, path) in repos.items():
    text = subprocess.check_output(['git', 'show', f'HEAD:{path}'], cwd=repo, text=True)
    rows = []
    zones = {}
    for i, line in enumerate(text.splitlines(), 1):
        m = re.match(r'^(\S+) \| (.*)$', line)
        if not m:
            continue
        raw = m.group(1)
        dt = datetime.fromisoformat(raw.replace('Z', '+00:00')).astimezone(timezone.utc)
        zone = 'Z' if raw.endswith('Z') else raw[-6:]
        zones[zone] = zones.get(zone, 0) + 1
        rows.append((i, raw, dt))
    inversions = [(a, b) for a, b in zip(rows, rows[1:]) if b[2] < a[2]]
    print(name, len(rows), zones, len(inversions))

report = subprocess.check_output(
    ['git', 'show', 'HEAD:MODERNIZATION/lint-reports/gpt55-progress-ledger-latest.json'],
    cwd='/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55',
    text=True,
)
data = json.loads(report)
print(data['max_entry_gap_seconds'], data['max_entry_gap_minutes'])
PY

cd /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55
git show HEAD:MODERNIZATION/GPT55_PROGRESS.md | nl -ba | sed -n '185,210p'
git show HEAD:MODERNIZATION/lint-reports/gpt55-progress-ledger-latest.md | sed -n '1,120p'

cd /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55
git show HEAD:GPT55_PROGRESS.md | nl -ba | sed -n '76,86p;116,126p;157,164p'
git grep -n -E "GPT55_PROGRESS|progress ledger|timestamp|zone|monotonic|inversion" HEAD -- bench automation
```
