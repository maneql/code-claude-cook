#!/usr/bin/env bash
# Max-autonomy launch: NO permission prompts (bypass mode) - the AI can run any command
# without asking. Use it only in a repo you trust, ideally inside a container or VM.
# The PreToolUse guard hook still blocks common git commit/push and destructive commands,
# but it is a best-effort safety net that matches command text, not a sandbox.
# Usage: scripts/auto.sh            (interactive, no prompts)
#        scripts/auto.sh -p "/feature add X"   (headless)
exec claude --dangerously-skip-permissions "$@"
