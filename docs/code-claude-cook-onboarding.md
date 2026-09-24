# code-claude-cook — Onboarding

> **Updated 2026-09-24 after the publish-risk fixes.** The guard fails closed and covers more patterns, hook paths are quoted, `notify.sh` passes messages as data, `export-spec.py` blocks formula injection and never auto-installs, the safety wording is corrected, and a `.gitignore` was added. The maintainer profile (checks, models, prompt style) now lives at the end of this doc.

## What this repo is
Not an application — a portable **Claude Code "virtual dev team" config kit**. The product IS
the configuration: subagent prompts, slash commands, hooks, and settings under `.claude/`, plus
`scripts/` and a root `CLAUDE.md` rulebook meant to be copied into a *target* project. There is no
package.json/pyproject/go.mod/`*.sln` — this repo builds nothing and has no runtime of its own.
As of commit `693a7be Cook 1.0` everything is tracked and the working tree is clean except a new
`docs/` folder (this doc) and a pre-existing, untracked `docs/state/tune-agents.md` left by a
separate, apparently interrupted `/tune-agents` run (not created by this pass — see Risks).

Verified inventory (via `find`/`git ls-files`): **11** agents, **13** commands, **6** hook files
(3 hooks × sh/ps1), **3** settings files, **7** files under `scripts/`, **3** files under
`proposals/`. Matches README.md:5's "Verified bundle: 11 agents, 13 commands."

## Languages/runtimes (no versions declared in-repo; observed on this machine)
Markdown+YAML frontmatter (agents/commands) · JSON (settings, spec template) · Bash (`.sh` hooks
+ scripts, plus inline `python3 -c` JSON parsing inside them) · PowerShell (`.ps1` twins) ·
Python 3 (`scripts/export-spec.py`). No shebang/engine version pins anywhere. Observed here:
`python` = 3.11.2 with `openpyxl` 3.1.5 already installed; `python3` = a *different*, WindowsApps
alias interpreter (3.14.3) without `openpyxl`; pwsh 7.6.6 and Windows PowerShell 5.1 both present;
git 2.35.1 with `core.fileMode=false`, `core.autocrlf=true`; Git Bash 4.4.23; Node present (only
needed to install the `claude` CLI itself, nothing in-repo depends on it).

## Module map

### `.claude/agents/` — 11 subagent personas (YAML frontmatter: `name`, `description`, `tools`, `model`)
| Agent | Model | Tools | Writes to |
|---|---|---|---|
| `intake` | haiku | Read, Write | `docs/intake/<slug>.md` + `INTAKE:` line |
| `orchestrator` | opus | **Agent**, Read, Grep, Glob, Bash, Write | `docs/state/<slug>.md` (only agent that can delegate via `Agent`) |
| `analyst` | haiku | Read, Grep, Glob, Write | `docs/specs/<feature>.md` |
| `planner` | opus | Read, Grep, Glob, Write | `docs/plans/<feature>.md` (+ rare `docs/adr/`) |
| `coder` | sonnet | Read, Edit, Write, Grep, Glob, Bash | product code (uncommitted) |
| `tester` | sonnet | Read, Write, Edit, Grep, Glob, Bash | tests — opt-in only (`tests=on`) |
| `reviewer` | sonnet | Read, Grep, Glob, Bash (**no Write/Edit**) | review notes only — read-only is tool-enforced, not just prompted |
| `docwriter` | haiku | Read, Write, Edit, Grep, Glob | README/CHANGELOG |
| `explorer` | sonnet | Read, Grep, Glob, Bash, Write | `docs/<project>-onboarding.md` (this doc) |
| `researcher` | sonnet | Read, Grep, Glob, WebSearch, WebFetch, Write | `docs/research/<slug>.md` |
| `optimizer` | opus | Read, Grep, Glob, Bash, Write | `proposals/<date>-<slug>.md` (path restriction is prompt-only at this layer — see Risks) |

