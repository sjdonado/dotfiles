---
name: worktree
description: Reuse the current task checkout and prepare ticket-linked T3 worktrees for new threads or isolated work.
---

Reuse the checkout that already owns the task or PR branch. Honor the user's branch and placement choice; feedback does not create another checkout. Confirm ownership from the host context and Git state rather than guessing from a directory name.

Before creating a new checkout or branch, apply the shared policy's ticket linkage: use the associated Linear identifier or git-bug human title ID when available, prefer an applicable tracker-supplied branch name, and otherwise choose a routine descriptive name. Read the relevant ticket before relying on its scope. Use the actual PR base for follow-ups and the default branch for independent work. Honor explicit user choices; do not rename the existing task branch merely because feedback arrived.

Use T3's workspace operations, not shell-created worktrees or a terminal worktree manager. An isolated child belongs on delegate_task with isolation worktree. For a requested new top-level thread in a Git repository, default to `t3_thread_launch` with an explicit worktree workspaceStrategy and ticket-linked branch. Apply `../../../../task-linkage.md`, relative to this helper's resolved directory, before the call. Use root or existing_worktree only for explicit user reuse; an inheriting batch tool is not the default for independent threads. Never emulate workspace binding with cd in a prompt or create a top-level thread merely to obtain isolation.

Use the returned absolute checkout path for every subsequent read, edit, check, and write. Preserve other tasks' dirty work and never copy secrets, ignored configuration, or task notes into a new checkout. Keep the current task in its existing checkout if no new isolation is needed. If required isolation cannot be obtained through an available host operation, report that limitation rather than silently switching branches or creating a new conversation.

Report a newly created checkout once. Cleanup is separate: remove no checkout or branch without authorization and preservation of its work.
