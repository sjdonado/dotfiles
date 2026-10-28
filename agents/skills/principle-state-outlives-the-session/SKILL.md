---
name: principle-state-outlives-the-session
description: Guidance for durable state when work spans sessions, substantial steps or handoffs. Small self-contained edits need no ledger.
---

Use durable task state when work spans sessions, several substantial steps or a handoff. A small self-contained edit needs no branch note or task list.

Reuse an existing OpenSpec tasks.md or project task list as the single checklist. Otherwise, when needed, keep one ignored task list at .agent/<branch-key>.tasks.md. Encode the branch name by replacing % with %25, then / with %2F. Do not create duplicate lists for the same work.

A useful branch note at .agent/<branch-key>.md carries Contract, State and Carry forward. Contract begins with Purpose, End state and Key tasks, including the authoritative checklist path when one exists. Record the user's scope, consequential assumptions, check evidence and next action; do not write an event log. A note records authorization and never grants it.

Keep .agent/ ignored through the repository's local info/exclude. Update state at meaningful checkpoints, after scope changes and before a handoff. Read it on continuation and reconcile it with Git and authoritative artifacts. A missing note alone is not a blocker: recover what is known, and ask only when essential intent cannot be recovered. Report a failed save. After a verified merge, land can archive useful notes and remove the local checklist.
