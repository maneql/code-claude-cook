# Claude Code "Dev Team" — Windows Setup Guide (English)

This is the Windows-specific setup for the multi-agent dev team. The **agents and commands are OS-independent** (they are just prompts); only the **hooks, the scheduler, and notifications** differ on Windows. This guide covers a **native PowerShell** setup (recommended) plus **WSL** and **Git Bash** alternatives.

> New here? See `SETUP-GUIDE.md` for the full architecture and the rationale behind the model choices. This file focuses on running it on Windows.

---

## 1. What you get

A virtual software team running inside Claude Code:

```
You → /new-project | /onboard | /feature
        ↓
   orchestrator (opus)
        ↓ delegates to
 intake(haiku) → analyst(haiku) → planner(opus) → coder(sonnet, self-verifies) → reviewer(sonnet) → docwriter(haiku)
 tester(sonnet)    ← opt-in: joins after the coder only when you ask for tests
 explorer(sonnet)  ← maps an existing codebase first
 researcher(sonnet) ← /research: cited findings from primary sources into docs\research\

 Scheduled, isolated:
 Task Scheduler → scripts\scheduled-improve.ps1 → optimizer(opus, PROPOSE-ONLY)
   → writes proposals\*.md → desktop/Slack notification "needs approval"
   → you approve → /apply-proposal → coder/reviewer make the change (tester only if you ask)
```

Model allocation (cost/speed optimized): **Opus for thinking** (orchestrator, planner, optimizer), **Sonnet for doing** (coder/tester/reviewer), **Haiku for templated work** (analyst, docwriter). Every request starts with a cheap **intake** step (haiku) that translates + standardizes it, and the pipeline is **right-sized** (trivial/small/standard) so small changes skip heavy stages. **Tests & git setup are opt-in** (off by default): the coder **self-verifies** each change (build, lint, run/smoke-check), and the tester / `git init` only appear when you ask. This runs on a **single repo with one coder**, and **never commits** — all changes stay local for your review.

---

## 2. Prerequisites

- **Node.js 18+** and **Claude Code**:
  ```powershell
  npm install -g @anthropic-ai/claude-code
  claude            # sign in
  ```
- **PowerShell 5.1** (built into Windows 10/11) or **PowerShell 7+** (`winget install Microsoft.PowerShell`).
- Optional, for nicer notifications: `Install-Module BurntToast -Scope CurrentUser`
- Optional formatters used by the post-edit hook: `black` (Python), `prettier` via `npx` (JS/TS), `gofmt` (Go). All optional — the hook skips silently if a tool is missing.

---

## 3. Choose how Claude Code runs shell commands

Pick **one** of the three. This decides which `settings.json` (hooks) to use.

| Option | When to use | Hooks file to use |
|--------|-------------|-------------------|
| **A. Native PowerShell** (recommended) | Plain Windows, no WSL | `settings.windows.json` (PowerShell `.ps1` hooks) |
| **B. WSL (Ubuntu)** | You already use WSL | `settings.json` (the bash `.sh` hooks) |
| **C. Git Bash** | You have Git for Windows | `settings.json` (the bash `.sh` hooks) |

For **A**, the repo ships both — just make the Windows one active:
```powershell
Copy-Item .claude\settings.windows.json .claude\settings.json -Force
```
For **B/C**, keep the existing `.claude\settings.json` (bash) and make the shell scripts executable inside that shell: `chmod +x .claude/hooks/*.sh scripts/*.sh`.

---

## 4. Install (native PowerShell — Option A)

From your project root in PowerShell:

