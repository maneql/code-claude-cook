#!/usr/bin/env bash
# PreToolUse hook for Bash AND PowerShell tools: block commits/pushes, commands that
# discard uncommitted work, and destructive commands. Changes stay LOCAL for review,
# and the working tree is the only copy of the work.
# exit 2 = block, stderr = reason. This is a best-effort safety net that matches command
# text - it is not a sandbox.
INPUT=$(cat)

# Read tool_input.command with Python. If that fails (no python3/python, bad JSON), check the
# raw hook input instead, so the guard fails closed rather than silently allowing everything.
CMD=""
for PY in python3 python; do
  command -v "$PY" >/dev/null 2>&1 || continue
  CMD=$(printf '%s' "$INPUT" | "$PY" -c "import sys,json; print(json.load(sys.stdin)['tool_input']['command'])" 2>/dev/null) && [ -n "$CMD" ] && break
  CMD=""
done
NOTE=""
if [ -z "$CMD" ]; then
  CMD="$INPUT"
  NOTE=" (could not parse the hook input - is python3 installed? - so the raw input was checked)"
fi

# Block commits / pushes - keep all changes local for human review.
if printf '%s' "$CMD" | grep -Eiq '\bgit\b.*\b(commit|push)\b'; then
  echo "[guard] Commits/pushes are disabled - changes are kept LOCAL for your review. Stage/diff is fine; please commit yourself.$NOTE" >&2
  exit 2
fi

# Block git commands that DISCARD uncommitted work (the working tree holds the only copy):
# reset --hard, clean, restore, stash drop/clear, checkout . / checkout * / checkout -- <path>.
if printf '%s' "$CMD" | grep -Eiq '\bgit\b[^|;&]*[[:space:]](reset[^|;&]*--hard|clean([[:space:]]|$)|restore([[:space:]]|$)|stash[[:space:]]+(drop|clear))' \
   || printf '%s' "$CMD" | grep -Eiq '\bgit\b[^|;&]*[[:space:]]checkout([[:space:]]+(\.|\*)|[^|;&]*[[:space:]]--([[:space:]]|$))'; then
  echo "[guard] Blocked: this would discard uncommitted work (the working tree holds the only copy): $CMD$NOTE" >&2
  exit 2
fi

# Block destructive commands (bash and PowerShell/cmd forms - this hook guards both tools):
# - recursive rm (-rf, -fr, -r -f, -R, --recursive) aimed at / ~ * . $HOME or a drive (C:)
# - find with -delete or -exec/-execdir rm
# - Remove-Item with -Recurse and -Force in any order (or -r / -fo), rd|rmdir|del /s, format X:
RM_RE='\brm([[:space:]]+-[^[:space:]]*)*[[:space:]]+(-[a-z]*r[a-z]*|--recursive)([[:space:]]+-[^[:space:]]*)*[[:space:]]+(\\?["'"'"'])?(/|~|\*|\.|\$HOME|\$\{HOME\}|[a-z]:)'
FIND_RE='\bfind\b[^|;&]*[[:space:]](-delete\b|-exec(dir)?[[:space:]]+rm\b)'
WIN_RE='Remove-Item[^|;&]*(-r[a-z]*\b[^|;&]*-fo[a-z]*\b|-fo[a-z]*\b[^|;&]*-r[a-z]*\b)|\b(rd|rmdir|del)[[:space:]]+/s|\bformat[[:space:]]+[a-z]:'
if printf '%s' "$CMD" | grep -Eiq "$RM_RE" \
   || printf '%s' "$CMD" | grep -Eiq "$FIND_RE" \
   || printf '%s' "$CMD" | grep -Eiq "$WIN_RE" \
   || printf '%s' "$CMD" | grep -Eiq '(mkfs|:\(\)\{|dd[[:space:]]+if=|DROP[[:space:]]+(TABLE|DATABASE)|git[[:space:]]+push[[:space:]].*--force)'; then
  echo "[guard] Blocked: this looks like a destructive command: $CMD$NOTE" >&2
  exit 2
fi
exit 0