### `.claude/commands/` — 13 slash commands (frontmatter: `description`, `argument-hint`; one exception below)
Each command's body says **"Act as the orchestrator"** and then delegates stage-by-stage via the
`Agent` tool — `new-project`, `onboard`, `feature`, `quick`, `verify`, `tune-agents`,
`apply-proposal`, `resume` all follow this shape. Three commands skip the orchestrator and
delegate straight to one named subagent: `grill.md` → `analyst` (interview mode), `research.md`
→ `researcher`, and `self-improve.md` → `optimizer`. `handoff.md` has no persona framing — it
just writes a checkpoint from the current session. `self-improve.md` is the odd one out
structurally: instead of `argument-hint` it carries `allowed-tools: Read, Grep, Glob,
Bash(git log/diff/status:*), Write(proposals/**)` and `model: opus` directly in its own
frontmatter — a second, command-level enforcement of "propose only" on top of `optimizer.md`'s
prompt text.

### `.claude/hooks/` — 3 hooks × {`.sh`, `.ps1`} = 6 files
| Hook | Event / matcher | Behavior |
|---|---|---|
| `guard-bash.{sh,ps1}` | `PreToolUse`, matcher `Bash\|PowerShell` | Blocks `git commit`/`git push`, work-discarding git (`reset --hard`, `checkout .`/`checkout -- <path>`, `restore`, `clean`, `stash drop/clear`), and destructive commands (`rm -rf /`, `Remove-Item -Recurse -Force`, `mkfs`, `dd if=`, `DROP TABLE/DATABASE`, `git push --force`, etc.). Exit 2 + stderr = block; exit 0 = allow. |
| `post-edit.{sh,ps1}` | `PostToolUse`, matcher `Edit\|Write` | Best-effort auto-format (`black`/`prettier`/`gofmt`/`csharpier`) by file extension; always exits 0, never fails the parent edit. |
| `notify.{sh,ps1}` | `Notification` (also called **directly**, not through the hook system, by `scheduled-improve.{sh,ps1}` with a custom message) | Slack webhook (`SLACK_WEBHOOK_URL`) if set, else a desktop toast (osascript/notify-send/BurntToast/tray balloon); always appends to `proposals/notifications.log`. |

**Implementation asymmetry:** `guard-bash.sh`/`post-edit.sh`/`notify.sh` parse the hook's stdin
JSON with inline Python; the `.ps1` twins use native `ConvertFrom-Json`. The guard tries `python3`,
then `python`, and if neither can parse the input it checks the raw text (fails closed).

### `.claude/settings*.json` — which file wires what
- `settings.json` (**currently active**): wires all 3 hooks by invoking the `.sh` file path
  directly (`"$CLAUDE_PROJECT_DIR"/.claude/hooks/guard-bash.sh`, quoted so project paths with
  spaces work) — requires the executable bit + a working shebang.
- `settings.windows.json`: same 3 hooks, invoked as `powershell -NoProfile -ExecutionPolicy
  Bypass -File "...\guard-bash.ps1"` — no executable bit needed. README.md:15 / SETUP-WINDOWS.md:58
  say to copy this over `settings.json` for native PowerShell use.
- `settings.autonomous.json`: **no `hooks` key at all** — only a `permissions` block
  (`defaultMode: acceptEdits`, an `allow` list of common dev commands, a `deny` list covering
  `git commit`/`git push`/`sudo`/work-discarding git in both Bash and PowerShell forms). Meant to
  be copied to the untracked `settings.local.json`, which Claude Code merges **over** whichever of
  the two files above is active — it changes prompting behavior, not hook wiring.

### `scripts/` — 7 files
- `auto.sh` / `auto.ps1`: thin wrappers around `claude --dangerously-skip-permissions "$@"` —
  **interactive**, just removes permission prompts (not headless).
- `scheduled-improve.sh` / `.ps1`: the cron / Task-Scheduler entry point — **headless**:
  `claude -p "/self-improve" --permission-mode default --allowedTools "Read" "Grep" "Glob"
  "Bash(git log:*)" "Bash(git diff:*)" "Bash(git status:*)" "Write(proposals/**)"`, output to
  `proposals/self-improve.log`, then finds the newest `proposals/*.md` and calls
  `notify.{sh,ps1}` directly with an "apply it" message.
- `register-task.ps1`: one-shot helper — creates a real Windows weekly Scheduled Task that runs
  `scheduled-improve.ps1`.
