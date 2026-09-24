#!/usr/bin/env bash
# PostToolUse hook for Edit|Write: auto-format the edited file (if a formatter exists). Never fails the tool.
INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | python3 -c "import sys,json
try:
    print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))
except Exception:
    print('')" 2>/dev/null)
[ -z "$FILE" ] && exit 0
case "$FILE" in
  *.py)  command -v black >/dev/null 2>&1 && black -q "$FILE" >/dev/null 2>&1 || true ;;
  *.ts|*.tsx|*.js|*.jsx|*.json|*.css|*.md)
         command -v npx >/dev/null 2>&1 && npx --no-install prettier -w "$FILE" >/dev/null 2>&1 || true ;;
  *.go)  command -v gofmt >/dev/null 2>&1 && gofmt -w "$FILE" >/dev/null 2>&1 || true ;;
  *.cs)  if command -v csharpier >/dev/null 2>&1; then csharpier "$FILE" >/dev/null 2>&1; elif command -v dotnet >/dev/null 2>&1; then dotnet format --include "$FILE" >/dev/null 2>&1; fi; true ;;
esac
exit 0
