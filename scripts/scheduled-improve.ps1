# Runs PERIODICALLY (Windows Task Scheduler). Generates improvement proposals in
# PROPOSE-ONLY mode, then notifies. Safety: headless run with restricted allowedTools
# (no Edit; Write limited to proposals/**) => the agent CANNOT modify code.
param([string]$RepoDir = (Get-Location).Path)
$ErrorActionPreference = 'Continue'
Set-Location $RepoDir
New-Item -ItemType Directory -Force -Path "proposals" | Out-Null
$env:CLAUDE_PROJECT_DIR = $RepoDir
Write-Output "[$([DateTime]::Now)] Starting self-improve in $RepoDir"

claude -p "/self-improve" `
  --permission-mode default `
  --allowedTools "Read" "Grep" "Glob" "Bash(git log:*)" "Bash(git diff:*)" "Bash(git status:*)" "Write(proposals/**)" `
  *>> "proposals\self-improve.log"

$latest = Get-ChildItem "proposals\*.md" -ErrorAction SilentlyContinue |
          Where-Object { $_.Name -notlike "*notifications*" } |
          Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($latest) {
  $msg = "New improvement proposal needs approval: $($latest.FullName)  ->  run: claude `"/apply-proposal proposals/$($latest.Name)`""
  & "$RepoDir\.claude\hooks\notify.ps1" -Message $msg
} else {
  Write-Output "No proposal generated (see proposals\self-improve.log)"
}
