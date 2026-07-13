---
description: Autonomous requirements-to-PR — clarify once, understand deeply, then implement lazily and open a PR with no further input
---

Autonomous implementation of: $@

Load and follow the `ponytail` skill for all coding decisions — laziest solution that works, YAGNI, reuse before writing, no over-engineering.

Flow: understand the problem, clarify requirements ONCE if needed, then run to completion without further human interaction, ending in an open PR.

1. Understand first. Investigate the codebase and the actual problem before touching anything. What already exists, what the real requirement is, what the smallest change is that satisfies it. Do not design a solution before the problem is clear.

2. Clarify only if requirements are ambiguous or underspecified. Ask specific questions and STOP. This is the ONLY human interaction point. If requirements are already clear, skip straight to implementation — do not ask for confirmation.

3. Once requirements are clear, proceed fully autonomously. No further questions. If a minor decision is ambiguous, pick the most reasonable minimal option and note it in the PR body.

4. Create a live progress checklist before changing code:
   - Resolve the repository root with `git rev-parse --show-toplevel` and the local exclude file with `git rev-parse --git-path info/exclude`.
   - Add `/PI_PROGRESS.md` to that exclude file if absent. Never modify `.gitignore` for this.
   - Write `PI_PROGRESS.md` in the repository root with Markdown checkboxes for: understand requirements, investigate existing code, define the minimal implementation, implement, run checks, review the diff, commit, push, and open the PR. Add task-specific substeps where useful.
   - Update the file immediately after each step completes. Record failures, assumptions, or skipped checks beneath the relevant item. Leave the completed file in place.

5. Implement on a branch off the current base. Keep it minimal per ponytail. Run the project's checks (typecheck, lint, tests, build — whatever exists) and fix failures.

6. Commit with conventional messages, push, and open a PR (`gh pr create`) summarizing what changed, why, and any assumptions. Do not merge — leave open for human review.

Use subagents only if the task genuinely benefits (large recon, parallel work); otherwise do it directly. Do not force-push shared branches.
