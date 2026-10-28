---
name: land
description: Verify a PR merged, close existing local task state and archive an associated OpenSpec change. Use for "the PR merged" or "archive the change".
---

Verify the identified PR with `gh pr view <pr> --json state,mergedAt,headRefName`. Unless its state is MERGED, preserve task state, report that it is still open or closed without merge, and stop. Never merge a PR yourself.

Locate the associated checkout and existing note from the head branch. Do not substitute another recently merged PR or create notes solely to close absent bookkeeping.

- With no OpenSpec change, mark the existing note complete with merge evidence, move it to `.agent/archive/` in the primary checkout, and remove the associated local `.agent/<branch-key>.tasks.md` if present. The primary checkout can hold any branch. These ignored local files require no commit, new worktree or publication. Report the result and finish here.
- With an OpenSpec change, verify the implementation against the merged state using openspec-verify-change, then sync and archive through openspec-archive-change. A blocking mismatch stops archival; report it instead of editing application code. Preserve explicitly unverified checks as unverified.

For tracked archive or spec changes, use existing scoped publication authority; if absent, prepare the concrete result before asking to publish it. Never silently commit to the default branch. The exception for explicitly authorized docs bookkeeping requires an unprotected default branch and a clean checkout; otherwise use worktree and open-pr for the authorized publication.

Update useful local task state after archival. Report any task worktree left behind and remove it only when requested, never while it contains unpreserved work.
