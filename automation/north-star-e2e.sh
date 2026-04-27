#!/usr/bin/env bash
# north-star-e2e.sh (sanhedrin) — RED until Sanhedrin demonstrates teeth.
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/Documents/local-codebases/temple-sanhedrin}"
ENFORCE_LOG="$REPO_DIR/audits/enforcement.log"

if [[ ! -f "$ENFORCE_LOG" ]]; then
  echo "RED: $ENFORCE_LOG does not exist — sanhedrin has not run enforcement yet"
  exit 1
fi

# Look for any enforcement action OR explicit clean-run line in last 24h
since=$(date -v-24H -u +%FT%TZ 2>/dev/null || date -u -d '24 hours ago' +%FT%TZ)
recent=$(awk -v cutoff="$since" '$1 >= cutoff' "$ENFORCE_LOG" 2>/dev/null | wc -l | tr -d ' ')

if (( recent < 1 )); then
  echo "RED: no enforcement actions or clean-run entries in last 24h"
  exit 1
fi

# Require at least one revert action ever
revert_count=$(grep -c "revert" "$ENFORCE_LOG" 2>/dev/null || echo 0)
if (( revert_count < 1 )); then
  echo "RED: no revert action ever logged — sanhedrin must demonstrate authority"
  exit 1
fi

echo "GREEN: sanhedrin has teeth ($recent entries in 24h, $revert_count reverts logged)"
exit 0
