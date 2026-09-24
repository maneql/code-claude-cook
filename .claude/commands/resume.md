---
description: Resume an interrupted run (e.g., after a plan usage-limit reset) from the on-disk checkpoint. Rebuilds context from files, not the whole repo.
argument-hint: (optional) slug or docs/state filename to resume; omit to use the latest
---

Act as the **orchestrator (Tech Lead)**. We are resuming a run that was interrupted (often because the plan usage limit was hit and has now reset). Nothing was committed, so partial work is still in the working tree.

1. **Find the checkpoint:** if `$ARGUMENTS` is given, read `docs/state/$ARGUMENTS` (accept a slug or a path); otherwise read the most recently modified file in `docs/state/`. If `docs/state/` is empty, say so and ask which task to resume.
2. **Rebuild context from files only** (keep context lean): read that checkpoint plus the spec/plan/intake it references. Do NOT re-read the whole repo.
3. **See what already exists:** if the project is a git repo, `git status` and `git diff --stat` to find the uncommitted changes made before the interruption; otherwise use the checkpoint's file list.
4. **Summarize** in a few lines: what was done, what is still pending.
5. **Continue** the pipeline from the next pending step (same right-sizing as before). Update `docs/state/<slug>.md` as you progress.
6. Keep all changes **uncommitted** for my review. Do not redo completed steps.
