#!/usr/bin/env bash
# Send a notification. Works both from a hook (reads JSON on stdin) or called directly with one argument.
MSG="${1:-}"
if [ -z "$MSG" ] && [ ! -t 0 ]; then
  MSG=$(python3 -c "import sys,json
try:
    d=json.load(sys.stdin); print(d.get('message') or d.get('reason') or 'An event needs your attention from the Claude dev team')
except Exception:
    print('An event needs your attention from the Claude dev team')" 2>/dev/null)
fi
MSG="${MSG:-Notification from the Claude dev team}"
# A leading "-" could be read as a command-line option by the tools below; add a space.
case "$MSG" in -*) MSG=" $MSG" ;; esac

# 1) Slack / webhook if configured
if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
  curl -s -X POST -H 'Content-type: application/json' \
    --data "$(python3 -c "import json,sys;print(json.dumps({'text':sys.argv[1]}))" "$MSG")" \
    "$SLACK_WEBHOOK_URL" >/dev/null 2>&1 || true
fi
# 2) Desktop notification. The message is passed as data (an argument, or base64 text),
#    never pasted into script code, so quotes or other characters in it cannot run commands.
if command -v osascript >/dev/null 2>&1; then           # macOS
  osascript -e 'on run argv' -e 'display notification (item 1 of argv) with title "Claude Dev Team"' -e 'end run' "$MSG" >/dev/null 2>&1 || true
elif command -v notify-send >/dev/null 2>&1; then         # Linux
  notify-send "Claude Dev Team" "$MSG" >/dev/null 2>&1 || true
elif command -v powershell.exe >/dev/null 2>&1; then      # Windows/WSL
  B64=$(printf '%s' "$MSG" | base64 | tr -d '\r\n')
  powershell.exe -NoProfile -Command "\$m = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('$B64')); New-BurntToastNotification -Text 'Claude Dev Team', \$m" >/dev/null 2>&1 || true
fi
# 3) Log + print
mkdir -p "$(dirname "$0")/../../proposals" 2>/dev/null || true
echo "[$(date '+%F %T')] $MSG" >> "$(dirname "$0")/../../proposals/notifications.log" 2>/dev/null || true
echo "[notify] $MSG"
