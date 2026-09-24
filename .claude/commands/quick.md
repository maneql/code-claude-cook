---
description: Fast lane for a small/trivial change in a single repo — normalize, implement, self-verify (build/run). No heavy pipeline, no tests unless asked, no commit.
argument-hint: <small change or quick fix, any language>
---

Act as the **orchestrator** in FAST mode for a small change: $ARGUMENTS

1. **intake** — translate (if needed) + standardize (1-2 sentences is enough).
2. If intake judges this **standard / large**, STOP and tell me to use `/feature` instead.
3. Otherwise **coder** implements the change directly from the brief, keeping it minimal.
4. The coder **self-verifies**: build passes, lint if quick, and the changed path actually runs (smoke-check). Do NOT add tests unless I explicitly asked for them.
5. One short **reviewer** pass ONLY if the change touches security, auth, money, or data. Skip otherwise.
6. **Do not commit** — leave the changes local for my review. No git setup (`git init`/branch) unless I asked.

Finish: list files changed (uncommitted) + what was verified (build/run result) in a few lines.
