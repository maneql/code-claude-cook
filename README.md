# Claude Code — Dev Team

Turn Claude Code into a small **software team** that takes a request through the real lifecycle: **intake → analyze → plan → code + self-verify → review → docs**, right-sized to each task. **Tests and git setup are opt-in** (off by default — say "with tests" / "with git" to enable); by default the coder **self-verifies** every change (build, lint, run/smoke-check). It works on **one repo** with **one coder**, **never commits** (all changes stay local for your review), and a strong **Opus leader** plans before delegating.

Multi-stack (Node, Python, Go, .NET/C#, …) — run `/tune-agents` and the team calibrates itself to your project. Verified bundle: **11 agents, 13 commands**. The engineering flow (vertical slices, bug-reproduction loop, two-axis review, deep-module design, grilling).

> **Windows:** see **`SETUP-WINDOWS.md`** (PowerShell hooks + Task Scheduler). Full architecture & rationale: **`SETUP-GUIDE.md`**.

---

## Setup

1. **Copy only `.claude/`, `scripts/` and `CLAUDE.md`** into your project root. The rest of this repo is documentation. Copying replaces files with the same name, so if your project already has a `CLAUDE.md` or `.claude/settings.json`, back them up first and merge your own content back in.
2. **Activate the hooks** for how Claude Code runs shell commands on your machine:
   - **Windows, native PowerShell:** `Copy-Item .claude\settings.windows.json .claude\settings.json -Force`
   - **Git Bash / WSL / macOS / Linux:** keep `.claude/settings.json` as-is and run `chmod +x .claude/hooks/*.sh scripts/*.sh`
3. *(Optional)* **Slack notifications:** set `SLACK_WEBHOOK_URL` (falls back to a desktop toast).
4. *(Optional)* **Autonomous mode** (fewer permission prompts): `cp .claude/settings.autonomous.json .claude/settings.local.json`. Delete the file to turn it off. **Use it only on repos you trust:** it lets the AI edit files and run `python`, `node`, `npm`, `npx`, `pip`, `make` and similar tools without asking, so instructions hidden in a README or a dependency could make it run anything. The guard hook still blocks common commit/push and destructive commands, but it is a safety net, not a sandbox.
5. **Open the project in Claude Code** and check: `/help` lists the 13 commands, and asking *"which subagents are available?"* names the 11 agents. (The `/agents` wizard was removed in Claude Code 2.1.198 — agents are simply the files in `.claude/agents/`, discovered automatically. After editing anything under `.claude/`, restart the session — agents, commands, and hook wiring load at startup.)
6. **Existing repo?** Run `/onboard` (maps the codebase), then `/tune-agents` (writes the repo's exact build/run commands and conventions into `CLAUDE.md`, tuning every agent at once).

---

## The workflow, drawn

### Where to enter

```
 NEW project                     EXISTING project              fuzzy idea?
 /new-project <description>      /onboard   (map the repo)     /grill <idea>  (interview:
      │                               │                          1 question at a time, each
      ▼                               ▼                          with a recommended answer;
 scaffold that BUILDS & RUNS     /tune-agents (calibrate         decisions land in the spec)
 (test harness / git init             every agent to                     │
  only if you asked)                  this repo)                         ▼
      └──────────────► ready ◄────────┘                             /feature
                         │
                         ▼
          /feature · /quick · /verify · /resume
```

### The main pipeline (`/feature`)

```
 you ─► /feature <request, any language>
          │
          ▼
 0. intake ........ translate + brief + size + flags          → docs/intake/<slug>.md
          │         tests=off, git=off  (on only if YOU asked)
          ▼
 1. orchestrator .. plans first, right-sizes the path         → docs/state/<slug>.md (checkpoint)
          │
          ├─ trivial ─► coder (self-verify: build/run) ─► done
          │
          ├─ small ───► coder (self-verify) ─► reviewer ─► done
          │
          └─ standard / large:
               ▼
 2. analyst ....... spec: stories, acceptance criteria,       → docs/specs/<feature>.md
          │         facts from code / decisions with defaults
          ▼
 3. planner ....... design it twice → deep modules;           → docs/plans/<feature>.md
          │         VERTICAL slices (each builds & runs)
          ▼
 4. coder ......... slice by slice; fastest check after       → uncommitted changes
          │         each slice, full build at the end   ▲
          ▼                                             │ fix loop
    [tester] ...... ONLY if tests=on (pre-agreed seams) │ (once for small,
          ▼                                             │  twice for standard)
 5. reviewer ...... two axes, reported separately ──────┘
          │         Spec (nothing missing, nothing extra)
          │         × Standards (conventions + smells)
          ▼ APPROVE
 6. docwriter ..... README / CHANGELOG
          ▼
 done ............. summary table: size | stages | files | verify result
                    everything stays UNCOMMITTED — you review, you commit
```

### Bug requests (`type=bug`): no reproduction, no fix

```
 reproduce (repeatable command) ─► minimize ─► hypothesize (ranked, falsifiable)
        │                                            │
        │ can't reproduce? STOP & report             ▼
        │ (never fix blind)          instrument (tagged [DBG-*]) ─► fix
        │                                            │
        ▼                                            ▼
      the SAME command re-run must pass ◄────────────┘ → cleanup + root cause
      (regression test only if tests=on)
```

### The self-improvement loop (propose-only, human-gated)

```
 scheduler (weekly) ─► /self-improve ─► optimizer (PROPOSE-ONLY) ─► proposals/<date>-<slug>.md ─► notify you
                                                                                      │
 code changes ◄── pipeline (coder → reviewer) ◄── /apply-proposal <file> ◄── you review & approve
```

---

## Day-to-day usage

| You want to… | Run |
|---|---|
| Start a brand-new app | `/new-project <description>` — add "with tests" / "with git" if you want them |
| Take over an existing repo | `/onboard`, then `/tune-agents` |
| Pin down a fuzzy idea first | `/grill <idea>` → answer its questions → `/feature` |
| Answer a tech question with sources | `/research <question>` → cited findings in `docs/research/` |
| Build a feature / fix a bug | `/feature <description, any language>` |
| Make a tiny change | `/quick <change>` |
| Prove a feature actually runs | `/verify <feature>` — build + start + smoke-test; writes a fix *plan* on failure |
| Continue after an interruption | `/resume` (rebuilds from `docs/state/` — nothing is lost, nothing was committed) |
| Stop mid-work in a free-form session | `/handoff <what's next>` — compacts the chat into `docs/state/`; next session: `/resume` |
| Get improvement ideas | `/self-improve` → review `proposals/` → `/apply-proposal <file>` |
| Hand the project over / rebuild it | `/export-spec [language]` → Excel blueprint in `docs/spec/` |

**The two switches (off by default):** say **"with tests" / "add unit tests"** in a request → `tests=on` (tester joins, TDD at pre-agreed seams); say **"init git" / "create a branch"** → `git=on`. Everything else runs development-only: the coder self-verifies each slice by building and running it.

---

## Commands

| Command | What it does |
|---------|--------------|
| `/new-project <desc>` | Bootstrap a **new** project: pick stack → scaffold (must build & run) → README. Test harness & `git init` only if you ask; **never commits**. |
| `/onboard` | Map an **existing** codebase into `docs/<project>-onboarding.md` (beside `.claude/`), then points you to `/tune-agents`. **Reuses an existing onboarding doc** (freshness check + incremental refresh; `force` to re-map). |
| `/tune-agents` | Detect the repo's stack + **exact** build/test/lint/format commands + conventions and write a *Project profile* into `CLAUDE.md` — tuning **every** agent to this project. |
| `/grill <idea\|path>` | Stress-test a plan BEFORE building: an interview, one question at a time, each with a recommended answer; facts come from the code, only decisions reach you. Writes a **Decisions** section into the spec. |
| `/research <question>` | Investigate against **primary sources** (official docs, source, changelogs) → `docs/research/<slug>.md` with a citation per claim. Specs/plans reference it instead of guessing. |
| `/feature <desc>` | The right-sized pipeline for a feature/bug (intake → … → review → docs). Changes are left **uncommitted**. |
| `/quick <desc>` | Fast lane for a small/trivial change — normalize → implement → self-verify (build/run). |
| `/verify <feature>` | Build + **run the app locally** + smoke-test the feature (+ existing tests if the project has any). On a bug it writes a **fix plan** to `docs/fixes/` (propose-only — never auto-fixes). |
| `/resume` | Continue an interrupted run from the `docs/state/` checkpoint (e.g. after a plan **usage-limit reset**). |
| `/handoff [focus]` | Compact the current conversation into a `docs/state/` handoff (reference artifacts by path, secrets redacted, suggested next commands) so `/resume` can pick it up — for free-form sessions with no pipeline checkpoint. |
| `/self-improve` | **Propose** features/optimizations into `proposals/` (manual, or scheduled). Never edits code. |
| `/apply-proposal <path>` | Implement an **approved** proposal or fix plan through the pipeline. |
| `/export-spec [lang]` | Summarize the whole project (design, features, verification, suggestions — ref the onboarding doc) into a **developer-level Excel blueprint** at `docs/spec/<project>-spec.xlsx`, usable to scope a new version. **Sheets/columns adapt per project** (not fixed). Language optional (English default). |

---

## Agents (model per role)

| Agent | Role | Model |
|-------|------|-------|
| `intake` | Translate any language + standardize the request (step 0) | `haiku` |
| `orchestrator` | **Leader** — plans first, right-sizes, coordinates one coder | `opus` |
| `analyst` | Requirements: user stories, acceptance criteria, decisions-with-defaults | `haiku` |
| `planner` | Architecture: design-it-twice, deep modules, vertical slices | `opus` |
| `coder` | Implementation + self-verify each slice (single coder) | `sonnet` |
| `tester` | **Opt-in** QA — runs only when you ask for tests; then tests by risk at pre-agreed seams | `sonnet` |
| `reviewer` | Two-axis review (Spec × Standards) of the local uncommitted diff | `sonnet` |
| `docwriter` | README / CHANGELOG / docs | `haiku` |
| `explorer` | Map an existing codebase (read-only, primary sources) | `sonnet` |
| `researcher` | Cited research from primary sources → `docs/research/` (web-enabled, propose-nothing) | `sonnet` |
| `optimizer` | Periodic improvement **proposals** (propose-only) | `opus` |

**Cost principle:** Opus for thinking (orchestrator, planner, optimizer) · Sonnet for doing (coder/tester/reviewer/explorer/researcher) · Haiku for templated work (intake/analyst/docwriter).

---

## The safety net

- **Never commits.** All changes stay **uncommitted** in the working tree; you review the diff and make the commit. A `PreToolUse` guard hook on **both** the Bash and PowerShell tools blocks `git commit` / `git push` in every permission mode, including autonomous.
- **Never destroys work.** The same hook blocks work-discarding git (`git reset --hard`, `git checkout -- <path>` / `git checkout .`, `git restore`, `git clean`, `git stash drop/clear`) and destructive commands (recursive `rm` aimed at `/`, `~`, `.`, `*` or a drive, `find -delete`, `Remove-Item -Recurse -Force`, `DROP TABLE`, …).
- **A safety net, not a sandbox.** The guard matches command text, so it catches the common forms, not every possible one. If it can't read a command, it blocks it instead of letting it through. For fully unattended runs (`--dangerously-skip-permissions`), use a container or VM.
- **Self-improvement can't touch code.** The optimizer only writes into `proposals/`; execution requires you to run `/apply-proposal`.
- **Interruption-proof.** Progress is checkpointed to `docs/state/<slug>.md` after every stage; `/resume` picks up from disk.
- **Auto-format on save.** A `PostToolUse` hook runs `black` / `prettier` / `gofmt` / `csharpier` when available; notifications go to Slack or a desktop toast.

---

## Support development
<a href="https://paypal.me/manqel" target="_blank">Let him cook !!!</a>