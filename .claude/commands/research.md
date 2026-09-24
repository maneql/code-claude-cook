---
description: Research a question against PRIMARY sources (official docs, source, changelogs) and save cited findings to docs/research/. Feeds planner/spec decisions with facts instead of guesses.
argument-hint: <the question, e.g. "which rate-limiting approach for ASP.NET Core 8?">
---

Delegate to the **researcher** subagent (via the `Agent` tool): $ARGUMENTS

1. Pass the question verbatim, plus useful repo context: the stack from CLAUDE.md's Project profile and any obviously related code paths. Do NOT pre-answer the question yourself.
2. The researcher writes `docs/research/<slug>.md` (per-claim citations, version caveats, "what this means for us") and returns the short answer.
3. Relay the short answer + the file path. If this research feeds a spec or plan, reference the file there by path — specs/plans cite `docs/research/<slug>.md`, they don't copy it.

Rules: no product-code changes. If the question is answerable from the repo alone, use the **explorer** instead and say so.