- `export-spec.py`: the only non-prompt "business logic" in the repo — renders
  `docs/spec/<project>-spec.json` into a styled multi-sheet `.xlsx` via `openpyxl`. If openpyxl is
  missing, it prints the install command and exits; it never installs packages itself. Text that
  starts with `=` is written as text, never as a live formula. Sheets/columns are data-driven,
  not hardcoded.
- `spec-template.json`: worked example of the JSON schema `export-spec.py` expects.

### `proposals/`
`2026-06-16-example.md` (sample proposal, explicitly marked "delete it when you go live" — still
present), `.gitkeep`, `notifications.log` (a live runtime log; untracked and git-ignored).

### Root docs
`CLAUDE.md` (shared rulebook, loaded into every agent every session — see Cross-file coupling),
`README.md` (pitch, workflow diagrams, commands/agents tables, safety net), `SETUP-GUIDE.md`
(full rationale + install + self-improve/CI details), `SETUP-WINDOWS.md` (Windows-specific
install + Task Scheduler), `LICENSE` (MIT, copyright "maneql" 2026 — the only file tracked before
`693a7be`).

## Control flow (how a request turns into files)
`you type /feature ...` → command file (`.claude/commands/feature.md`) frames the main session as
**orchestrator** → orchestrator delegates to `intake` (Agent tool) → intake writes
`docs/intake/<slug>.md` and returns one `INTAKE: type=.. size=.. slug=.. tests=.. git=..` line →
orchestrator right-sizes (trivial/small/standard) and delegates to `analyst` → `planner` →
`coder` → optionally `tester` (only if `tests=on`) → `reviewer` → `docwriter`, each reading/
writing its own `docs/<stage>/<slug>.md` file — the orchestrator itself only holds short
checkpoints (`docs/state/<slug>.md`), never full file contents. Nothing is committed by any agent;
the guard hook is the actual enforcement of that rule, independent of what any prompt says.

## Common commands (verified where noted)
| Purpose | Command | Verified this session |
|---|---|---|
| Install Claude Code | `npm install -g @anthropic-ai/claude-code && claude` | Documented only (README.md:11-20); not run |
| Activate Windows hooks | `Copy-Item .claude\settings.windows.json .claude\settings.json -Force` | Documented (README.md:15, SETUP-WINDOWS.md:58/72); not run (would change active hook wiring) |
| Activate bash hooks | `chmod +x .claude/hooks/*.sh scripts/*.sh` | Documented (README.md:16, SETUP-GUIDE.md:120-122, SETUP-WINDOWS.md:60); not run — read-only pass |
| Enable autonomous overlay | `cp .claude/settings.autonomous.json .claude/settings.local.json` | Documented only |
| Fully unattended launch | `claude --dangerously-skip-permissions` / `scripts/auto.sh` / `scripts\auto.ps1` | Script bodies read and confirmed to just wrap that flag; not executed |
| Run the kit | `/new-project`, `/onboard`, `/feature`, `/quick`, `/grill`, `/research`, `/verify`, `/resume`, `/handoff`, `/tune-agents`, `/self-improve`, `/apply-proposal`, `/export-spec` | All 13 confirmed present as `.claude/commands/*.md` with valid frontmatter |
| Register weekly Windows task | `powershell -ExecutionPolicy Bypass -File scripts\register-task.ps1 -RepoDir "<path>"` | Logic read/confirmed; **not run** (would create a real Scheduled Task) |
| **Validate settings JSON** | `python -m json.tool .claude/settings.json` (repeat for `.windows.json`, `.autonomous.json`, `scripts/spec-template.json`) | **RAN — all 4 valid** |
| **Syntax-check bash files** | `bash -n <file>` on all 5 `.sh` files | **RAN — all 5 pass** |
| **Syntax-check PowerShell files** | `[System.Management.Automation.Language.Parser]::ParseFile(...)` via `pwsh -NoProfile -File` on all 6 `.ps1` files | **RAN — all 6 pass, no parse errors** |
| **Export a spec workbook** | `python scripts/export-spec.py scripts/spec-template.json <out>.xlsx` (Windows: `python`, not the WindowsApps `python3` stub) | **RAN against the sample template → produced a valid .xlsx** (openpyxl already present, no install needed) |

