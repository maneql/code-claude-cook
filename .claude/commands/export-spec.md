---
description: Summarize the WHOLE project (design, features, verification, suggestions — referencing the onboarding doc) and export a developer-level Excel blueprint you can use to build a new version. Output language optional (English default).
argument-hint: (optional) output language, e.g. "Vietnamese"; omit for English
---

Act as the **orchestrator**. Produce a complete, **developer-level feature blueprint** of this project and export it to Excel. Output language: **$ARGUMENTS** (default: **English**).

1. **Gather sources** (read and summarize — keep context lean, delegate heavy reading to **explorer**, let **planner**/**analyst** structure it):
   - `docs/<project>-onboarding.md` (run `/onboard` first if it is missing).
   - The Project profile in `CLAUDE.md` (run `/tune-agents` if it is empty).
   - `docs/specs/`, `docs/plans/`, `docs/fixes/`, `proposals/` if present.
   - The actual code: modules, endpoints/APIs, data model, key flows.
2. **Compile a structured spec** and write it to `docs/spec/<project>-spec.json`. Write **all human-readable text in the chosen language** (sheet names, headers, values).

   **The workbook structure is flexible — shape it to THIS project.** The renderer accepts any number of sheets and any columns/rows per sheet, so adapt the baseline below: **drop** sheets that don't apply (no HTTP API → omit *APIs*), **add** sheets the project needs (e.g. *Screens/UX*, *Permissions & Roles*, *Background jobs*, *Integrations*, *Config & Env*, *Non-functional/SLA*, *Glossary*), and **rename/extend** columns (e.g. add *Owner*, *Since version*, *Test refs*). Keep what's relevant; don't pad with empty sheets.

   Baseline to start from (`kv` sheet = key/value rows; `table` sheet = `columns` + `rows`):
   ```json
   {
     "meta": {"project":"","version":"","language":"","generated":"YYYY-MM-DD","source":"docs/<project>-onboarding.md"},
     "sheets": [
       {"name":"Overview","type":"kv","rows":[["Project",""],["Purpose",""],["Stack",""],["Architecture",""],["Build/Run/Test",""],["Version / next",""]]},
       {"name":"Features","type":"table","columns":["ID","Feature","Module/Area","Description","User value","Inputs","Outputs","Business rules","Dependencies","Data touched","Acceptance criteria","Edge cases","Status","Priority","Notes"],"rows":[]},
       {"name":"Data model","type":"table","columns":["Entity","Field","Type","Constraints","Relationships","Notes"],"rows":[]},
       {"name":"APIs & Interfaces","type":"table","columns":["Method","Path/Name","Auth","Request","Response","Errors","Feature ref"],"rows":[]},
       {"name":"Dependencies","type":"table","columns":["Name","Version","Purpose","Risk"],"rows":[]},
       {"name":"Verification","type":"table","columns":["Area/Feature","How verified","Result","Issues"],"rows":[]},
       {"name":"Suggestions","type":"table","columns":["Area","Suggestion","Impact","Effort","Source"],"rows":[]}
     ]
   }
   ```
   Be concrete and **exhaustive at the feature level** — enough for a developer to rebuild the project as a new version. List every real feature; mark unknowns explicitly instead of inventing. (See `scripts/spec-template.json` for a filled example — your sheet/column set may differ.)
3. **Export to Excel:**
   `python3 scripts/export-spec.py docs/spec/<project>-spec.json docs/spec/<project>-spec.xlsx`
   (Windows: `python scripts\export-spec.py docs\spec\<project>-spec.json docs\spec\<project>-spec.xlsx`)
   If it reports that `openpyxl` is missing, show the user the install command it printed and ask before installing anything.
4. Report the path to the `.xlsx` and a 5-line summary (feature count, modules, open items/suggestions).

Rules: write only under `docs/spec/`; no product-code changes; no commits. The JSON is the single source of truth — the script just renders it, so regenerating after edits is cheap.
