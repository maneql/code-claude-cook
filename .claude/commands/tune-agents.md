---
description: Calibrate the team to THIS project — detect stack, build/test/lint/format commands, and conventions, then write them into CLAUDE.md so every agent is tuned to the repo. Run right after /onboard. No product-code changes.
argument-hint: (optional) area or stack hint, e.g. ".NET", "monorepo packages/api"
---

Act as the **orchestrator**. Goal: tune the team's skill to the current project. You only edit `CLAUDE.md` (team config) — never product code.

1. If the onboarding doc (`docs/<project>-onboarding.md`, beside `.claude/`) is missing or stale, run the **explorer** subagent first to map the repo (keep context lean — summaries, not dumps).
2. **Detect by reading manifests/configs (do not guess):**
   - Language(s) & framework(s) **and versions** — e.g. .NET target framework(s) from `*.csproj` / `Directory.Build.props`, Node `engines`, Python version, Go version.
   - Package manager and the **exact** commands for: install, build, run, **test**, lint, **format**, typecheck.
   - Test framework(s) and how tests are laid out.
   - Project layout (solution/projects/modules), entry points.
   - Conventions: `.editorconfig`, analyzers/linters, naming, nullable/strict flags, the formatter in use.
   - Notable risks / gotchas.
   Focus hint (if any): $ARGUMENTS
3. **Write the Project profile into `CLAUDE.md`**, replacing everything between the markers
   `<!-- PROJECT-PROFILE:START -->` and `<!-- PROJECT-PROFILE:END -->` (create the block if it's missing). Include: stack & versions, a **commands table** (install/build/run/test/lint/format with the real invocations), the layout, conventions, and gotchas. Keep it concise — it loads into every agent.
4. Because `CLAUDE.md` is loaded by **every** subagent, this calibrates the whole team at once: the coder builds/formats the right way, the tester uses the real test command, the reviewer checks the project's conventions.
5. Print a short summary of what you detected and what you wrote.

**.NET / C# specifics to capture when present:** target framework(s) (TFM) from `*.csproj` / `global.json`, the `*.sln`, test projects and runner (xUnit / NUnit / MSTest), and prefer `dotnet restore` / `dotnet build` / `dotnet test` / `dotnet format` (or `csharpier`). Note nullable reference types, `async/await`, `IDisposable`/`using`, DI patterns, and EF Core (`dotnet ef migrations`, never auto-applied or committed).
