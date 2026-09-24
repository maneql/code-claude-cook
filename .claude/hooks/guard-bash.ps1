# PreToolUse hook (Bash AND PowerShell tools): block commits/pushes, commands that
# discard uncommitted work, and destructive commands. exit 2 = block, stderr = reason.
# This is a best-effort safety net that matches command text - it is not a sandbox.
# Keep this file ASCII-only (see SETUP-WINDOWS.md section 7).
$ErrorActionPreference = 'SilentlyContinue'
$raw = [Console]::In.ReadToEnd()
# Read tool_input.command. If that fails, check the raw hook input instead, so the guard
# fails closed rather than silently allowing everything.
$cmd = $null
try { $cmd = ($raw | ConvertFrom-Json).tool_input.command } catch {}
$note = ''
if (-not $cmd) { $cmd = $raw; $note = ' (could not parse the hook input, so the raw input was checked)' }
if (-not $cmd) { exit 0 }
if ($cmd -match '\bgit\b.*\b(commit|push)\b') {
  [Console]::Error.WriteLine("[guard] Commits/pushes are disabled - changes are kept LOCAL for your review. Stage/diff is fine; please commit yourself.$note")
  exit 2
}
# git commands that DISCARD uncommitted work (the working tree holds the only copy):
# reset --hard, clean, restore, stash drop/clear, checkout . / checkout * / checkout -- <path>
$discard = @(
  '\bgit\b[^|;&]*\s(reset[^|;&]*--hard|clean(\s|$)|restore(\s|$)|stash\s+(drop|clear))',
  '\bgit\b[^|;&]*\scheckout(\s+(\.|\*)|[^|;&]*\s--(\s|$))'
)
foreach ($p in $discard) {
  if ($cmd -match $p) {
    [Console]::Error.WriteLine("[guard] Blocked: this would discard uncommitted work (the working tree holds the only copy): $cmd$note")
    exit 2
  }
}
# Destructive commands (same rules as guard-bash.sh; -match ignores case):
# - recursive rm (-rf, -fr, -r -f, -R, --recursive) aimed at / ~ * . $HOME or a drive (C:)
# - find with -delete or -exec/-execdir rm
# - Remove-Item with -Recurse and -Force in any order (or -r / -fo), rd|rmdir|del /s, format X:
$patterns = @(
  '\brm(\s+-\S*)*\s+(-[a-z]*r[a-z]*|--recursive)(\s+-\S*)*\s+(\\?["''])?(/|~|\*|\.|\$HOME|\$\{HOME\}|[a-z]:)',
  '\bfind\b[^|;&]*\s(-delete\b|-exec(dir)?\s+rm\b)',
  'Remove-Item[^|;&]*(-r[a-z]*\b[^|;&]*-fo[a-z]*\b|-fo[a-z]*\b[^|;&]*-r[a-z]*\b)',
  '\b(rd|rmdir|del)\s+/s', '\bformat\s+[a-z]:',
  'mkfs', ':\(\)\{', 'dd\s+if=',
  'DROP\s+(TABLE|DATABASE)',
  'git\s+push\s+.*--force'
)
foreach ($p in $patterns) {
  if ($cmd -match $p) {
    [Console]::Error.WriteLine("[guard] Blocked potentially destructive command: $cmd$note")
    exit 2
  }
}
exit 0
