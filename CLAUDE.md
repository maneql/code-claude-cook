# Dev Team — Shared Rules (read by every agent)

This is a virtual "dev team" of multiple Claude subagents. This file is the shared rulebook, always loaded into every session.

## Two ways to start
- **New project (greenfield):** `/new-project <description>` — analyst -> planner (pick stack) -> coder (scaffold; hello-world must build & run) -> docwriter. Test harness and `git init` only if you ask.
- **Existing project (brownfield):** `/onboard` — the `explorer` agent writes `docs/<project>-onboarding.md` (in the `docs/` folder beside `.claude/`) first, then use `/feature`.

## Standard workflow (SDLC)
0. **intake** – Translate (if needed) into English + standardize the request; estimate size.
1. **analyst** – Analyze requirements -> create `docs/specs/<feature>.md`
2. **planner** – Design architecture & plan -> create `docs/plans/<feature>.md`
3. **coder** – Implement per the plan + **self-verify** (build, lint if quick, run/smoke-check the change)
4. **tester** – OPT-IN: only when the request asks for tests (`tests=on`)
5. **reviewer** – Review security/performance/correctness
6. **docwriter** – Update docs/CHANGELOG

## Right-size the process (streamlined)
Every request starts with **intake** (step 0). The **orchestrator (leader, Opus)** then **plans first** — restating the goal and sequencing the work — and picks the lightest path by size:
- **trivial** -> coder (implement + self-verify: build/run). Nothing else.
- **small** -> coder (self-verify) -> quick reviewer.
- **standard / large** -> analyst -> planner -> coder (self-verify) -> reviewer -> docwriter; a large task is split into ordered steps for **one coder** (sequential).
- The **tester** stage is inserted after the coder ONLY when the request asks for tests (intake records `tests=on`).
Use `/quick` to force the fast lane. Default to the smaller path when unsure.

## Testing & git are opt-in (default: OFF)
- **Default = development only.** No tester stage, no new test files. Instead the **coder self-verifies** every change: the build passes, lint if quick, and the changed path actually runs (compile/start/call it and check the output).
- **Tests run only when asked** (the request says so; intake records `tests=on`). When ON, test by risk, not by habit: cover the acceptance criteria, the critical path, and bug regressions; add edge/error tests only where failure is likely or costly (money, auth, data loss, untrusted input). A few high-value tests beat many shallow ones. If tests are off but the change touches a risky area, recommend them in the final summary — don't write them unasked.
- **Git is opt-in too** (intake records `git=on` only when the request asks): never `git init`, branch, stash, or restructure a repo unless asked. If the project already IS a git repo, read-only `git status` / `git diff` (e.g. for review) is always fine. Committing/pushing stays forbidden regardless — the guard hook enforces it.


## Context discipline (don't fill the window)
Keep the working context lean so a run never hits 100% (which forces compaction and loses detail):
- **Persist, don't accumulate.** Write artifacts to files — intake brief (`docs/intake/`), spec (`docs/specs/`), plan (`docs/plans/`), and a running checkpoint (`docs/state/<slug>.md`). Work from those files, not from a long chat history.
- **Heavy reading happens in subagents.** Let explorer/coder/tester read files and logs in their own context; they return a short summary, not raw dumps.
- **Summaries only.** Never paste full file contents, full diffs, or full test logs into the main thread — cite `file:line` and summarize.
- **Read targeted.** Prefer Grep / specific line ranges over reading whole files; don't echo large command output.
- **Checkpoint between stages.** The orchestrator updates `docs/state/<slug>.md` (goal, decisions, done-so-far, next step, key paths) after each stage, so progress survives a compaction or a fresh session.
- **Compact early.** If the context indicator gets high mid-task, summarize to the checkpoint and `/compact` (or resume in a new session from `docs/state/<slug>.md`) rather than pushing to the limit.
- **Resume after an interruption.** If a session ends or the plan usage limit is hit, no work is lost — state is on disk and changes are uncommitted. When the limit resets, reopen and run `/resume` to continue from the last checkpoint. For a free-form session with no pipeline checkpoint, run `/handoff` before stopping — it compacts the conversation into `docs/state/` so `/resume` can pick it up.

## Engineering flow
- **The rate of feedback is your speed limit.** Prefer the tightest available check at every step: typecheck/compile after each slice, run the touched path, full build once at the end. Never code blind through several steps.
- **Vertical slices (tracer bullets).** Split work into thin end-to-end slices that each build & run on their own — never layer-by-layer. Prefactor when it makes the change easy ("make the change easy, then make the easy change").
- **Bugs: no reproduction, no fix.** Reproduce with a repeatable command first, minimize, hypothesize (falsifiable), then fix and re-run the same command. Never fix what you haven't seen fail.
- **Design for depth.** Prefer deep modules — small interface, lots of behaviour behind it. No seam/abstraction until something actually varies across it. Design the core interface twice before committing.
- **Review on two axes.** Spec (does it do what was asked — nothing missing, nothing extra) and Standards (conventions + smells) are reported separately so one can't mask the other.
- **Facts vs decisions.** Anything verifiable in the repo is a fact — read the code, don't ask. Facts from OUTSIDE the repo (library behaviour, API limits, version support) go to the `researcher` (`/research`) — cited findings land in `docs/research/`, never guesses. Only real decisions go to the user, each with a recommended default. `/grill` runs this as an interactive interview before building.
- **Domain language & decisions on disk.** The project glossary lives in `CONTEXT.md` at the repo root (glossary ONLY — no implementation detail); every agent uses its terms for names. A decision that is hard to reverse + surprising without context + a real trade-off gets an ADR in `docs/adr/`; anything less doesn't.

## Definition of Done
- Spec + plan approved before coding (standard/large path).
- The coder **self-verified** the change: build passes and the changed path runs (smoke-checked). If tests were requested (`tests=on`), they exist and pass.
- No blocking issues left from the reviewer.
- Docs/CHANGELOG updated.
- Changes left **uncommitted** in the working tree for human review (agents never commit).

## Coding standards
- Read before editing; small, reviewable changes.
- No committed secrets. No destructive commands (`rm -rf`, drop db...).
- **One repo, one coder.** No parallel coders, no git worktrees, no multi-repo.
- **Never commit or push.** Leave all changes uncommitted in the working tree for the human to review and commit; the reviewer reads the local `git diff`. This holds even in **autonomous mode** (`settings.autonomous.json` / `--dangerously-skip-permissions`): the guard hook blocks commit/push regardless of permission mode.
- Commit messages (when *you* commit) follow Conventional Commits: `feat:`, `fix:`, `test:`, `docs:`, `refactor:`.

## Self-improvement (important)
- The **optimizer** agent may only **PROPOSE**, never edit code itself.
- Proposals are written to `proposals/`. Execution happens only when a human runs `/apply-proposal`.

## Stack notes
- **.NET / C#:** build `dotnet build`, test `dotnet test` (xUnit / NUnit / MSTest), format `dotnet format` or `csharpier`. Respect `.editorconfig`, nullable reference types, `async/await`, and `IDisposable`/`using`. EF Core changes use `dotnet ef migrations` — the coder writes them; never auto-applied to real data and never committed.
- Other stacks (Node/TS, Python, Go, Rust, Java...) are auto-detected. Run `/tune-agents` to lock in this repo's exact commands and conventions.

## Project profile (auto-generated by /tune-agents)
<!-- PROJECT-PROFILE:START -->
_Empty until you run `/tune-agents`. It will fill in this project's stack, exact build/test/lint/format commands, layout, and conventions — and because this file loads into every agent, it tunes the whole team._
<!-- PROJECT-PROFILE:END -->
