# Changelog

## Unreleased — security fixes

If you already copied the kit into a project, copy these files again: `.claude/hooks/guard-bash.sh`, `.claude/hooks/guard-bash.ps1`, `.claude/hooks/notify.sh`, `.claude/settings.json`, `scripts/export-spec.py`.

- **The guard hook fails closed.** It used to allow every command when `python3` was missing. It now checks the raw hook input instead (`guard-bash.sh`, `guard-bash.ps1`).
- **The guard blocks more destructive forms:**
  - `rm -r -f /`, `rm --recursive --force ~`, `rm -R`, and drive targets (`C:`)
  - `find -delete` and `find -exec rm`
  - `Remove-Item -Force -Recurse` in either order, and `rmdir /s`
- **Hook paths are quoted in `.claude/settings.json`.** Before, the hooks silently didn't run when the project path contained a space.
- **`notify.sh` no longer runs message text as code** on macOS or on Windows (Git Bash/WSL).
- **`export-spec.py` fixes:**
  - Spec text that starts with `=` stays text, so it can't become an Excel formula.
  - The script no longer runs `pip install --break-system-packages openpyxl` without asking.
- **Docs:**
  - The guard is now described as a best-effort safety net, not a sandbox.
  - Autonomous and skip-permissions modes are marked for trusted repos only.
  - Setup says exactly which files to copy and warns before existing files are replaced.

## 1.0 — 2026-09-24

- First public release.
