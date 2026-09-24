---
description: Implement an APPROVED proposal — planner (if needed) -> coder (self-verify) -> reviewer; tester only if you ask for tests.
argument-hint: <path to the proposal file, e.g. proposals/2026-06-16-cache.md>
---

I have APPROVED the proposal in: $ARGUMENTS

Act as the **orchestrator**:
1. Read the proposal file above.
2. Confirm with me which item(s) to implement (if there are several).
3. For each chosen item, run the short pipeline: **planner** (if design is needed) -> **coder** (implement + self-verify: build/run) -> **reviewer**. Add **tester** only if I asked for tests.
4. Update docs via **docwriter**.
5. Mark the proposal as handled (e.g. add `STATUS: APPLIED <date>` at the top of the file).

This step is allowed to change code, because it has human approval.
