#!/usr/bin/env bash
# enforce-laws.sh — Sanhedrin enforcement. Detects violations + reverts.
# Runs across TempleOS + holyc-inference. Requires git push permissions.

set -euo pipefail

SANHEDRIN_DIR="${SANHEDRIN_DIR:-$HOME/Documents/local-codebases/temple-sanhedrin}"
AUDITS_DIR="$SANHEDRIN_DIR/audits"
ENFORCE_LOG="$AUDITS_DIR/enforcement.log"
mkdir -p "$AUDITS_DIR"
touch "$ENFORCE_LOG"

# Repos under enforcement
declare -a REPOS=(
  "$HOME/Documents/local-codebases/TempleOS"
  "$HOME/Documents/local-codebases/holyc-inference"
)

ts() { date -u +%FT%TZ; }

log_action() {
  local action="$1" repo="$2" sha="$3" law="$4" detail="$5"
  echo "$(ts) action=$action repo=$(basename "$repo") sha=$sha law=$law detail=$detail" >> "$ENFORCE_LOG"
}


CUTOFF_FILE="$SANHEDRIN_DIR/audits/.enforce-since"
if [[ -f "$CUTOFF_FILE" ]]; then
  SINCE_TS=$(grep -oE "SINCE_TS=[^ ]+" "$CUTOFF_FILE" | head -1 | sed "s/SINCE_TS=//")
fi
SINCE_EPOCH=$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "${SINCE_TS:-1970-01-01T00:00:00Z}" "+%s" 2>/dev/null || echo 0)

violations_found=0

