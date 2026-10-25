---
name: open-pr
description: Commit, push and open or update a PR when requested, then complete its required checks. Does not require autonomous mode or independent review.
---

Use the user's publication authorization for the specific scope. A direct request to open or update the PR covers its commits, push and description refresh. Before publication, resolve behavior the user explicitly left undecided; do not invent a fallback to complete the PR. An agent-written ledger is not an extra acceptance gate.

1. Inspect the branch and diff, preserving unrelated work. Never commit to the default branch. Use worktree when a task checkout is needed.
2. Establish relevant local check evidence (verification and principle-prove-it-works). Reuse current results when their inputs have not changed. Stop before committing, pushing or opening a PR while a relevant required local check is failing. Fix failures within the authorized scope; if the user prohibited edits, report the failure without publishing.
3. Stage only the intended files, commit per principle-write-for-the-reader, and push the task branch. Do not add an independent-review requirement.
4. Create a normal PR, or a draft when requested. Update an existing PR in place, preserving issue links, checklists and human-written context. Avoid temporary title markers.
5. Write the body with the problem, resulting behavior, actual verification and meaningful limitations. Use the repository's template when present. Include a diagram or screenshot when it explains behavior better than prose. With gh, use `--body-file <path>` or `--body-file -` with stdin for multiline bodies, then read the body back. Never pass literal `\n` sequences through a shell `--body` argument.
6. When PR delivery was requested, complete required checks and check mergeability. Fix in-scope failures, rerun flakes once, and resolve mechanical conflicts. Ask before a semantic conflict or rewriting a shared branch outside existing authorization. Prefer the host's event-driven watcher when available; never delegate polling.
7. Report the PR URL and final check state, or the concrete blocker and next action. Never merge. Update existing durable task state when useful.
