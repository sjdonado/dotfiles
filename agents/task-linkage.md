# Thread and PR linkage checks

Use the shared policy's isolation and ticket rules before launching a requested T3 thread. Read available task context and the repository's tracker convention first. With git-bug, resolve the human title ID and retain its entity ID for later CLI operations; do not use the entity hash as the branch identifier. With Linear, retain the issue identifier and its supplied branch name when available. If several tickets belong to one task, put its primary ticket first; reference every applicable ticket in the PR. Do not create or renumber tickets just to name a branch.

Keep the preflight record outside tracked source. Its `launch` object is the actual `t3_thread_launch` argument object; the other fields are checker metadata, not tool arguments. For example:

```json
{
  "git_repository": true,
  "tickets": [{"id": "DEMO-7", "tracker": "git-bug"}],
  "launch": {
    "title": "Implement the ticket's requested behavior",
    "workspaceStrategy": {
      "type": "worktree",
      "branch": "fix/demo-7-save-flow",
      "baseRef": "origin/main",
      "startFromOrigin": true
    }
  }
}
```

Run `python3 <resolved-shared-policy-directory>/scripts/check_task_linkage.py launch < <temporary-launch-record.json>` before calling the host. Include the requested project and task in the real tool arguments. Resolve the base under current host rules: independent work normally starts from the remote default branch, while dependent work uses its required base. Keep `baseRef` and `startFromOrigin` explicit. If the user asks to reuse root or an existing worktree, use that strategy and put their instruction in `reuse_reason`; do not rename the reused checkout. A non-Git target uses `"git_repository": false`. Use `"tickets": []` when no associated ticket is available.

For an exact user-selected branch that omits the primary ticket ID, record `branch_exception` with `"basis": "explicit-user-choice"` and a nonempty `reason` containing that instruction. PR checks also allow `"basis": "existing-published-branch"` with the existing PR context as the reason. Neither exception permits changing another task's branch or falsely claiming an unverified ticket is resolved.

At PR preparation, recover the same ticket context. Add `"relation": "resolves"` to completed ticket entries; use `"relation": "refs"` and a nonempty `reason` for partial or related work. Include a plain `Resolves DEMO-7` or `Refs DEMO-7` line in the actual body, outside fenced examples. A mention alone is not a resolution reference. Follow the repository's additional linking rules without inventing a GitHub issue number or URL for a git-bug ticket.

The private open-pr delivery checker uses this same validator, with the actual branch supplied by `--branch`. The standalone equivalent is `python3 <resolved-shared-policy-directory>/scripts/check_task_linkage.py pr --branch <actual-branch> --body-file <prepared-body.md> < <temporary-ticket-context.json>`. It checks declared ticket IDs, branch naming and body references; it does not query a tracker, prove completion, create a thread or close a ticket. The lead verifies the source context and passes only the validated `launch` object to the host. A preflight cannot technically intercept arbitrary tool calls; do not describe it as a host-level enforcement hook.
