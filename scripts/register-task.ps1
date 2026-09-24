# Registers a weekly Windows Scheduled Task that runs the propose-only self-improve.
# Usage (from repo root):
#   powershell -ExecutionPolicy Bypass -File scripts\register-task.ps1 -RepoDir "C:\path\to\repo"
# Remove later:  Unregister-ScheduledTask -TaskName "ClaudeDevTeam-SelfImprove"
param(
  [string]$RepoDir   = (Get-Location).Path,
  [string]$Time      = "09:00",
  [string]$DayOfWeek = "Monday",
  [string]$TaskName  = "ClaudeDevTeam-SelfImprove"
)
$script  = Join-Path $RepoDir "scripts\scheduled-improve.ps1"
if (-not (Test-Path $script)) { throw "Not found: $script" }
$action  = New-ScheduledTaskAction  -Execute "powershell.exe" `
            -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$script`" -RepoDir `"$RepoDir`""
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $DayOfWeek -At $Time
Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger `
  -Description "Weekly Claude self-improve (propose-only, requires approval to apply)" -Force | Out-Null
Write-Output "Registered task '$TaskName' ($DayOfWeek $Time)."
Write-Output "Run now:  Start-ScheduledTask -TaskName '$TaskName'"
Write-Output "Remove:   Unregister-ScheduledTask -TaskName '$TaskName' -Confirm:`$false"
