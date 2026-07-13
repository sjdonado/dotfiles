---
description: Apply bullet-list feedback to the current PR, commit and push, then optionally run one final review
---

Apply implementation feedback: $@

Load and follow the `ponytail` skill. Keep every change minimal and address the underlying requirement, not only the literal wording.

The input is usually a bullet list reviewing work previously completed by `/yolo`.

1. Resolve the current branch and its open PR with `gh pr view`. This workflow updates that branch. Do not create another branch or PR. If no open PR exists, STOP and ask for the intended PR or branch.

2. Parse every feedback bullet into a separate actionable item. Investigate the relevant code before deciding how to implement it.

3. If any item is ambiguous, contradictory, or requires a product decision, ask specific questions and STOP. This is the only pre-implementation clarification point. Otherwise, proceed without confirmation until the final optional-review question.

4. Resolve the repository root with `git rev-parse --show-toplevel` and the local exclude file with `git rev-parse --git-path info/exclude`. Add `/PI_PROGRESS.md` to that exclude file if absent; never modify `.gitignore`.

   Write `PI_PROGRESS.md` with `## Current run` and `## Gotchas` sections. Reset only `## Current run`; preserve relevant existing gotchas and discard old checklist history.

   Under `## Current run`, track:
   - [ ] Parse feedback
   - [ ] Investigate affected code
   - [ ] One checkbox per feedback item
   - [ ] Run checks
   - [ ] Verify every feedback item is addressed
   - [ ] Commit
   - [ ] Push
   - [ ] Ask about one final review

   Update each checkbox immediately after completion and before starting the next item. Never begin the next checklist item while the completed item is still unchecked.

   Keep `## Gotchas` concise and current. Add only durable assumptions, known risks, skipped checks, environment blockers, non-obvious decisions, or failed approaches worth avoiding. Prefix new entries with `[feedback]`, remove resolved or obsolete entries, and update gotchas before moving to the next checklist item. Leave the completed file in place.

5. Apply every feedback item. Use subagents only when the work genuinely benefits from broader reconnaissance or parallel investigation.

6. Run the project's relevant checks and fix failures caused by the changes. Verify every feedback item has a corresponding change or an explicit reason it required no change. Do not run a separate code review or call a review tool/subagent before committing and pushing.

7. Commit with conventional messages and push the current branch. Do not open or merge a PR. Review must never block this step.

8. Only after the push succeeds, ask whether to run one final review of the accumulated PR diff. Mention that review is best deferred if more feedback rounds are expected. If declined, finish. If approved, run the review once and report findings without changing code, committing, or pushing again unless explicitly asked.