for repo in "${REPOS[@]}"; do
  [[ ! -d "$repo/.git" ]] && continue
  cd "$repo"

  # Find the active codex branch
  branch=$(git branch -a 2>/dev/null | grep -E "codex/(modernization|inference)-loop|(^\* main$|^  main$|remotes/origin/main$)" | head -1 | sed 's/^[* ] //; s|^remotes/origin/||') || true
  [[ -z "$branch" ]] && continue

  # Inspect last 5 commits
  for sha in $(git log "$branch" --format=%H -n 5 2>/dev/null); do
    commit_epoch=$(git log -1 --format=%ct "$sha")
    if (( commit_epoch < SINCE_EPOCH )); then continue; fi
    # Skip sanhedrin's own revert commits (prevents oscillation)
    sha_msg=$(git log -1 --format=%s "$sha")
    if [[ "$sha_msg" == revert:\ sanhedrin\ enforcement* ]]; then
      continue
    fi
    # Skip auto-checkpoint commits (host loop snapshots, not creative work)
    if [[ "$sha_msg" == chore\(codex\):\ checkpoint* ]]; then
      continue
    fi
    # Skip sanhedrin self-actions (RM/revert commits)
    if [[ "$sha_msg" == sanhedrin:\ * ]]; then
      continue
    fi
    # Skip shas already escalated to humans (LAW-6 conflict, etc.) — no point re-detecting
    if grep -qF "sha=$sha" "$AUDITS_DIR/blockers-escalated.log" 2>/dev/null; then
      continue
    fi
    # Skip commits already reverted by sanhedrin (regex, not -F: needs to match .* in pattern)
    if git log "$branch" --format=%s -n 30 | grep -qE "^revert: sanhedrin enforcement.*$sha"; then
      continue
    fi

    msg=$(git log -1 --format=%s "$sha")

    # LAW 4: Identifier compounding (filename or function-name lengths)
    bad_files=$(git diff-tree --no-commit-id --name-only -r "$sha" 2>/dev/null | while read f; do
      [[ -z "$f" ]] && continue
      # Skip generated artifacts — the source is the violation, not the build output
      case "$f" in
        *__pycache__*|*.pyc|*.bak|*.deprecated.bak) continue ;;
      esac
      base=$(basename "$f")
      name="${base%.*}"
      if (( ${#name} > 40 )); then echo "$f"; continue; fi
      tokens=$(echo "$name" | tr '_-' '\n' | wc -l | tr -d ' ')
      if (( tokens > 5 )); then echo "$f"; continue; fi
    done)

    if [[ -n "$bad_files" ]]; then
      first_bad=$(echo "$bad_files" | head -1)
      log_action "DETECT" "$repo" "$sha" "LAW-4-compounding" "$first_bad"
      violations_found=$((violations_found+1))
      # Targeted removal: git rm each bad file (preserves rest of commit).
      # Skip if file already absent (prior enforce-laws run handled it).
      removed_any=0
      while IFS= read -r bf; do
        [[ -z "$bf" ]] && continue
        if [[ -e "$bf" ]] || git ls-files --error-unmatch "$bf" >/dev/null 2>&1; then
          if git rm -f "$bf" >/dev/null 2>&1; then
            removed_any=1
          fi
        fi
      done <<< "$bad_files"
      if (( removed_any == 1 )); then
        if git commit -m "sanhedrin: remove LAW-4 compounding violator(s) introduced in $sha" >/dev/null 2>&1; then
          git push origin "$branch" >/dev/null 2>&1 || log_action "PUSH-FAIL" "$repo" "$sha" "LAW-4" "push failed"
          log_action "RM" "$repo" "$sha" "LAW-4-compounding" "$first_bad"
        else
          log_action "RM-COMMIT-FAIL" "$repo" "$sha" "LAW-4-compounding" "$first_bad"
        fi
      else
        log_action "ALREADY-CLEAN" "$repo" "$sha" "LAW-4-compounding" "$first_bad"
      fi
      continue
    fi

    # LAW 6: Self-generated CQ/IQ items — commit added new "- [ ] CQ-" or "- [ ] IQ-" lines
    added_queue=$(git show "$sha" -- '*MASTER_TASKS.md' 2>/dev/null | { grep -cE "^\+- \[ \] (CQ|IQ)-" || true; } | tr -d ' ')
    if (( added_queue > 0 )); then
      log_action "DETECT" "$repo" "$sha" "LAW-6-self-queue" "added=$added_queue"
      violations_found=$((violations_found+1))
      if git revert --no-edit --no-commit "$sha" >/dev/null 2>&1; then
        git commit -m "revert: sanhedrin enforcement (LAW-6 self-generated queue items) of $sha" >/dev/null 2>&1 || true
        git push origin "$branch" >/dev/null 2>&1 || log_action "PUSH-FAIL" "$repo" "$sha" "LAW-6" "push failed"
        log_action "REVERT" "$repo" "$sha" "LAW-6-self-queue" "added=$added_queue"
      else
        # Conflict — abort, escalate to human (dedup: skip if sha already escalated)
        git revert --abort >/dev/null 2>&1 || true
        if ! grep -qF "sha=$sha" "$AUDITS_DIR/blockers-escalated.log" 2>/dev/null; then
          echo "$(ts) LAW-6 revert conflict: $(basename "$repo") sha=$sha — manual cleanup needed" >> "$AUDITS_DIR/blockers-escalated.log"
        fi
        log_action "REVERT-CONFLICT" "$repo" "$sha" "LAW-6-self-queue" "escalated"
      fi
      continue
    fi
  done

  # LAW 7: Repeated blocker — same error string in last 5 final messages
  logs_dir="$repo/automation/logs"
  if [[ -d "$logs_dir" ]]; then
    blocker_pattern="readonly database"
    recent_finals=$(ls -t "$logs_dir"/*.final.txt 2>/dev/null | head -5 || true)
    if [[ -n "$recent_finals" ]]; then
      blocker_count=$(echo "$recent_finals" | { xargs grep -l "$blocker_pattern" 2>/dev/null || true; } | wc -l | tr -d ' ')
      if (( blocker_count >= 3 )); then
        log_action "DETECT" "$repo" "(N/A)" "LAW-7-repeated-blocker" "pattern=$blocker_pattern count=$blocker_count"
        violations_found=$((violations_found+1))
        # Don't revert — escalate to human-visible file
        echo "$(ts) repeated blocker '$blocker_pattern' in $(basename "$repo") — needs human action" >> "$AUDITS_DIR/blockers-escalated.log"
      fi
    fi
  fi
done

if (( violations_found == 0 )); then
  log_action "CLEAN" "all" "-" "-" "no violations detected"
fi

echo "enforce-laws: $violations_found violations"
exit 0
