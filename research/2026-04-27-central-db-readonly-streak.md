# Central DB readonly streak (2026-04-27)

## Trigger
- Repeated builder loop failures (5+ consecutive) in TempleOS and holyc-inference logs:
  - `attempt to write a readonly database (8)` when inserting into `~/Documents/local-codebases/temple-central.db`.
- Pattern observed across many iterations on 2026-04-27, causing stale `iterations` telemetry despite ongoing code production.

## Findings
- SQLite code `SQLITE_READONLY` (8) indicates write path blocked.
- Extended code `SQLITE_READONLY_DIRECTORY` occurs when DB file may exist but process cannot create journal/WAL sidecar files in DB directory.
- WAL/journal behavior requires write capability for sidecar files (`-wal`, `-shm`, journal) in the same directory as the DB.
- In this environment, builder sandboxes can write inside repo roots but not `~/Documents/local-codebases/temple-central.db`, so inserts fail by policy, not by query syntax.

## Practical fix options
1. Move central DB into a shared writable root for all three loops (recommended for lowest friction).
2. Keep DB path, but run a host-side relay process that drains queued SQL (`pending_temple_central_inserts.sql`) and performs inserts outside restricted sandboxes.
3. Use per-repo local writable spool DBs and periodic host-side merge into central DB.

## Immediate containment
- Treat stale central DB telemetry as an audit WARNING while deriving agent liveness/progress from fresh `automation/logs/*.final.txt` and heartbeat files.
- Keep logging this failure pattern each audit until DB write path is restored.

## References
- https://sqlite.org/rescode.html
- https://sqlite.org/wal.html
- https://sqlite.org/forum/forumpost/ecec426355?t=c
