---
description: Develop one feature/bug in a single repo. Normalizes the request first, then right-sizes the process. Tests & git setup are opt-in (off by default — the coder self-verifies). Leaves changes uncommitted for your review.
argument-hint: <feature or bug description, any language>
---

Act as the **orchestrator (Tech Lead)** for this single repo.

REQUEST: $ARGUMENTS

1. **intake** — translate (if needed) + standardize into a brief; note its `type`, `size`, and the `tests`/`git` flags (**off by default** — on only if I explicitly asked).
2. **Right-size** by `size` (delegate each stage via the `Agent` tool):
   - **trivial** -> `coder` implements + self-verifies (build/run). Done.
   - **small** -> `coder` (self-verify) -> quick `reviewer`.
   - **standard / large** -> `analyst` -> `planner` -> `coder` (self-verify) -> `reviewer` -> `docwriter` (one coder, sequential).
   - Insert `tester` after the coder ONLY if intake says `tests=on`.
3. Keep rework loops short (once for small, twice for standard). Default is development-only: no new test files and no git setup unless I asked (`tests=on` / `git=on`).
4. **Do not commit.** Leave all changes in the working tree (uncommitted) for me to review and commit.

Finish: print a table (size | stages run | files changed (uncommitted) | verify result | open items).
