---
description: Draft a clear, scoped Linear ticket from a request, then create it via Linear MCP after confirmation
---

Turn a request into a well-formed Linear ticket. Draft first, create only after the user confirms.

Input: $@

The input is a raw request: a bug, a feature, or an adjustment. It may be terse, a paste from Slack, or a rough idea. Your job is to shape it into a ticket a teammate can pick up cold, without over-engineering the write-up.

## Writing rules

- Never use em-dashes (—) or en-dashes (–). Use periods, commas, or parentheses.
- Less is more. Every line earns its place. Cut restatement, hedging, and filler.
- Plain language. Short sentences. No buzzwords, no ceremony.
- Concrete over vague: name the file, endpoint, screen, or error, not "the relevant part".
- Technical enough to act on, not a design doc. Link or cite code as `path:line` when it sharpens scope.

## Steps

1. Parse the request. Identify type (bug / feature / adjustment) and the actual outcome wanted.

2. If the request is ambiguous or missing something load-bearing (no repro for a bug, unclear scope for a feature, no acceptance signal), STOP and ask specific questions. Do not invent requirements.

3. Investigate code only as much as needed to ground scope and cite `path:line`. Use the "scout" subagent only for a broad search.

4. Draft the ticket in this shape (omit a section if it truly adds nothing):

   **Title** — imperative, specific, under ~70 chars. "Fix token expiry off-by-one in auth middleware", not "Auth bug".

   **Context** — 1 to 3 sentences: why this exists, the user or system impact. The "why".

   **Requirements** — bullet list of what must be true when done. Behavior, not implementation. For a bug: expected vs actual, plus repro steps.

   **Technical notes** — where it lives (`path:line`), constraints, gotchas, suggested approach if one is clearly right. Keep it hints, not a spec. Skip if trivial.

   **Acceptance** — short checklist of done conditions. Testable.

5. Show the draft. Ask the user to confirm, and for any missing target fields (team, project, labels, priority, assignee).

6. On confirmation, create it with the Linear MCP (`linear_create_issue`). Report the created issue ID and URL. Do not create before explicit confirmation.

Constraints: no code edits. Draft is text only until the user approves creation.
