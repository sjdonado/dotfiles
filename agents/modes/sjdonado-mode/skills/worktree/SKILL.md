---
name: worktree
description: Reuse the T3 task checkout and request host-managed isolation only when separate work needs it.
---

Reuse the checkout that already owns the task or PR branch. Honor the user's branch and placement choice; feedback does not create another checkout. Confirm ownership from the host context and Git state rather than guessing from a directory name.

When separate isolation is required, resolve the base and a routine branch name from the task. Use the actual PR base for follow-ups and the default branch for independent work. Do not ask for a routine branch name.

Use T3's workspace operations, not shell-created worktrees or a terminal worktree manager. An isolated child belongs on delegate_task with isolation worktree. A new top-level thread requires an explicit user request; it is not an isolation fallback. For a requested new thread, set workspaceStrategy through the host and follow its base rules. Never emulate workspace binding with cd in a prompt.

Use the returned absolute checkout path for every subsequent read, edit, check, and write. Preserve other tasks' dirty work and never copy secrets, ignored configuration, or task notes into a new checkout. Keep the current task in its existing checkout if no new isolation is needed. If required isolation cannot be obtained through an available host operation, report that limitation rather than silently switching branches or creating a new conversation.

Report a newly created checkout once. Cleanup is separate: remove no checkout or branch without authorization and preservation of its work.
