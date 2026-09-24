---
description: Bootstrap a NEW project from scratch across the team (requirements -> pick stack -> scaffold that builds & runs -> README). Test harness and git init are opt-in (only if you ask); never commits.
argument-hint: <product description; optionally include the desired tech stack>
---

Act as the **orchestrator** to bootstrap a NEW project. Description: $ARGUMENTS

Steps (delegate via the `Agent` tool):
1. **intake** — translate (if needed) + standardize the product description. Then **analyst** — clarify product scope, target users, and the core features for a first version (MVP); write `docs/specs/`.
2. **planner** — propose a **tech stack** (with rationale & one alternative), directory structure, initial architecture, and scaffolding plan; write `docs/plans/`. If the stack is unclear, ask me BEFORE creating files.
3. **coder** — create the skeleton: directory tree, config/manifest files, a runnable "hello world", .gitignore, dependency management. **Self-verify: the hello-world must BUILD and RUN** before moving on.
4. **(opt-in — only if I asked for tests)** **tester** sets up the test harness (a test framework + one passing sample test) and a `test` command. Skip by default.
5. **docwriter** — README (install, run — and test, if a harness was set up) and an initial CHANGELOG.
6. **(opt-in — only if I asked for git)** run `git init`, but even then **do NOT commit**; the first commit is mine. By default leave the folder without git.

Finish: print the directory tree, the run command (and test command if a harness exists), and suggest using `/feature` for the next feature.
