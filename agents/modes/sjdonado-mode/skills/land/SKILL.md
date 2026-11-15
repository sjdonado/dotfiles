---
name: land
description: Verify a PR merged and close existing local task state when requested. Never merge a PR.
---

Verify the identified PR's state, merge timestamp, and head branch through the forge. Unless its state is MERGED, preserve task state, report that it is still open or closed without merge, and stop. Never merge it yourself or substitute another PR.

Locate the associated checkout and existing task state. Close the host task record with merge evidence. If ignored branch notes exist, mark them complete, archive useful context under .agent/archive/ in the primary checkout, and remove their local checklist. Do not switch branches or create notes solely to close absent bookkeeping. These ignored files need no commit or publication.

ADRs preserve reasoning, not a task lifecycle. Do not archive, regenerate, or require an ADR when a PR merges. Update an existing decision only if the merged outcome materially changes its reasoning and the task authorizes that edit. Tracked document changes need their own applicable commit and publication authority; local cleanup does not grant it.

Report the closed state and any task worktree left behind. Delete no worktree or branch unless requested and its work is preserved.
