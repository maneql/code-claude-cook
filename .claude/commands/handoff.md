---
description: Compact the current conversation into a handoff/checkpoint doc in docs/state/ so a fresh session can continue via /resume. Use before stopping mid-work in a free-form session
argument-hint: (optional) what the next session will focus on
---

Write a handoff document summarizing THIS conversation so a fresh session can continue the work. Save it to `docs/state/<slug>.md` (derive a short slug from the topic; if this conversation already has a checkpoint file there, UPDATE that file instead of creating a second one).

Rules:
- **Reference, don't duplicate:** point to artifacts by path (intake brief, spec, plan, onboarding doc, proposals, research notes, changed files) instead of copying their content.
- **Capture what is NOT on disk yet:** the goal, decisions made in conversation (and why), what's done, what's pending, dead ends already ruled out, and the exact next step.
- **Suggested next commands:** end the doc with the command(s) the next session should run first (e.g. `/resume <slug>`, `/feature ...`, `/verify ...`).
- **Redact secrets** — API keys, passwords, tokens, PII never go into the doc.
- If I passed arguments, treat them as what the next session will focus on and tailor the doc to that.
- No product-code changes: writing the handoff file is the ONLY edit.

Finish: print the handoff path and a 3-line summary, and remind me that the next session starts with `/resume`.
