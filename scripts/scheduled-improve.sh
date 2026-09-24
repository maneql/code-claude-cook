#!/usr/bin/env bash
# Runs PERIODICALLY (cron / launchd / Task Scheduler / GitHub Actions).
# Goal: generate improvement proposals in PROPOSE-ONLY mode, then send a "needs approval" notification.
# Safety: runs headless with restricted allowedTools => the agent CANNOT modify code,
# it can only read the repo and write into proposals/. Any other tool is auto-denied.
set -uo pipefail

REPO_DIR="${1:-$PWD}"
cd "$REPO_DIR"
mkdir -p proposals
export CLAUDE_PROJECT_DIR="$REPO_DIR"

echo "[$(date '+%F %T')] Starting self-improve in $REPO_DIR"

claude -p "/self-improve" \
  --permission-mode default \
  --allowedTools "Read" "Grep" "Glob" "Bash(git log:*)" "Bash(git diff:*)" "Bash(git status:*)" "Write(proposals/**)" \
  >> "proposals/self-improve.log" 2>&1 || true

# Find the newest proposal and send a "needs approval" notification
LATEST=$(ls -t proposals/*.md 2>/dev/null | grep -v notifications | head -1 || true)
if [ -n "$LATEST" ]; then
  "$REPO_DIR/.claude/hooks/notify.sh" "NEW improvement proposal needs your approval: $LATEST  -> run: claude \"/apply-proposal $LATEST\""
else
  echo "[$(date '+%F %T')] No proposal was generated (see proposals/self-improve.log)"
fi
