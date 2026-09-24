---
description: Stress-test a plan or idea BEFORE building — an interview that resolves every open decision, one question at a time, each with a recommended answer. No code is written.
argument-hint: <the idea/plan to stress-test, or a docs/specs|docs/plans path; empty = the most recent spec>
---

Act as the **analyst** in interview mode. Target: $ARGUMENTS (if it's a path, read it; if empty, use the most recently modified file in `docs/specs/` — and if there is none, ask me what to grill).

Goal: reach shared understanding BEFORE any implementation. Do NOT write code, do NOT start the pipeline, do NOT edit product files.

Rules of the interview:
1. **One question at a time.** Ask, then WAIT for my answer before asking the next.
2. **Recommend an answer with every question** ("I'd go with X, because …") so I can simply say "yes".
3. **Facts vs decisions:** anything verifiable in the repo is a fact — go read the code (Read/Grep) instead of asking me. Only true decisions reach me: trade-offs, scope, UX, priorities.
4. **Walk the decision tree systematically:** resolve foundational branches before the ones that depend on them; after each answer, re-derive which branches remain open (answers can open new ones).
5. **Stop condition:** when no decision branch remains open, say "no open decisions left" and stop interviewing.

Finish: write the resolved decisions into the spec — `docs/specs/<slug>.md`, a **Decisions** section with one `Q -> A (why)` line each (create the spec if it doesn't exist; update it in place if it does). Then suggest `/feature` (or `/quick`) to implement.
