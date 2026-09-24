# Notification helper. Works from a hook (reads JSON on stdin) or called directly with -Message.
param([string]$Message = "")
$ErrorActionPreference = 'SilentlyContinue'
if (-not $Message) {
  $raw = [Console]::In.ReadToEnd()
  if ($raw) { try { $j = $raw | ConvertFrom-Json; $Message = $j.message; if (-not $Message) { $Message = $j.reason } } catch {} }
}
if (-not $Message) { $Message = "Notification from Claude dev team" }

# 1) Slack / webhook
if ($env:SLACK_WEBHOOK_URL) {
  try { Invoke-RestMethod -Uri $env:SLACK_WEBHOOK_URL -Method Post -ContentType 'application/json' -Body (@{ text = $Message } | ConvertTo-Json) | Out-Null } catch {}
}
# 2) Desktop notification (BurntToast if installed, else tray balloon)
if (Get-Module -ListAvailable -Name BurntToast) {
  try { Import-Module BurntToast; New-BurntToastNotification -Text "Claude Dev Team", $Message } catch {}
} else {
  try {
    Add-Type -AssemblyName System.Windows.Forms
    $n = New-Object System.Windows.Forms.NotifyIcon
    $n.Icon = [System.Drawing.SystemIcons]::Information
    $n.Visible = $true
    $n.ShowBalloonTip(5000, "Claude Dev Team", $Message, [System.Windows.Forms.ToolTipIcon]::Info)
  } catch {}
}
# 3) Log
try {
  $log = Join-Path $PSScriptRoot "..\..\proposals\notifications.log"
  "$([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss')) $Message" | Out-File -FilePath $log -Append -Encoding utf8
} catch {}
Write-Output "[notify] $Message"
