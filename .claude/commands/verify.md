---
description: Run the project locally and auto-verify a feature — build + start + smoke-test + run tests. If it finds a bug, it writes a fix PLAN (root cause + steps) and stops; it does NOT auto-fix and never commits.
argument-hint: <feature/flow to verify, e.g. "login with Google"; omit to verify the whole build + tests>
---

Act as the **orchestrator**. Verify the project runs and the feature works locally. Target: $ARGUMENTS

Use the **Project profile** in `CLAUDE.md` (or `docs/<project>-onboarding.md`) for the real build/run/test commands. If they're unknown, detect them or run `/tune-agents` first.

1. **Build.** Run the project's build (e.g. `dotnet build`, `npm run build`, `go build`, `make`). If it fails → go to step 5.
2. **Test (only if a suite already exists).** Run the project's existing test suite if there is one (do NOT add tests here; skip this step silently if the project has none). Capture pass/fail; a failure → step 5.
3. **Run & smoke-test the feature.** Start the app locally **in the background with a bounded wait**, health-check it, then exercise the feature for real:
   - **web / API:** start the server (record the PID and port), poll the URL until healthy (with a timeout), then hit the relevant endpoint(s)/page for the feature and check status/response.
   - **CLI / library:** run the command/flow with representative input and check output and exit code.
   Capture stdout/stderr and any error logs. **Always stop the process you started** (kill the PID) when done — even on failure. Never leave a server running.
4. **All good →** report a short PASS summary: what you ran, the commands, what you checked, and the result. Stop.
5. **Bug found → suggest a fix plan (do NOT fix).** Delegate to **planner** to write a fix plan to `docs/fixes/<YYYY-MM-DD>-<slug>.md`:
   - **Symptom + exact reproduction** (command, input, observed vs expected, key error/log lines only).
   - **Most likely root cause** (cite `file:line`) with 1–2 alternatives.
   - **Fix plan:** ordered steps, files to change, tests to add, risks, severity.
   Then tell me: review it and run **`/apply-proposal docs/fixes/<file>`** (or `/feature <summary>`) to implement after approval — nothing is changed automatically.

Rules: no product-code changes and no commits in this command. Keep context lean — quote only the key error lines, not full logs. Honor the guard hook; if a run command needs a port/env, ask me rather than guessing secrets.
