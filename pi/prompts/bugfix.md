---
description: From a pasted Linear bug prompt (or ID), scout the root cause and propose fixes with pros/cons (no implementation)
---
Investigate a bug reported in Linear. This is analysis ONLY — do NOT write, edit, run, or commit any fix.

Input: $@

The input is usually a full Linear issue prompt pasted directly (starts with "Work on Linear issue <ID>" and contains `<issue>`, possibly `<video-transcripts>`, `<comment-thread>`, and `<issue-relations>` blocks). Treat that pasted content as the PRIMARY source — it carries data the Linear MCP does not return, notably `<video-transcript>` text and full comment threads.

Steps:

1. Parse the pasted input. Extract: title, description, labels, expected vs actual behavior, repro steps, error messages/stack traces, and the affected component. If `<video-transcripts>` are present, use the timestamped transcript as repro evidence (it describes what the recording shows). Read every `<comment-thread>` — comments often already contain triage notes, suspected root cause, or a draft PR.

2. Use the Linear MCP only to supplement: if the input is just an ID/URL (no `<issue>` block), call `linear_get_issue` (with `includeRelations: true`) to fetch it. Note: the MCP description gives only a link to any video, NOT its transcript, and omits comment threads — so prefer pasted content when both exist. Fetch comments via MCP if the pasted input lacks them.

3. If, after parsing, there is not enough to locate the bug — no repro, vague symptom, missing error text, or ambiguous scope — STOP and ask specific clarifying questions. Do not guess. List exactly what you need.

4. Use the "scout" subagent to find all code relevant to the symptom (error strings, function/module/component names from the ticket, transcript, and comments). Run parallel scouts if the symptom spans areas.

5. From scout's findings, determine the root cause. Trace the actual code path end to end. Cite evidence as `path:line`. If a comment already proposes a root cause or fix, verify it against the code rather than assuming it correct.

6. Output:
   - **Summary** — one line: the bug + confirmed or suspected root cause.
   - **Root cause** — the mechanism, with `file:line` evidence. State confidence (confirmed / likely / unclear).
   - **Tentative fixes** — 2-4 options. For each: what changes, **Pros**, **Cons**, and risk/blast radius.
   - **Recommendation** — preferred option and why. If uncertain, list open questions instead.

Constraints: no code edits, no file writes, no commits, no running the fix. If the root cause stays unclear after scouting, say so and list what's needed to confirm it.
