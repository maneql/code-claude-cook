# Max-autonomy launch (Windows): NO permission prompts (bypass mode) - the AI can run any
# command without asking. Use it only in a repo you trust, ideally inside a VM or Windows
# Sandbox. The PreToolUse guard hook still blocks common git commit/push and destructive
# commands, but it is a best-effort safety net that matches command text, not a sandbox.
# Usage: powershell -ExecutionPolicy Bypass -File scripts\auto.ps1
#        ... -File scripts\auto.ps1 -p "/feature add X"
claude --dangerously-skip-permissions @args