```powershell
# 1) Copy only .claude\, scripts\ and CLAUDE.md into your repo. Back up an existing
#    CLAUDE.md or .claude\settings.json first - copying replaces files with the same name.

# 2) Activate the Windows hooks
Copy-Item .claude\settings.windows.json .claude\settings.json -Force

# 3) Allow local scripts to run (current user only)
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned

# 4) (Optional) Slack notifications — set a user env var, then restart the shell
setx SLACK_WEBHOOK_URL "https://hooks.slack.com/services/XXX/YYY/ZZZ"

# 5) Open the project with Claude Code and verify
claude
#   then inside Claude Code:
#   /help       -> /new-project /onboard /grill /research /feature /quick /resume /handoff /tune-agents /verify /export-spec /self-improve /apply-proposal
#   agents: ask "which subagents are available?" -> the 11 agents
#   (the /agents wizard was removed in Claude Code 2.1.198; agents are the files in .claude\agents\)
```

> Tip: keep `.claude\` in the repo so the whole team shares it (commit to git). For a personal, cross-project setup, copy `agents\` and `commands\` into `%USERPROFILE%\.claude\` instead.

---

## 5. Daily usage (identical on every OS)

```text
# Brand-new project (greenfield)
/new-project A personal finance tracker in Next.js + Postgres, with login and charts

# Existing project (brownfield) — map it first
/onboard

# Build one feature or fix a bug — full pipeline
/feature Add Google OAuth login
/feature Fix wrong total when a discount code is applied

