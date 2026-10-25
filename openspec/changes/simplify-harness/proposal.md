# Proposal

## Why

This session turned a small Handy settings change into branch-name confirmation, workflow selection and two independent reviews. Extracting smaller skills did not improve the experience because mandatory workflow transitions and diff-size rules still controlled the agent's decisions.

## What Changes

- **BREAKING**: replace mandatory routing and graduation with independent capabilities and optional recipes. Clear requests can be implemented directly.
- **BREAKING**: select autonomous PR delivery only through an explicit request; approving a plan or naming a bounded task no longer selects yolo or publication.
- Choose checks, tests, delegation and independent review by changed behavior and concrete risk. Remove automatic review from feedback, review repair and yolo, and remove reviewer-count thresholds based on file or line count.
- Reuse the current task checkout, honor the user's placement choice and choose routine branch names without confirmation. Require durable notes only when continuity benefits from them.
- Preserve secrets, scope, unrelated work, publication authority and the prohibition on merging. Finish local work without a mandatory publication prompt.
- Keep the branch's existing building-block extraction, git-bug CLI support and worktrunk integration, while shortening the policy, recipes and documentation.
- Finish the accompanying setup changes: Handy preferences linked into each macOS account's own clone for git-based updates, and mise declared through the shared Nix package list. Keep credentials and model data outside tracked preferences.

## Capabilities

### New Capabilities

- `harness-structure`: independent capabilities, proportional verification and review, and a small always-on policy.
- `task-worktrees`: task checkout reuse and isolation without routine naming gates.
- `pull-request-opening`: scoped publication with appropriate checks, preserving existing PR context.
- `work-graduation`: optional experiments and explicitly selected autonomous delivery without mandatory graduation.

### Modified Capabilities

None. These are revisions of the existing unmerged change's capabilities. Older unarchived harness proposals retain their historical decisions and do not govern this revised contract.

## Impact

The shared policy, locally maintained workflow and principle skills, agents/README.md, repository instructions, existing OpenSpec artifacts and disposable-session scenarios. Upstream locked skill bodies remain unchanged. Setup changes touch macOS preferences and the shared Nix declaration and checks. The pre-existing flake.lock edits are excluded. No host activation, publication or merge is part of this local batch.
