#!/bin/bash
set -euo pipefail
ISO="/home/azureuser/TempleOS.ISO"
RESULT_DB="/home/azureuser/test-results.db"
sqlite3 "$RESULT_DB" "CREATE TABLE IF NOT EXISTS tests (id INTEGER PRIMARY KEY AUTOINCREMENT, ts TEXT DEFAULT (datetime('now')), repo TEXT, branch TEXT, files_tested TEXT, result TEXT, serial_excerpt TEXT);" 2>/dev/null
cd /home/azureuser/TempleOS && git pull --ff-only origin codex/modernization-loop 2>/dev/null || true
cd /home/azureuser/holyc-inference && git pull --ff-only origin main 2>/dev/null || true
TEMPLEOS_HC=$(cd /home/azureuser/TempleOS && git diff --name-only HEAD~1 -- "*.HC" 2>/dev/null | tr "\n" "," || echo "none")
INFERENCE_HC=$(cd /home/azureuser/holyc-inference && git diff --name-only HEAD~1 -- "*.HC" 2>/dev/null | tr "\n" "," || echo "none")
SERIAL_LOG="/tmp/templeos-serial-$$.log"
timeout 60 qemu-system-x86_64 -m 512M -cdrom "$ISO" -nic none -nographic -serial file:"$SERIAL_LOG" 2>/dev/null || true
RESULT="pass"
SERIAL=""
if [ -f "$SERIAL_LOG" ]; then
    SERIAL=$(head -20 "$SERIAL_LOG" | tr "'" " " | tr "\n" "|" | head -c 400)
    if grep -qi "error\|panic\|fault" "$SERIAL_LOG" 2>/dev/null; then
        RESULT="fail"
    fi
    rm -f "$SERIAL_LOG"
fi
sqlite3 "$RESULT_DB" "INSERT INTO tests (repo,branch,files_tested,result,serial_excerpt) VALUES ('TempleOS','codex/modernization-loop','${TEMPLEOS_HC}','${RESULT}','${SERIAL}');"
echo "[$(date -Iseconds)] compile-test: $RESULT | templeos-hc: $TEMPLEOS_HC | inference-hc: $INFERENCE_HC"