**Does not exist:** no test suite/framework, no CI (`.github/` absent), no linter/formatter
config for the kit's own files (no `.editorconfig`, no shellcheck/PSScriptAnalyzer config — and
neither tool is installed on this machine), no `.gitattributes`, no `CONTEXT.md` yet (a
`.gitignore` exists since 2026-09-24). `docs/specs|plans|intake|research|fixes|adr|spec/` don't exist yet either — they're created
on demand by the pipeline; only `docs/state/tune-agents.md` pre-dates this pass.

## Important files and roles
- `CLAUDE.md` — shared rulebook loaded into **every** agent's context every session; source of
  truth for SDLC stages, right-sizing, opt-in tests/git, the commit/push ban, and the
  auto-generated Project profile block (`CLAUDE.md:74-76`, currently the empty placeholder).
- `.claude/agents/orchestrator.md` — leader persona; the only agent with the `Agent` tool.
- `.claude/agents/coder.md` — sole implementation agent; "one repo, one coder" lives here too.
- `.claude/hooks/guard-bash.sh` / `.ps1` — actual enforcement of "never commit/push" / "no
  destructive commands"; everything else about safety is just prompt text on top of this.
- `.claude/commands/self-improve.md` + `scripts/scheduled-improve.{sh,ps1}` — the two places that
  hard-restrict the optimizer's tools via `--allowedTools`/`allowed-tools` (not just its prompt).
- `scripts/export-spec.py` + `scripts/spec-template.json` — the one real script; verified working.
- `proposals/notifications.log` — live notification log; untracked and git-ignored.
- `README.md` / `SETUP-GUIDE.md` / `SETUP-WINDOWS.md` — see Mismatches below for where they
  disagree with each other and with the files on disk.

## Things to know before changing anything

### Cross-file coupling
- "Never commit/push" is asserted in four independent places that must stay in sync:
  `CLAUDE.md:62`, `orchestrator.md`'s "Never commit" section, `coder.md`'s rules, and the
  `deny` lists in the settings files — plus the guard hook, which is the only one that's actually
  *enforced* rather than *asked for*.
