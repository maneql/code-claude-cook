---
description: Review the project and PROPOSE (don't execute) new features + performance optimizations. Writes a proposal and asks for approval.
allowed-tools: Read, Grep, Glob, Bash(git log:*), Bash(git diff:*), Bash(git status:*), Bash(git diff --stat:*), Write(proposals/**)
model: opus
---

Use the **optimizer** subagent to review the current repo.

Context you may use:
- Recent history: !`git log --oneline -20`
- Pending changes: !`git status --short`

Ask the optimizer to:
1. Propose 3-6 items: features to add and/or performance/tech-debt optimizations.
2. Write `proposals/<YYYY-MM-DD>-<slug>.md` per the template in the optimizer's system prompt.
3. NOT modify any product code (it may only Write into `proposals/`).
4. End with `PROPOSAL_READY: proposals/<file>` so the notification mechanism can detect it.

Reminder: this is a PROPOSE-ONLY step. Execution requires me to run `/apply-proposal`.
