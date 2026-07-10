---
description: Autonomous implement — plan, confirm once, then build/review/fix and open a PR with no further input
---
Autonomous implementation of: $@

Flow: agree on a plan FIRST, then run to completion without asking for more input, ending in an open PR.

1. Use the "scout" subagent to gather context, then the "planner" agent to produce a concrete plan. Present the plan and STOP for user confirmation. This is the only interaction point.

2. After the user confirms the plan, proceed fully autonomously — do NOT ask further questions. If a decision is ambiguous, pick the most reasonable option consistent with the plan and note it in the PR body.

3. Create a branch off the current base for the work.

4. Chain via the subagent tool, passing output with `{previous}`:
   - "worker" agent implements the confirmed plan.
   - "reviewer" agent reviews the implementation.
   - "worker" agent applies the review feedback.

5. Run the project's checks (typecheck, lint, tests, build — whatever exists). Fix failures. Repeat review→fix if the reviewer flagged blocking issues.

6. Commit with conventional messages, push the branch, and open a PR (`gh pr create`) with a summary of what changed, the plan followed, any assumptions made, and test results.

Constraints: one confirmation gate at the plan (step 1) only. No further prompts. Do not force-push shared branches. Do not merge the PR — leave it open for human review.