- `intake.md`'s exact output contract, the line `INTAKE: type=<type> size=<size> slug=<slug>
  tests=<on|off> git=<on|off>`, is parsed by `orchestrator.md` (`size=`/`slug=`). The `tests=on` /
  `git=on` flags are also referenced by `coder.md`, `planner.md`, `reviewer.md`, `tester.md`,
  `feature.md` and `CLAUDE.md`. Changing that format breaks every consumer silently.
- Model routing (opus: orchestrator/planner/optimizer + `self-improve.md`'s own frontmatter;
  sonnet: coder/tester/reviewer/explorer/researcher; haiku: intake/analyst/docwriter) is declared
  three times: each agent's frontmatter `model:` field, README.md:145-159's table, and
  SETUP-GUIDE.md:50-64's table — three places to update together.
- `guard-bash.sh`/`guard-bash.ps1` are hand-maintained parallel implementations (regex sets
  compared line-by-line; equivalent today) with no shared source and no test — an edit to one
  side only will silently desync platform behavior.
- Hook contract: `PreToolUse` hooks read the tool-call JSON from stdin; exit 2 + stderr = block,
  exit 0 = allow. `PostToolUse`/`Notification` hooks are fire-and-forget (always exit 0).
  `settings.autonomous.json` never wires hooks itself — it only loosens/tightens permissions and
  is layered in as `settings.local.json` on top of `settings.json` or `settings.windows.json`.
- Two independent layers guard commit/push: the `permissions.deny` list stops a prompt from even
  appearing; the guard hook hard-blocks execution regardless of permission mode, including
  `--dangerously-skip-permissions`. Only the hook is unconditional.
- The optimizer's "propose-only" guarantee is enforced at the **command/CLI** layer
  (`self-improve.md`'s `allowed-tools`, and `scheduled-improve.*`'s `--allowedTools`, both
  path-restricting `Write` to `proposals/**`), not at the agent-definition layer —
  `optimizer.md`'s own `tools:` list is a plain, unrestricted `Write`. A route that invokes the
  optimizer subagent without going through those two entry points relies on prompt text alone.

### Platform gotchas
- **The guard fails closed (fixed 2026-09-24).** It used to allow everything when `python3` was
  missing (reproduced). Now `guard-bash.sh` tries `python3`, then `python`, and if neither can
  parse the input it checks the raw hook text. `guard-bash.ps1` does the same when
  `ConvertFrom-Json` fails. `post-edit.sh` and `notify.sh` still need `python3`, but only for
  formatting and notification text, not for safety.
- **`python` ≠ `python3` on this Windows machine.** `python` → 3.11.2 with `openpyxl` installed;
  `python3` → a separate WindowsApps-alias interpreter (3.14.3) without it. `export-spec.md:34-35`
  correctly tells Windows users to run `python`, not `python3` — worth keeping that distinction if
  anyone edits the docs.
- **Executable bits don't survive `git` here.** `core.fileMode=false` locally, so `chmod +x`
  never registers as a diff, and the index already stores every `.sh`/`.ps1`/`.py` as `100644`
  (confirmed via `git ls-files -s`). A clone onto a `core.fileMode=true` system (typical
  macOS/Linux) needs the documented `chmod +x .claude/hooks/*.sh scripts/*.sh` — nothing in the
  repo (no `.gitattributes`, no CI) sets or enforces this automatically.
- **No `.gitattributes`; line endings are LF today but unpinned.** `core.autocrlf=true` locally;
  currently both the index and working tree are LF for the shell scripts (no corruption today),
  but nothing stops a future Windows-side edit from introducing CRLF into a `.sh` file, which can
  break its shebang/parsing on Linux/macOS/WSL.
- **PowerShell hooks must stay ASCII.** Windows PowerShell 5.1 reads `.ps1` in the system ANSI
  codepage; a stray em-dash/smart-quote breaks parsing and silently disables the guard
  (documented at `SETUP-WINDOWS.md:180`). All 6 `.ps1` files currently parse cleanly and are
  ASCII.

### README / SETUP mismatches found
- Fixed 2026-09-24: the directory tree in `SETUP-GUIDE.md` §3 said "10 subagents" and listed only
  10 commands (missing `researcher.md`, `grill.md`, `research.md`, `handoff.md`). It now matches
  the real 11 agents and 13 commands, like `README.md:5` and `SETUP-WINDOWS.md` §9.
- Everything else checked (agent frontmatter fields, both hooks tables, README's commands/agents
  tables, install steps, `export-spec.py`'s CLI contract) matched the real files.

## Risks and tech debt
- **`.gitignore` added (2026-09-24)** for `settings.local.json`, `proposals/*.log`, `docs/state/`,
  `__pycache__/`, `*.pyc` and `*.xlsx`. `proposals/notifications.log` was untracked.
- **No CI/tests/lint for the kit's own files** — nothing currently catches a broken hook or
  malformed JSON except a manual pass like this one (see Common commands for the checks that
  would be cheap to wire into a CI job: JSON validate, `bash -n`, PowerShell AST parse).
- **The guard is a text-matching safety net, not a sandbox.** Its `python3` single point of
  failure is fixed (it now fails closed) and its patterns were widened, but a determined command
  can still slip past regexes. The docs now say so.
- `CLAUDE.md`'s Project profile block is still the empty placeholder — expected, since this repo
  has no app of its own to tune against; it only matters once this kit is copied elsewhere.
- `docs/state/tune-agents.md` (untracked) is the checkpoint of the `/tune-agents` run that
  commissioned this doc; that run was interrupted by a usage limit and then resumed. Its model
  names ("Opus 5.5", "Fable 5.1") come from the environment and the claude-api skill's model
  table, not from this repo.
- `proposals/2026-06-16-example.md` is explicitly marked "SAMPLE ... delete it when you go live"
  but is still present and already committed as of `693a7be`.
- The duplicated policy text called out under Cross-file coupling (commit/push ban, model
  routing, agent/command counts) has no automated check keeping copies in sync — the README/SETUP
  mismatches above are that exact failure mode, already realized once.

## Not covered in this pass
No live pipeline was executed (no real `/feature`, `/self-improve`, `/apply-proposal`,
`/tune-agents`, `/onboard`, `/grill`, `/verify` run). No Windows Scheduled Task was registered, no
real Slack/BurntToast notification was sent, and the guard hook was not exercised live by this
agent (a live `git push` block via Git Bash on this machine was already confirmed separately).
This was a static, read-only review of the files plus the syntax/JSON/export-spec checks listed
under Common commands.

## Maintainer profile (moved from CLAUDE.md)
Generated by `/tune-agents` on 2026-09-24. It lives here, not in `CLAUDE.md`, because `CLAUDE.md`
ships to users as a template and must keep its empty placeholder.

**Checks** (Bash tool, repo root; all verified 2026-09-24). There is no test, lint or format tooling.
```bash
# JSON (settings + spec template)
python -c "import json,sys; [json.load(open(f, encoding='utf-8')) for f in sys.argv[1:]]; print('json ok', len(sys.argv) - 1)" .claude/settings*.json scripts/spec-template.json
# Bash syntax
for f in .claude/hooks/*.sh scripts/*.sh; do bash -n "$f" && echo "ok $f" || echo "FAIL $f"; done
# PowerShell syntax, with the 5.1 parser that runs the Windows hooks
powershell -NoProfile -Command 'Get-ChildItem .claude/hooks/*.ps1, scripts/*.ps1 | ForEach-Object { $e = $null; [void][Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$e); if ($e) { "FAIL $($_.Name): $($e[0].Message)" } else { "ok $($_.Name)" } }'
# Python syntax (py_compile would leave scripts/__pycache__/ behind)
python -c "import ast; ast.parse(open('scripts/export-spec.py', encoding='utf-8').read()); print('py ok')"
# Hook smoke test: exit 0 = allow, 2 = block (.ps1 twin: pipe into powershell -NoProfile -ExecutionPolicy Bypass -File .claude/hooks/guard-bash.ps1)
printf '{"tool_input":{"command":"ls"}}' | bash .claude/hooks/guard-bash.sh; echo "exit=$?"
```
- To test the guard's block path, write the JSON payload to a file and pipe it in. The live guard blocks any command line that contains the blocked words itself.
- The `post-edit` hook reformats edited `.py` files with `black`. For a minimal diff, write the file from the shell instead.

**Models.** `model:` uses family aliases, which follow the newest release. As of 2026-09:
- `opus` = Opus 5.5: orchestrator, planner, optimizer, `/self-improve`
- `sonnet` = Sonnet 5: coder, explorer, researcher, reviewer, tester
- `haiku` = Haiku 4.5: intake, analyst, docwriter

Keep aliases rather than dated IDs. Thinking depth is set with `/effort`, not with prompt text.

**Prompt style for current models** (agents, commands, `CLAUDE.md`). These models follow instructions literally:
- State each rule once, with its reason. Stacked MUST/NEVER/CRITICAL makes them over-apply rules.
- Describe the outcome and how to verify it. Use numbered steps only where order matters.
- Leave out "think step by step", "be thorough" and "don't narrate" lines.
- A frontmatter `description` is routing text: say exactly when to use the agent.
- Subagents start cold. A delegation prompt carries the goal, the paths, the constraints and the expected reply shape.

**Change together** (nothing keeps these in sync automatically):
- **Commit/push ban:** `CLAUDE.md`, `orchestrator.md`, `coder.md`, the `deny` list in `settings.autonomous.json`, and both `guard-bash.*`.
- **Model routing:** agent frontmatter, the `README.md` agents table, and `SETUP-GUIDE.md` §2.
- **Agent/command counts:** `README.md`, `SETUP-GUIDE.md` §3, and `SETUP-WINDOWS.md` §9.
- **Hook twins:** `.sh` and `.ps1` share hand-mirrored regexes. Change both and test both.
- **Guard wording:**
  - `README.md` "The safety net"
  - `SETUP-GUIDE.md` §4b and §7
  - `SETUP-WINDOWS.md` §5b and §7
  - the `scripts/auto.*` headers
