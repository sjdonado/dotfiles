---
name: principle-state-outlives-the-session
description: Not a workflow; read when a step names it. The branch note and the one task list that let work survive a session. Read before the second step of any work that edits files, and on continuation.
---

Not a workflow: workflows and building blocks read this when a step names it.

**The branch note.** For work spanning sessions or rounds, keep one ignored note at `.agent/<branch-key>.md` in the task's worktree. Encode the branch name by replacing `%` with `%25`, then `/` with `%2F`. Before creating it, add `/.agent/` to the file `git rev-parse --git-path info/exclude` resolves; never commit the note. Read it on continuation unless already current in context.

It holds **Contract**, **State** (branch, checks, next action) and **Carry forward** (essential rationale, sourced findings, rejected reviews). Contract opens with three fixed lines, in order:

- **Purpose**: why this work exists, in one sentence.
- **End state**: what done looks like, naming the acceptance evidence, machine-checkable where possible.
- **Key tasks**: the path of the single task list.

Write them at the first checkpoint of any workflow that edits files, from the request, the conversation and repository evidence before asking, marking as assumed what you could not derive. When the user changes the purpose or end state, rewrite the line before any further edit and say in one line what changed. Downstream workflows read these lines by path; never substitute a summary when dispatching a subagent. Recommend `handoff` in one line when the purpose or end state has changed twice or the conversation was compacted, then continue.

Read-only skills consume the note without writing it; the next authorized writer preserves their relevant conclusions, and any conclusion available only in conversation. Reuse resolved check commands and loaded skills while their inputs stay current. At PR updates, reconcile the rationale with the diff and checks.

Specs and `tasks.md` stay authoritative; reference them instead of duplicating tasks. A note records approval, never grants it. Check its branch and checkpoint against Git. Save it at each checkpoint, replacing superseded state, with the next owner and action; report a failed save instead of claiming one. No note is written for the default branch. After a verified merge, `land` completes the note and moves it to the main checkout's `.agent/archive/`.

**The task list.** Every task has exactly one task list, and the note is never it. Under an OpenSpec change it is the change's `tasks.md`; otherwise write `.agent/<branch-key>.tasks.md` before the second step of the work, with numbered items under headings, ticked as each lands. Tick a check item only after observing it succeed. Hand a subagent the list's path instead of restating progress. Adopting an OpenSpec change mid-flight folds the ledger's items into its `tasks.md` and deletes the ledger, saying so. `land` deletes the list when the work merges.

A missing note alone is not a blocker: recover from authoritative artifacts and context, then recreate it. If an essential requirement cannot be recovered, ask one focused question and leave dependent behavior unchanged. No event log, and no second task list.
