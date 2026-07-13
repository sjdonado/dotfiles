---
description: Address PR review comments — fix legit ones and reply with the fixing commit hash, reject others with a reason; also fix red CI and outdated branch
---
Address review feedback on a pull request. Use the `gh` CLI for all PR interaction (comments, CI status, branch state).

Input: $@ (a PR number, URL, or branch name; if omitted, resolve the PR for the current branch via `gh pr view`).

Steps:

1. Load the PR: `gh pr view <pr> --json number,headRefName,baseRefName,mergeStateStatus,state,url`. Fetch all review threads and comments (`gh pr view --json reviews,comments`, and `gh api` on the review-comments endpoint for inline threads with their IDs). Group by file/thread.

2. Create a live progress checklist before changing code:
   - Resolve the repository root with `git rev-parse --show-toplevel` and the local exclude file with `git rev-parse --git-path info/exclude`.
   - Add `/PI_PROGRESS.md` to that exclude file if absent. Never modify `.gitignore` for this.
   - Write `PI_PROGRESS.md` with `## Current run` and `## Gotchas` sections. Reset only `## Current run`; preserve relevant existing gotchas and discard old checklist history.
   - Under `## Current run`, add Markdown checkboxes for: load the PR, assess comments, fix accepted feedback, inspect and fix CI, update the branch if needed, review the result, await approval, push, reply to threads, and finish. Add one task-specific item per review thread and failing check.
   - Update the file immediately after each step completes and before starting the next step. Never begin the next checklist item while the completed item is still unchecked. Record verdicts and commit hashes beneath the relevant item.
   - Keep `## Gotchas` concise and current. Add only durable assumptions, known risks, skipped checks, environment blockers, non-obvious decisions, or failed approaches worth avoiding. Prefix new entries with `[address-review]`, remove resolved or obsolete entries, and update gotchas before moving to the next checklist item. Leave the completed file in place.

3. For EACH review comment, judge it:
   - **Legit** — the reviewer is right. Make the fix in code. Keep one focused commit per comment (or per tightly-related cluster). After committing, capture the short hash.
   - **Not legit** — the change is wrong, out of scope, or already handled. Do not change code. Draft a concise reason to reject.

   Prefer to handle straightforward fixes directly. For a wide or risky change, scout first (use the "scout" subagent) before editing.

4. Commit fixes locally as you go. Do not push or reply yet — batch that for step 7 after review below.

5. Red pipelines: check CI with `gh pr checks <pr>`. For each failing check, inspect logs (`gh run view <run-id> --log-failed`), find the cause, and fix it in a commit. Re-run only what's needed. Distinguish real failures from flakes (note flakes, re-trigger rather than "fix").

6. Outdated branch: if `mergeStateStatus` is `BEHIND` (or base has moved), update the branch from the base (usually `main`). Default to a merge of `main` into the branch to preserve history and avoid rewriting pushed commits. Resolve conflicts properly — never discard the reviewer's or main's changes blindly. Only rebase/force-push if the user explicitly asks.

7. STOP and confirm before any external action (pushing commits, replying to comments, re-running CI). Show a summary: per-comment verdict (fix → which commit / reject → reason), CI fixes, and the branch-update plan. Push and reply only after the user approves.

8. After approval and push, reply to each thread with `gh api` (POST to the review-comment reply endpoint):
   - Fixed: reply with the fixing commit hash, e.g. `Fixed in <shorthash>.` (a one-line note on what changed if not obvious).
   - Rejected: reply with the reason, respectfully and specific.

Constraints: never force-push or rebase a shared branch without explicit approval. Never resolve a conflict by dropping changes. Keep commits focused and messages conventional. If a comment is ambiguous, ask the reviewer (draft the clarifying reply) rather than guessing.
