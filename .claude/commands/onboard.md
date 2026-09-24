---
description: Take over & understand an EXISTING project — map the codebase and build/test commands before developing. Reuses an existing onboarding doc if present (incremental refresh, not a full re-map).
argument-hint: (optional) a subfolder/area to focus on; add "force" to re-map from scratch
---

Act as the **orchestrator**. Focus / options (if any): $ARGUMENTS

0. **Check for an existing onboarding doc FIRST** (don't re-scan the repo yet). Use Glob/Read to look for `docs/<project>-onboarding.md` in the `docs/` folder beside `.claude/`.
   - **If it exists** and `$ARGUMENTS` does NOT contain `force`:
     a. Read it and give me a short summary of what's already captured.
     b. Do a light **freshness check** — has the repo changed since it was written? Compare cheaply: recent history (`git log --oneline` since the doc's date), new/renamed top-level modules, and changed manifests/build files (package.json, *.csproj, go.mod, etc.).
     c. If it still looks **current** -> say "onboarding is up to date" and STOP (no re-map, no wasted tokens). If only parts are **stale** -> have **explorer** do an **incremental update** of just those sections, preserving the rest, and report what changed.
     d. Then skip to step 3.
   - **If it does not exist** (or `force` was given) -> continue to step 1 for a full map.
1. **Full map (first time / forced):** the **explorer** subagent surveys the repo and writes **`docs/<project>-onboarding.md`** — in the `docs/` folder **beside `.claude/`** (the project root), where `<project>` is the project name in lower-kebab-case (architecture, entry points, main flow, build/test/lint commands, conventions, risks).
2. Summarize for me the 5-10 most important things to know before changing anything.
3. Confirm the real **run** and **test** commands (try `--help`/`test` if safe).
4. Suggest 3 next steps (e.g. add missing tests, fix tech debt) — and note that `/feature` can do them, or `/self-improve` for a full set of proposals.
5. **Calibrate the team:** run `/tune-agents` to detect this project's exact build/test/lint/format commands and conventions and write them into `CLAUDE.md`, so every agent is tuned to the repo.

Do NOT change code in this step. Keep context lean — for the freshness check, read summaries/diffs, not whole files.
