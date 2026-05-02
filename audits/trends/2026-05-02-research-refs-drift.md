# temple-central.db Research Reference Provenance Drift

Audit timestamp: 2026-05-02T07:58:00+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for source-reference coverage in the `research` ledger. It did not inspect live liveness, restart processes, run QEMU or VM commands, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

SQL: `audits/trends/2026-05-02-research-refs-drift.sql`

Python tokenizer: `audits/trends/2026-05-02-research-refs-drift.py`

## Summary

The `research` table stores source references as free-form text rather than normalized rows. Across 444 research records, 76 rows have blank `references_urls`, 8 more have nonblank text with no parseable URL, and the remaining references mix semicolons, commas, newlines, and spaces as delimiters. The cited-source set is also concentrated: 880 URL mentions collapse to 423 distinct URLs, with the top 15 repeated URLs accounting for 292 mentions.

Findings: 5 warning findings.

## Findings

### WARNING-1: Blank references are concentrated in the research burst window

Evidence:
- Research rows: 444.
- Blank `references_urls`: 76 rows.
- 75 of the 76 blank-reference rows occur on 2026-04-21 and 2026-04-22.
- Highest blank-reference hours: 2026-04-21T23:00:00 with 9 blanks, 2026-04-21T22:00:00 with 8 blanks, and 2026-04-21T20:00:00 with 8 blanks.

Impact: the exact window that produced the most loop-remediation research also lost the most source provenance. Law 5 historical scoring should not count raw research row volume as deep research unless each row has either cited sources or a clear committed-artifact reference.

### WARNING-2: `references_urls` is a free-form list with multiple delimiter conventions

Evidence:
- Rows containing semicolons: 163.
- Rows containing newlines: 6.
- Rows containing commas: 43.
- Rows containing spaces inside the reference field: 30.

Impact: downstream audits must re-implement ad hoc tokenization before they can count citations or detect repeated research. A normalized `research_references(research_id, url, source_type)` table would make repeat detection and reference coverage deterministic.

### WARNING-3: Some nonblank reference fields still contain no parseable URL

Evidence:
- URL tokenizer found 360 rows with at least one `http://` or `https://` URL.
- 76 rows are blank.
- 8 rows are nonblank but contain no parseable URL.

Impact: a non-empty `references_urls` field is not enough proof that the research was sourced. Historical queries need to validate URL tokens, not just `trim(references_urls) != ''`.

### WARNING-4: Repeated citations can inflate apparent research breadth

Evidence:
- URL mentions: 880.
- Distinct URLs: 423.
- The top repeated URL appears 58 times.
- The 15 most repeated URLs account for 292 mentions.

Impact: repeated source citations are not bad by themselves, but the ledger lacks a case/update model. Without one, repeated mentions of the same retry/backoff/circuit-breaker sources can look like many independent research efforts instead of updates to one loop-remediation case.

### WARNING-5: Source domains are operationally concentrated

Evidence:
- Top URL domains by mention count: `aws.amazon.com` 125, `sre.google` 116, `docs.temporal.io` 85, `docs.github.com` 79, `martinfowler.com` 66, `docs.aws.amazon.com` 61, `arxiv.org` 55.
- The domain mix matches the repeat-task and reliability-remediation theme rather than broad LAWS.md coverage.

Impact: this supports the prior topic-churn finding from a different angle: the research ledger is useful for retry-loop operations, but weaker as evidence of broad law research. Future reports should distinguish operational source reuse from new legal/policy edge-case research.

## Key Aggregates

| Metric | Count |
| --- | ---: |
| Research rows | 444 |
| Blank reference rows | 76 |
| Rows with parseable URL | 360 |
| Nonblank rows without parseable URL | 8 |
| URL mentions | 880 |
| Distinct URLs | 423 |

| Day | Rows | Blank References | URL Mentions | Rows With URL |
| --- | ---: | ---: | ---: | ---: |
| 2026-04-15 | 1 | 0 | 1 | 1 |
| 2026-04-16 | 1 | 0 | 1 | 1 |
| 2026-04-17 | 1 | 1 | 0 | 0 |
| 2026-04-19 | 4 | 0 | 13 | 4 |
| 2026-04-20 | 3 | 0 | 11 | 3 |
| 2026-04-21 | 273 | 55 | 535 | 211 |
| 2026-04-22 | 160 | 20 | 315 | 139 |
| 2026-04-23 | 1 | 0 | 4 | 1 |

## Recommendations

- Add a normalized `research_references` table with one URL per row and preserve the raw field only as import context.
- Require either at least one parseable URL or one committed artifact path for every new research case.
- Add `research_case_id` and `is_case_update` fields so repeated citations update an existing case instead of inflating research breadth.
- Treat blank-reference burst rows as evidence-limited in Law 5 backfills unless a matching committed research artifact supplies sources.

## Read-Only Verification Commands

```bash
sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-02-research-refs-drift.sql
python3 audits/trends/2026-05-02-research-refs-drift.py
```

Finding count: 5 warning findings.
