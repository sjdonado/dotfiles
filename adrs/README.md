# Decision records

These records explain major changes to this setup so an agent can understand why the current structure exists. Commands and operating rules belong in AGENTS.md and the files that implement them; ADRs preserve reasoning, alternatives, and consequences.

- `0001-repairable-shell-provisioning.md`: why conventional package managers replaced Nix without giving up explicit declarations or outcome checks.
- `0002-opt-in-t3-development-mode.md`: why development procedures live behind one explicit mode and T3 owns orchestration.
- `0003-manual-harness-checks.md`: why area-indexed manual checks replaced the eval framework, and what counts as evidence.
- `0004-record-reasoning-without-a-spec-workflow.md`: why concise decision records replaced the specification lifecycle.

Add a short record when a major decision would otherwise lose its reasoning. Describe the problem, the chosen approach, the meaningful alternative, and what was learned in whatever form makes that decision clear. Small edits need no record. When a decision changes, explain the replacement and identify what it supersedes rather than silently rewriting the earlier rationale. Keep task progress, generated schemas, and speculative acceptance claims out of this directory.

The removed planning artifacts remain in Git history before this change. Some contained incomplete checks and superseded proposals; their removal does not establish that the old work passed. Read current source and current verification evidence before treating a historical decision as present behavior.
