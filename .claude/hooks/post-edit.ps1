# PostToolUse hook (Edit|Write): auto-format the edited file if a formatter exists. Never fails the tool.
$ErrorActionPreference = 'SilentlyContinue'
$raw = [Console]::In.ReadToEnd()
try { $j = $raw | ConvertFrom-Json } catch { exit 0 }
$file = $j.tool_input.file_path
if (-not $file) { exit 0 }
switch -Regex ($file) {
  '\.py$'                          { if (Get-Command black -ErrorAction SilentlyContinue) { black -q "$file" } }
  '\.(ts|tsx|js|jsx|json|css|md)$' { if (Get-Command npx   -ErrorAction SilentlyContinue) { npx --no-install prettier -w "$file" } }
  '\.go$'                          { if (Get-Command gofmt -ErrorAction SilentlyContinue) { gofmt -w "$file" } }
  '\.cs$'                          { if (Get-Command csharpier -ErrorAction SilentlyContinue) { csharpier "$file" } elseif (Get-Command dotnet -ErrorAction SilentlyContinue) { dotnet format --include "$file" } }
}
exit 0
