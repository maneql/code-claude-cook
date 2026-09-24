# Guide: Build a multi-agent "Dev Team" in Claude Code

This guide shows how to build a **virtual software team** on Claude Code: specialized subagents that collaborate through the real software lifecycle (intake → analyze → plan → code + self-verify → review → docs; tests & git are **opt-in**, off by default), right-sized to each task, optimized for **cost/speed** by choosing the right model per role, supporting **both new projects and existing ones** (any stack — Node, Python, Go, .NET/C#, …; `/tune-agents` calibrates the team to your repo), with a **periodic self-improvement mechanism gated by human approval**.

The accompanying config bundle (the `claude-dev-team/` folder) is ready to copy into your project.

---

## 1. The architecture idea

Claude Code lets you define **subagents**: each has its own context window, its own system prompt, its own tool list, and its own **model**. The main session acts as the *Tech Lead* (orchestrator): it receives a request and **delegates** to the right subagent at each stage.

```
                         YOU (the user)
                              │
                  /new-project | /onboard | /feature
                              ▼
                ┌─────────────────────────────┐
                │   orchestrator (Tech Lead)   │  model: opus
                └─────────────────────────────┘
        ┌──────────┬──────────┬──────────┬──────────┬──────────┐
        ▼          ▼          ▼          ▼          ▼          ▼
   analyst    planner     coder      tester    reviewer   docwriter
   (haiku)    (opus)     (sonnet)   (sonnet)   (sonnet)    (haiku)
        │          │          │          │          │
   spec.md     plan.md     code      tests     APPROVE/    README/
                                                CHANGES    CHANGELOG
        ▲
   intake (haiku)     ← step 0: translate any language + standardize every request
   explorer (sonnet)  ← for existing projects: writes docs/<project>-onboarding.md
   NOTE: tester is OPT-IN — it joins only when you ask for tests; by default the
         coder self-verifies (build, lint, run/smoke-check) and git setup is off.

   ─────────────────── Runs PERIODICALLY, isolated ───────────────────
   cron → scripts/scheduled-improve.sh → optimizer (opus, PROPOSE-ONLY)
        → writes proposals/*.md → notify "needs approval"
        → you approve → /apply-proposal → coder/reviewer execute (tester only if you ask)
```

Why split into subagents instead of one Claude doing everything?

- **Save context:** heavy reading stays inside subagents and only summaries return; artifacts and a `docs/state/` checkpoint live on disk, so the main thread never holds everything (see §8b).
- **Limit permissions:** reviewer/explorer are read-only; the optimizer can only write into `proposals/`.
- **Optimize cost:** each role uses the cheapest model that is *good enough* for its job.

---

## 2. Role ↔ SDLC stage ↔ model

| Agent | Stage | Model | Why this model |
|-------|-------|-------|----------------|
| **intake** | Normalize/translate the request (step 0) | `haiku` | Translation + reformatting is templated -> fast & cheap; runs on every request. |
| **analyst** | Requirements analysis | `haiku` | Extracting user stories / acceptance criteria is templated — needs to be **fast & cheap**. |
| **explorer** | Understand an existing project | `sonnet` | Reads many files and **synthesizes** the architecture — needs decent reasoning, but not opus. |
| **researcher** | Facts from outside the repo (`/research`) | `sonnet` | Follows claims to **primary sources** and writes cited findings to `docs/research/`; runs on demand. |
| **planner** | Design / architecture | `opus` | The **hardest reasoning**; a good decision here lets the cheaper agents execute smoothly. Runs ~once per feature, so the cost is acceptable. |
| **coder** | Implementation | `sonnet` | Best **code-quality/cost** ratio; runs the most. |
| **tester** | Test / QA (opt-in) | `sonnet` | Runs only when you ask for tests; then tests by risk, not for coverage's sake; *running* tests is Bash, nearly free. |
| **reviewer** | Code review | `sonnet` | Enough for everyday review. Bump to `opus` for critical modules (security/payments). |
| **docwriter** | Documentation | `haiku` | Writing README/CHANGELOG is templated → **cheap**. |
| **orchestrator** | Leader: plan-first + coordination | `opus` | Does the up-front planning & right-sizing; quality here steers every cheaper agent. Runs per request, so the leader is the one role worth Opus. |
| **optimizer** | Self-improvement (proposals) | `opus` | Proposal quality matters, but it **runs rarely** (scheduled), so total cost stays low. |

> **Cost-optimization principle:** *Opus for thinking (orchestrator, planner, optimizer) — Sonnet for doing (coder/tester/reviewer) — Haiku for templated work (analyst, docwriter).* The most "token-heavy" work (reading/running) is in Bash and barely costs model tokens.

The aliases `haiku`/`sonnet`/`opus` auto-resolve to the latest version (currently Haiku 4.5, Sonnet 4.6, Opus 4.8). To pin a specific version, replace the alias with the full model string in the frontmatter, e.g. `model: claude-sonnet-4-6`.

---

## 3. Directory structure

```
claude-dev-team/
├── CLAUDE.md                     # Shared rules, always loaded for every agent
├── README.md                     # Quickstart
├── SETUP-GUIDE.md                # (this file)
├── SETUP-WINDOWS.md              # Windows-specific setup
├── .claude/
│   ├── settings.json             # Hooks (default: bash)
│   ├── settings.windows.json     # PowerShell hooks (Windows)
│   ├── settings.autonomous.json  # OPTIONAL: no-prompt permissions overlay
│   ├── agents/                   # 11 subagents
│   │   ├── intake.md             # step 0: translate + standardize the request
│   │   ├── orchestrator.md       # Tech Lead: right-size + coordinate (single coder)
│   │   ├── analyst.md  planner.md  coder.md
│   │   ├── tester.md  reviewer.md  docwriter.md
│   │   ├── explorer.md           # onboard existing projects
│   │   ├── researcher.md         # cited answers from primary sources (/research)
│   │   └── optimizer.md          # improvement proposals (PROPOSE-ONLY)
│   ├── commands/                 # Slash command = a workflow (13)
│   │   ├── new-project.md  onboard.md
│   │   ├── feature.md            # /feature      (right-sized pipeline)
│   │   ├── quick.md              # /quick        (fast lane)
│   │   ├── grill.md              # /grill        (stress-test a plan before building)
│   │   ├── research.md           # /research     (cited research into docs/research/)
│   │   ├── resume.md             # /resume       (continue after an interruption)
│   │   ├── handoff.md            # /handoff      (checkpoint a free-form session)
│   │   ├── tune-agents.md        # /tune-agents  (calibrate the team to this repo)
│   │   ├── verify.md             # /verify       (run locally + smoke-test + fix plan)
│   │   ├── export-spec.md        # /export-spec  (project blueprint -> Excel)
│   │   └── self-improve.md  apply-proposal.md
│   └── hooks/                    # .sh (bash) + .ps1 (PowerShell) versions
│       ├── guard-bash.{sh,ps1}   # Block destructive commands
│       ├── post-edit.{sh,ps1}    # Auto-format edited files
│       └── notify.{sh,ps1}       # Send notifications (Slack/desktop)
├── scripts/
│   ├── scheduled-improve.sh|ps1  # Self-improve entrypoint (cron / Task Scheduler)
│   ├── register-task.ps1         # Register the schedule on Windows
│   ├── auto.sh|ps1               # OPTIONAL: launch with no permission prompts
│   └── export-spec.py            # JSON -> styled .xlsx (used by /export-spec; + spec-template.json)
└── proposals/                    # Where the optimizer writes proposals + notification log
```

---

## 4. Step-by-step install

1. **Install Claude Code** (if needed) and sign in:
   ```bash
   npm install -g @anthropic-ai/claude-code
   claude            # sign in as prompted
   ```
2. **Copy only `.claude/`, `scripts/` and `CLAUDE.md`** into your project root. Copying replaces files with the same name, so if your project already has a `CLAUDE.md` or `.claude/settings.json`, back them up first and merge your own content back in.
3. **Make scripts executable**:
   ```bash
   chmod +x .claude/hooks/*.sh scripts/*.sh
   ```
4. (Optional) **Slack notifications**: create an Incoming Webhook and set the env var:
   ```bash
   export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/XXX/YYY/ZZZ"
   ```
   You can skip this — the hook falls back to a desktop notification (macOS/Linux/Windows) and logs to `proposals/notifications.log`.
5. **Open the project with Claude Code** and verify:
   ```
   /help        # see /new-project, /onboard, /grill, /research, /feature, /quick, /resume, /handoff, /tune-agents, /verify, /export-spec, /self-improve, /apply-proposal
   ```
   For the agents, ask Claude *"which subagents are available?"* — it should name the 11 above. (The `/agents` wizard was removed in Claude Code 2.1.198; agents are just the files in `.claude/agents/`, discovered automatically — ask Claude to create/manage them, or edit the files directly.)

> Put `.claude/` at the **repo root** so the whole team shares it (commit it to git). For a **personal, cross-project** setup, copy `agents/` and `commands/` into `~/.claude/` instead of into the repo.

---

## 4b. Autonomous mode (no permission prompts)

By default Claude Code asks before running commands. To let the team **progress without stopping for permission**, pick one level. Both keep the guard hook, which blocks `git commit` / `git push` and common destructive commands in every permission mode. It is a best-effort safety net that matches command text, not a sandbox. **Use these modes only on repos you trust:** with fewer prompts, instructions hidden in a README, an issue or a dependency can make the AI run commands you never see.

**Level 1 - auto-proceed for dev work (recommended).** Enable the bundled overlay:
```bash
cp .claude/settings.autonomous.json .claude/settings.local.json   # turn ON
# remove .claude/settings.local.json to turn OFF
```
It sets `defaultMode: acceptEdits` (file edits never prompt) and allow-lists common dev commands (npm / pytest / go / make / git-read ...), while denying commit/push. Unknown commands still prompt - a deliberate backstop. Note that allow-listing `python`, `node`, `npx`, `npm`, `pip` or `make` means the AI can run any code through them without asking. `settings.local.json` merges over your `settings.json`, so it works with either the bash or the Windows hooks.

**Level 2 - never ask at all (fully unattended).** Launch in bypass mode:
```bash
claude --dangerously-skip-permissions      # or: scripts/auto.sh     (Windows: scripts\auto.ps1)
```
No prompts for anything. Use it only in a trusted repo, ideally inside a container or VM that cannot reach your secrets. The guard hook still blocks the common commit/push/destructive commands, but it is a safety net, not a guarantee.

Either way the leader still right-sizes, checkpoints to `docs/state/`, and leaves changes uncommitted for your review.

---

## 5. Usage

### 5.1. NEW project (greenfield)
```
/new-project A personal finance app in Next.js + Postgres, with login and charts
```
The team will: clarify the MVP (analyst) → pick stack + architecture (planner, will ask you if the stack is unclear) → create a runnable skeleton that builds & runs (coder) → README (docwriter). Test harness (tester) and `git init` happen only if you ask for them.

### 5.2. EXISTING project (brownfield)
```
/onboard
```
The `explorer` agent maps the codebase into `docs/<project>-onboarding.md` — the `docs/` folder beside `.claude/` (architecture, entry points, build/test commands, conventions, risks) and summarizes "what to know before changing code". Then run **`/tune-agents`** to calibrate the team to this repo's exact stack/commands/conventions (e.g. .NET/C#: `dotnet build`/`dotnet test`/`dotnet format`), and use `/feature` as usual. If an onboarding doc already exists, `/onboard` **reuses it** (freshness check + incremental refresh; add `force` to re-map from scratch).

### 5.3. Build one feature / fix a bug (either project type)
```
/feature Add Google OAuth login
/feature Fix the wrong total when a discount code is applied
```
Full pipeline: analyst → planner → coder (self-verify: build/run) → reviewer → docwriter — the tester joins only when you ask for tests. If the self-verify (or requested tests) fail or the reviewer requests changes, the orchestrator loops back to the coder (max 2 rounds), then reports.

Every request is **right-sized**: `intake` estimates trivial/small/standard, and the orchestrator skips heavy stages for small work. Force the fast lane for a small change with `/quick <fix>`. A large task stays in the standard pipeline — the planner splits it into ordered steps for the single coder.

All changes are left **uncommitted** in the working tree for your review; no agent commits. The reviewer reads the local `git diff`, and you make the commit yourself once you're satisfied.

### 5.3b. Verify a feature locally (run + smoke-test)
```
/verify checkout flow
```
Builds the project, runs the test suite, then actually **starts the app locally** and smoke-tests the feature (hits the endpoint / runs the flow), stopping the process afterward. If anything breaks, it writes a **fix plan** (root cause + ordered steps) to `docs/fixes/` and stops — review it and run `/apply-proposal docs/fixes/<file>` to implement. No code changes, no commits.

### 5.3c. Export a developer blueprint (Excel)
```
/export-spec            # English (default)
/export-spec Vietnamese # any language
```
Compiles the whole project — overview, every feature (rules, I/O, acceptance criteria, status), data model, APIs, dependencies, verification results, and suggestions — referencing `docs/<project>-onboarding.md`, into `docs/spec/<project>-spec.json`, then renders a styled multi-sheet workbook at `docs/spec/<project>-spec.xlsx`. Detailed enough to brief a developer or scope a new version. The **sheet/column layout adapts per project** — the renderer takes whatever sheets, columns, and rows the spec defines (the baseline 7 sheets are just a starting point, e.g. add *Screens/UX*, *Permissions & Roles*, *Integrations*; drop *APIs* for a library). Needs Python + `openpyxl` (install it with `python -m pip install openpyxl`; the script never installs packages itself). See `scripts/spec-template.json` for the format.

### 5.4. Call a single role
You can ask directly, e.g. *"use the reviewer to look at the changes in src/auth"* — Claude will pick the `reviewer` subagent.

---

## 6. SELF-IMPROVEMENT + APPROVAL GATE

This satisfies the requirement: *the system periodically proposes new features / performance optimizations, but must send a notification and require approval before executing.*

### 6.1. How it works
```
(1) Periodically: cron runs scripts/scheduled-improve.sh
        │
        ▼
(2) Runs /self-improve HEADLESS with RESTRICTED permissions:
       allowedTools = Read, Grep, Glob, Bash(git ...), Write(proposals/**)
       → optimizer (opus) can ONLY read the repo + ONLY write into proposals/
        │
        ▼
(3) Produces proposals/<date>-<slug>.md  (features + optimizations, ranked)
        │
        ▼
(4) notify.sh sends: "New proposal needs approval: proposals/..."
        │
        ▼
(5) YOU review the proposal. If you agree:  /apply-proposal proposals/<file>.md
        │
        ▼
(6) Only now (and only now) can coder/tester/reviewer change code.
```

**The key safety property:** the automated step (2) runs with `--allowedTools` that **excludes `Edit`** and **path-limits `Write` to `proposals/**`**. Because it runs headless (no human present), any tool outside that list is **auto-denied** — so the agent **cannot modify code**. It can only propose. Execution always requires a deliberate human action (`/apply-proposal`).

### 6.2. Scheduling

**macOS / Linux — cron** (example: 9:00 AM every Monday):
```bash
crontab -e
# Add (adjust your repo path):
0 9 * * 1  cd /path/to/repo && /path/to/repo/scripts/scheduled-improve.sh /path/to/repo >> /tmp/claude-improve.log 2>&1
```

**macOS — launchd** or **Linux — systemd timer**: call the same `scheduled-improve.sh`.

**Windows — Task Scheduler**: see `SETUP-WINDOWS.md` (`scripts/register-task.ps1` does it in one command).

**CI (GitHub Actions)** — generate the proposal and open a **Pull Request** instead of a notification (the PR is the approval gate):
```yaml
name: weekly-self-improve
on:
  schedule: [{ cron: "0 9 * * 1" }]   # 9:00 Monday (UTC)
  workflow_dispatch:
jobs:
  propose:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Claude Code
        run: npm install -g @anthropic-ai/claude-code
      - name: Generate proposals (propose-only)
        env: { ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }} }
        run: |
          claude -p "/self-improve" \
            --permission-mode default \
            --allowedTools "Read" "Grep" "Glob" "Bash(git log:*)" "Write(proposals/**)"
      - name: Open a PR with the proposals
        uses: peter-evans/create-pull-request@v6
        with:
          branch: auto/self-improve
          title: "Automated improvement proposals (needs review)"
          commit-message: "chore: weekly self-improve proposals"
          add-paths: proposals/**
```
> Merging the PR = approval. After merging, run `/apply-proposal` to implement. Never let the workflow edit code or auto-merge.

### 6.3. Try it now (no waiting)
```
/self-improve
```
Check the new file in `proposals/` (there's a sample `2026-06-16-example.md` showing the format).

### 6.4. It's optional / on-off
Nothing runs automatically unless you register the schedule. Turn it **off** by removing the cron line / unregistering the Windows task / disabling the workflow. You can still run `/self-improve` manually anytime, or delete `optimizer.md` + the two related commands to remove it entirely.

---

## 7. Hooks (safe automation)

`.claude/settings.json` wires three hooks:

| Hook | Event | What it does |
|------|-------|--------------|
| `guard-bash.sh` | `PreToolUse` (matcher `Bash\|PowerShell`) | **Blocks** `git commit`/`git push`; git commands that would **discard uncommitted work** (`git reset --hard`, `git checkout .` / `git checkout -- <path>`, `git restore`, `git clean`, `git stash drop/clear`); and dangerous commands: recursive `rm` aimed at `/`, `~`, `.`, `*` or a drive, `find -delete`, `mkfs`, `dd if=`, `DROP TABLE/DATABASE`, `git push --force`, plus their PowerShell/cmd forms. Returns exit code 2 so Claude won't run it. If it can't parse the hook input (for example, no `python3`), it checks the raw text instead of letting the command through. |
| `post-edit.sh` | `PostToolUse` (matcher `Edit\|Write`) | Auto-**formats** the edited file if a tool exists (`black`, `prettier`, `gofmt`). Never breaks the operation. |
| `notify.sh` | `Notification` | Pushes to **Slack/desktop** and logs. Also called directly by `scheduled-improve.sh` when a new proposal is ready. |

You can add more hooks, e.g. a `PostToolUse` that runs fast tests after each edit, or a `SubagentStop` to log each role's duration.

---

## 8. Cost & speed tips

- **Let planner/optimizer (opus) run rarely and decisively.** A good plan means the coder (sonnet) reworks less.
- **Downgrade models when good enough:** small projects can move `planner` to `sonnet`, and `explorer`/`reviewer` to `haiku`.
- **Limit tools to what's needed** (already done): fewer tools per agent → less noise, faster, safer.
- **Run in the background / parallel:** for independent work, use multiple sessions (Claude Code background agents / agent teams) to cut wall-clock time.
- **Schedule `/self-improve` infrequently** (weekly/biweekly) to avoid wasting opus.

---

## 8b. Context discipline (don't fill the window)

Long pipelines can fill the context window; at 100% Claude Code compacts and detail is lost. The team is built to stay well under that:

- **Subagents isolate context.** Heavy reading (explorer/coder/tester) happens in a subagent's own window; only a short summary returns to the leader.
- **State lives on disk.** The intake brief (`docs/intake/`), spec (`docs/specs/`), plan (`docs/plans/`), and a running checkpoint (`docs/state/<slug>.md`) are files. The team works from them, not from a growing chat history — so a compaction or a fresh session loses nothing.
- **Summaries only.** Agents cite `file:line` and summarize; they don't paste whole files, diffs, or test logs back into the main thread.
- **Targeted reads.** Prefer Grep / specific line ranges over whole files; avoid echoing large output.
- **Compact early.** When the context indicator climbs mid-task, the leader checkpoints to `docs/state/<slug>.md` and you run `/compact` (or resume in a new session from the checkpoint) — never riding at the limit.

- **Resume after a pause.** If the plan usage limit is hit (or a session ends), no work is lost — state is on disk and changes are uncommitted. When the limit resets, reopen and run `/resume` to continue from the last checkpoint.

Net effect: a feature can run end-to-end across many stages without the leader's context approaching 100%.

---

## 9. Customize & extend

- **Add a new role:** create a file in `.claude/agents/` with frontmatter `name / description / tools / model`. Write a clear "when to use" `description` so Claude routes to it automatically.
- **Change a workflow:** edit the files in `.claude/commands/` (they are the pipeline scripts).
- **Integrate real tools:** add MCP servers (GitHub, Jira/Linear, Slack, Postgres...) so agents can read issues, open PRs, update tickets — declare the matching MCP tools in the relevant agent's `tools:`.
- **Pin model versions:** replace the alias with a full model string in frontmatter if you need long-term stability.

---

## 10. Notes & limitations

- Subagents **don't talk to each other directly**; the orchestrator (main session) coordinates and passes context. Always include the spec/plan path when delegating.
- Hooks run shell commands with **your permissions** — only run scripts you trust (the included ones are short; read them first).
- `guard-bash.sh` blocks common patterns; it is **not a substitute** for running in a controlled/sandboxed environment.
- Claude Code's `--allowedTools` / `--permission-mode` flags can change between versions — if a headless run errors, run `claude --help` to confirm the current flags.
- Always keep a human **approval** step before merge/production; the proposal mechanism is there to *assist*, not to replace your judgment.
