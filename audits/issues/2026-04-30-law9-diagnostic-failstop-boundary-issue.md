# Local Issue: Law 9 Diagnostic Fail-Stop Boundary

Timestamp: 2026-04-30T09:53:27+02:00

Source audit: `audits/research/2026-04-30-law9-diagnostic-failstop-boundary.md`

## ISSUE-LAWS-008: Diagnostic vs Live Fail-Stop Controls

Problem: Law 9 forbids any API that disables halt-on-failure behavior, but current and historical Book-of-Truth code can contain diagnostic or replay helpers with parameters such as `halt_on_dead=FALSE`. Some live paths clamp those requests back to fail-stop, while retro audits can still flag the parameter shape without checking effective policy.

Impact: Auditors can disagree on whether a non-fatal parameter is a critical Law 9 bypass, a safe diagnostic simulation, or an acceptable blocked request. This affects serial-liveness, tamper, text-integrity, and append-failure audits.

Proposed resolution: Define a diagnostic/replay exception boundary. Live required Book-of-Truth failure paths must halt on the first required failure observation. Diagnostic helpers may be non-fatal only if they cannot alter live fail-stop policy, are labeled diagnostic-only, and record requested versus effective halt behavior. Audit reports should cite both requested and effective policy before scoring a bypass finding.

