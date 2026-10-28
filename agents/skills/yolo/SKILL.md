---
name: yolo
description: Complete explicitly requested autonomous delivery through the agreed outcome, including a green PR when requested. Use for "yolo this" or "work independently until the PR is green", not ordinary plan approval.
---

Enter only for an explicit request for autonomous delivery. A plan approval, bounded implementation request or existing PR does not select this recipe. Use the user's agreed scope or existing specification; do not require a second contract format.

1. Inspect the task, relevant code and existing checks. If starting from the default branch, resolve the task workspace through worktree before editing. Otherwise reuse the existing task checkout.
2. Resolve routine decisions yourself (principle-decide-then-declare). Keep essential state for a long run (principle-state-outlives-the-session).
3. Implement the agreed behavior and verify it with appropriate tests and checks (principle-test-agreed-decisions and principle-prove-it-works). Fix failures caused by the change.
4. Seek independent review only for a concrete unresolved concern or the user's request, using agent-review. Delegate when it helps (principle-delegate-down-a-tier).
5. When the agreed outcome is a PR, use open-pr and drive its required checks and mergeability green. Do not merge.

Continue until the agreed outcome is achieved. Stop only for a genuine blocker, missing authority or a premise contradicted by evidence (principle-stop-at-the-rabbit-hole). Report unresolved checks honestly and save the next action when blocked. Routine lint failures, mechanical conflicts and reversible implementation choices are work to resolve, not checkpoints for permission.