# Small change — fast lane (skips the heavy pipeline)
/quick Rename the "Submit" button to "Save"
```

`/feature` runs analyst → planner → coder (self-verify: build/run) → reviewer → docwriter — the tester joins only when you ask for tests. It loops back to the coder if the self-verify (or requested tests) fail or review requests changes (max 2 rounds), then reports.

---

## 5b. Autonomous mode (no permission prompts)

To let the team run without asking for permission. The `guard-bash` hook still blocks `git commit`/`git push` and common destructive commands in every mode, but it is a best-effort safety net, not a sandbox, so **use these modes only on repos you trust**:

- **Recommended:** `Copy-Item .claude\settings.autonomous.json .claude\settings.local.json` (delete it to turn off). File edits never prompt; common dev commands are allow-listed; commit/push are denied.
- **Fully unattended:** `powershell -ExecutionPolicy Bypass -File scripts\auto.ps1` (wraps `claude --dangerously-skip-permissions`). Nothing prompts at all, so run it inside a VM or Windows Sandbox where possible.

See `SETUP-GUIDE.md` §4b for details.

---

## 6. Self-improvement + approval gate (Windows Task Scheduler)

This satisfies the requirement: *the system periodically proposes new features / performance optimizations, but must send a notification and require approval before executing.*

### How it stays safe
The scheduled run executes `/self-improve` **headless** with restricted permissions:
```
--permission-mode default
--allowedTools "Read" "Grep" "Glob" "Bash(git log:*)" "Bash(git diff:*)" "Bash(git status:*)" "Write(proposals/**)"
```
There is **no `Edit`**, and `Write` is **path-limited to `proposals\`**. Because it runs unattended, any tool outside that list is **auto-denied** — so the agent **cannot modify code**. It can only write a proposal and notify you. Code only changes when **you** run `/apply-proposal`.

### Register the weekly task
From the repo root (PowerShell):
```powershell
powershell -ExecutionPolicy Bypass -File scripts\register-task.ps1 -RepoDir "C:\path\to\your\repo"
# optional: -DayOfWeek Friday -Time 17:00 -TaskName "MyTeam-SelfImprove"
```
Useful commands:
```powershell
Start-ScheduledTask  -TaskName "ClaudeDevTeam-SelfImprove"     # run now (test it)
Get-ScheduledTask    -TaskName "ClaudeDevTeam-SelfImprove"     # check status
Unregister-ScheduledTask -TaskName "ClaudeDevTeam-SelfImprove" -Confirm:$false  # remove
```

### When a proposal arrives
1. You get a desktop/Slack notification: *"New improvement proposal needs approval: proposals\…"*
2. Open the file under `proposals\` and review the ranked items.
3. To execute approved items:
   ```text
   /apply-proposal proposals\2026-06-16-example.md
   ```

### Prefer CI instead of a local task?
Use the **GitHub Actions** workflow in `SETUP-GUIDE.md` (section 6.2). It generates the proposal and opens a **Pull Request** — merging the PR is the approval. Never let CI edit code or auto-merge.

### Try it right now (no waiting)
```text
/self-improve
```
Then check `proposals\` (a sample `2026-06-16-example.md` shows the format).

---

## 7. Hooks on Windows

`settings.windows.json` wires three PowerShell hooks:

| Hook | Event | What it does |
|------|-------|--------------|
| `guard-bash.ps1` | `PreToolUse` (matcher `Bash\|PowerShell`) | **Blocks** `git commit`/`git push`; git commands that would **discard uncommitted work** (`git reset --hard`, `git checkout .` / `git checkout -- <path>`, `git restore`, `git clean`, `git stash drop/clear`); and destructive commands — recursive `rm` aimed at `/`, `~`, `.`, `*` or a drive, `find -delete`, `Remove-Item -Recurse -Force` (either order), `rd /s`, `rmdir /s`, `del /s`, `format X:`, `mkfs`, `dd if=`, `DROP TABLE/DATABASE`, `git push --force`. Returns exit code 2 so Claude won't run it. If it can't parse the hook input, it checks the raw text instead of letting the command through. |
| `post-edit.ps1` | `PostToolUse` (matcher `Edit\|Write`) | Auto-formats the edited file if `black` / `prettier` / `gofmt` is installed. Never breaks the operation. |
| `notify.ps1` | `Notification` | Sends a Slack message (if `SLACK_WEBHOOK_URL` set) and a desktop toast (BurntToast or tray balloon); logs to `proposals\notifications.log`. |

Each hook reads the event JSON from **stdin** (`[Console]::In.ReadToEnd()`), so it works the same way Claude Code calls hooks on macOS/Linux.

> **Keep hooks ASCII-only.** Windows PowerShell reads `.ps1` files in the system ANSI codepage, so a non-ASCII character (em-dash, smart quotes) makes it fail to parse - you'll see `PreToolUse:Bash hook error ... At ...guard-bash.ps1:<line> char:<n>`, and a crashed guard silently stops blocking commits/destructive commands. The shipped hooks are ASCII-only; if you edit one, keep it ASCII (or save the file as UTF-8 **with BOM**).

---

## 9. File map (Windows-relevant)

```
claude-dev-team\
├─ .claude\
│  ├─ settings.json            # active hooks (copy from one of the two below)
│  ├─ settings.windows.json    # PowerShell hooks  (Option A)
│  ├─ settings.autonomous.json # OPTIONAL: no-prompt permissions overlay
│  ├─ agents\ ...              # 11 agents (intake, orchestrator, analyst, planner, coder, tester, reviewer, docwriter, explorer, researcher, optimizer)
│  ├─ commands\ ...            # /new-project /onboard /grill /research /feature /quick /resume /handoff /tune-agents /verify /export-spec /self-improve /apply-proposal
│  └─ hooks\
│     ├─ guard-bash.ps1  post-edit.ps1  notify.ps1     # Windows (PowerShell)
│     └─ guard-bash.sh   post-edit.sh   notify.sh      # WSL / Git Bash (bash)
├─ scripts\
│  ├─ scheduled-improve.ps1    # Task Scheduler entrypoint (Windows)
│  ├─ register-task.ps1        # one-liner to register the weekly task
│  ├─ scheduled-improve.sh     # cron entrypoint (WSL / Git Bash / macOS / Linux)
│  ├─ auto.sh | .ps1           # OPTIONAL: launch with no permission prompts
│  └─ export-spec.py           # JSON -> .xlsx (used by /export-spec; Windows: python scripts\export-spec.py)
├─ proposals\                  # proposals + notifications.log
├─ CLAUDE.md                   # shared team rules
├─ README.md
├─ SETUP-GUIDE.md              # full guide
└─ SETUP-WINDOWS.md            # this file
```

That's it — copy the bundle in, activate the Windows hooks, register the weekly task, and start with `/new-project` or `/onboard`.
