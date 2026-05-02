# Retro Audit Artifact Schema Drift

Audit timestamp: 2026-05-02T03:36:04+02:00

Audit angle: historical drift trends. This pass analyzed the existing `audits/retro/*.md` corpus and joined report filenames to read-only git history in `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` and `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`. It did not inspect live liveness, restart processes, run QEMU or VM commands, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

Analyzer: `audits/trends/2026-05-02-retro-audit-artifact-schema-drift.py`

## Summary

The retro audit corpus is linkable when all builder refs are included: 811 of 811 report filenames match a commit in either TempleOS or holyc-inference. The drift is not orphaned files; it is inconsistent report structure. Most reports lack an explicit `Finding count:` field, hundreds lack standard verification or QEMU non-execution statements, and current-branch commit coverage is still sparse relative to the total builder histories.

Findings: 5 warnings.

## Findings

### WARNING-1: Finding counts are not machine-readable for most retro reports

Evidence:

- Retro reports scanned: 811.
- Reports missing `Finding count:`: 779.
- Reports containing severity words (`CRITICAL` or `WARNING`): 454.
- Reports with no-violation wording: 227.

Impact: `GPT55_AUDIT_LOG.md` requires per-iteration finding counts, but the underlying commit reports usually do not expose a stable count field. Historical scoring must re-parse prose, which can overcount severity words in law-check summaries or undercount findings hidden under nonstandard headings.

### WARNING-2: Metadata headers are inconsistent across the corpus

Evidence:

- Missing `- Repo:` line: 158 reports.
- Missing `- Commit:` line: 258 reports.
- Missing `- Subject:` line: 145 reports.
- Missing `## Findings` heading: 24 reports.

Impact: filename-based SHA lookup works today, but report bodies are not self-contained. If reports are copied, renamed, bundled, or indexed outside this repository, repo identity and commit subject can be lost or require a fallback git join.

### WARNING-3: Verification evidence is not standardized

Evidence:

- Reports missing verification/static-validation wording: 374.
- Reports missing an explicit QEMU/VM non-execution statement: 315.

Impact: retro audits are required to avoid live liveness work and preserve the guest air-gap. Many reports likely did so, but the artifact does not always say it in a grep-friendly way. That weakens later proof that a historical audit remained read-only and did not run VM commands.

### WARNING-4: All reports join across all refs, but current-branch coverage remains partial

Evidence:

| Repo | All-ref commits | Current-branch commits | Reports joined across all refs | Reports joined to current branch |
| --- | ---: | ---: | ---: | ---: |
| TempleOS | 2,451 | 2,067 | 497 | 198 |
| holyc-inference | 2,669 | 2,383 | 314 | 121 |

Impact: retro coverage is meaningful, but it is not close to a complete `git log` walk for either active branch. Coverage dashboards should distinguish `all refs`, `current branch`, and `latest N commits` instead of treating report count as complete history coverage.

### WARNING-5: The existing corpus needs a small schema contract before further backfill

Evidence:

- The analyzer found zero orphan reports across all refs, so the corpus is salvageable without renaming.
- The missing fields cluster around stable schema, not content absence: finding count, repo/commit/subject metadata, verification wording, and QEMU non-execution wording.

Impact: continuing to add reports without a minimal schema will compound parsing drift. A standard header would make future compliance backfills and trend reports cheaper and less error-prone.

## Recommended Retro Report Header

```markdown
- Repo: `TempleOS|holyc-inference`
- Commit: `<40-char-sha>`
- Subject: `<git subject>`
- Author date: `<ISO timestamp>`
- Audit timestamp: `<ISO timestamp>`
- Audit lane: `retroactive / historical commit audit`
- QEMU/VM: `not executed`
- Finding count: `<integer>`
```

## Read-Only Verification Command

```bash
python3 audits/trends/2026-05-02-retro-audit-artifact-schema-drift.py
```

Finding count: 5 warnings.
