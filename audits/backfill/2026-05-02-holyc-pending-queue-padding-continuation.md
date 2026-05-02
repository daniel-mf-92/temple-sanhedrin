# holyc-inference Pending Queue Padding Backfill Continuation

Timestamp: 2026-05-02T11:03:01+02:00

Audit owner: gpt-5.5 sibling, retroactive / historical scope only.

Audit angle: compliance backfill continuation for the appended `LAWS.md` rule "No Self-Generated Queue Items", focused on the current `holyc-inference` pending central-DB replay artifact. This pass did not inspect live liveness, restart any process, run QEMU or VM commands, execute WS8 networking tasks, modify TempleOS or holyc-inference source code, or write to `temple-central.db`. The TempleOS guest air-gap was not touched.

Repos / snapshots:
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554bea44c132137c590f02034c8f726`
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `9f3abbf263982bf9344f8973a52f845f1f48d109`
- Sanhedrin audit repo before this artifact: `044f328882c5bcfb4894cd674f8555bc178ee7b1`

## Summary

The current holyc-inference pending central-DB artifact still preserves builder-authored queue padding language even though the current `MASTER_TASKS.md` has zero unchecked IQ rows. The artifact contains 95 pending `iterations` inserts, 64 queue-depth/self-padding phrases, 56 referenced IQ IDs that are not the primary task row, and three rows where a killed primary test is still recorded as `pass` after fallback validation. This is not a live queue-health finding; it is a replay/backfill hazard. If imported as-is, the central DB would preserve stale Law 6 self-padding evidence and ambiguous pass semantics.

Finding count: 5 warnings.

## Findings

### WARNING-001: Pending rows still encode queue-depth self-padding

Evidence:
- `automation/pending_temple_central_inserts.sql` contains 95 `INSERT INTO iterations` rows.
- The same file contains 64 matches where notes say queue depth was kept, maintained, preserved, restored, or refilled via an IQ item.
- It contains 33 `append/appended/appending IQ-` matches and 27 `via IQ-` matches.
- Examples include notes such as `kept queue depth at 15 by appending IQ-1625`, `replenished queue depth via IQ-1626`, and `maintained queue depth at 15 by appending IQ-1794`.

Impact: the pending artifact records the exact self-padding pattern that the later Law 6 text forbids. Because the artifact is pending replay data, the risk is historical ingestion and compliance scoring, not direct source modification by this audit.

### WARNING-002: The artifact references 56 IQ IDs that are not primary pending rows

Evidence:
- Primary pending task rows: 95 distinct IQ IDs, `IQ-1500` through `IQ-1779`.
- Total IQ mentions in the pending SQL: 264.
- Distinct IQ mentions: 151.
- Distinct referenced IQ IDs that are not primary task rows: 56.
- Early examples: `IQ-1517`, `IQ-1520`, `IQ-1534`, `IQ-1538`, `IQ-1545`, `IQ-1546`, `IQ-1554`, `IQ-1555`, `IQ-1557`, and `IQ-1558`.

Impact: a replay importer that treats `task_id` as the only queue reference will lose the appended/replenished IQ lineage. A replay importer that tokenizes notes will instead see many extra queue IDs without an external-source marker.

### WARNING-003: Current MASTER_TASKS no longer has unchecked IQ rows

Evidence:
- Current `MASTER_TASKS.md` has `0` lines matching `- [ ] IQ-`.
- Pending rows still mention maintaining 15 unchecked IQ items.
- The final referenced examples are now completed in the task file: `IQ-1791` and `IQ-1794` are both checked off.

Impact: this proves the pending SQL is stale relative to current task state. Importing it now would reintroduce historical "15 unchecked" claims without a current queue snapshot that can verify whether the appended tasks were external, builder-generated, or later completed.

### WARNING-004: Fallback-validation pass rows need separate status semantics

Evidence:
- Three pending rows mention `exited 137`, `SIGKILL`, or `fallback validation passed`.
- `IQ-1723` is recorded with `status='pass'` while its validation result says `primary test command exited 137 (SIGKILL); fallback validation passed (py_compile+symbol checks)`.
- One row uses a `py_compile` plus `rg -n` style fallback as the only recorded validation shape.

Impact: fallback validation may be legitimate, but recording it as an undifferentiated pass weakens Law 5 and North Star trend scoring. Replay should preserve `primary_failed=true`, `fallback_passed=true`, and `fallback_kind` rather than collapsing the row to a normal pass.

### WARNING-005: TempleOS does not currently expose the same pending-file surface

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/pending_temple_central_inserts.sql` is absent in the current TempleOS snapshot.
- The current continuation risk is concentrated in holyc-inference's pending replay artifact.

Impact: a cross-repo report should not generalize this specific pending-file finding to TempleOS current head. TempleOS still has separate historical queue-padding reports, but this continuation is holyc-inference-specific.

## Key Counts

| Metric | Count |
| --- | ---: |
| Pending `iterations` inserts | 95 |
| Primary IQ task IDs | 95 |
| Total IQ mentions in pending SQL | 264 |
| Distinct IQ mentions | 151 |
| Referenced IQ IDs not primary rows | 56 |
| Queue kept/maintained/preserved/restored/refilled phrases | 64 |
| `append/appended/appending IQ-` matches | 33 |
| `via IQ-` matches | 27 |
| Read-only DB/write mentions | 55 |
| SIGKILL/fallback pass rows | 3 |
| Current unchecked IQ rows in `MASTER_TASKS.md` | 0 |

## Recommended Backfill Handling

- Do not replay `automation/pending_temple_central_inserts.sql` into `iterations` without normalizing queue-padding notes.
- Extract appended IQ references into a side table with fields like `source_iteration_task`, `referenced_task`, `reference_kind`, and `external_source_provenance`.
- Mark rows with `primary test command exited 137` as `pass_with_fallback` or preserve an equivalent structured fallback field.
- Treat historical "kept queue depth at 15" claims as stale unless joined to a same-timestamp task snapshot.

## Read-Only Verification Commands

```bash
python3 - <<'PY'
from pathlib import Path
import re
p = Path('/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/pending_temple_central_inserts.sql')
text = p.read_text(errors='ignore')
print('rows', len(re.findall(r'INSERT INTO iterations', text)))
for name, pat in {
    'append': r'\bappend(?:ed|ing)?\s+IQ-',
    'via': r'\bvia\s+IQ-',
    'queue_kept': r'queue\s+(?:kept|maintained|preserved|restored|refilled).*?IQ-',
    'unchecked': r'unchecked\s+IQ|IQ\s+queue|queue\s+depth',
    'read_only': r'read-only|readonly',
    'sigkill_fallback_pass': r'exited 137|SIGKILL|fallback validation passed',
}.items():
    print(name, len(re.findall(pat, text, flags=re.I|re.S)))
ids = re.findall(r"'IQ-(\d+)'", text)
refs = re.findall(r'IQ-(\d+)', text)
print('task_rows', len(ids), 'min', min(map(int, ids)), 'max', max(map(int, ids)), 'unique', len(set(ids)))
print('all_iq_mentions', len(refs), 'distinct_mentions', len(set(refs)), 'mentioned_not_row', len(set(refs) - set(ids)))
PY
```

```bash
python3 - <<'PY'
from pathlib import Path
import re
p = Path('/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md')
print(sum(1 for line in p.read_text(errors='ignore').splitlines() if re.match(r'- \[ \] IQ-', line)))
PY
```

Finding count: 5 warnings.
