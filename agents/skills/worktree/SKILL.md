---
name: worktree
description: Create an isolated task checkout with worktrunk when requested or when separate work needs isolation. Reuse an existing task checkout.
---

Reuse the checkout that already holds the task or PR branch. Honor the user's placement choice; do not create another branch just because a small follow-up arrived. Ask about ownership only when the current context cannot settle it.

When a new worktree is needed:

1. Resolve the base and branch from the user's request or tracker. Otherwise choose a short Conventional Commits type and kebab-case name; no branch-name confirmation is needed. Use the actual PR base for follow-ups and the default branch for independent work.
2. Inspect `wt config approvals list`. Do not approve untrusted project hooks yourself or pass `--yes`; ask only when creation would execute hooks outside existing authorization. Require worktrunk when that is the project's declared tool.
3. Resolve the chosen base, fetch it when appropriate, then run `wt switch --create <branch> --base <base> --no-cd --format json`. Read the absolute checkout path from its JSON. For an existing branch without a checkout, use `wt switch <branch> --no-cd --format json` instead.
4. `--no-cd` does not change the harness working directory. Use the returned absolute path for every read, edit and write, and set each shell command's workdir or use `git -C <path>`. Keep unrelated dirty work in its original checkout and do not silently copy it. New checkouts must not inherit another task's .agent/ notes; remove only copied task notes from the new checkout when the project hook did not already do so.
5. Report a newly created checkout's path and how to open it. Do not repeat worktree cleanup instructions in every later small-change report or remove a checkout that still contains work.

In T3 Code, launch a new top-level thread only when the user explicitly asks for one, using t3_thread_launch with the intended workspaceStrategy. Creating a worktree for the current task does not itself request another conversation. Do not use a prompt-level cd as a substitute for binding a requested new thread to its workspace.
