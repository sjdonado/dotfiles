---
name: iteration
description: Build a small working slice and refine it with owner feedback. Use when trying an approach or discovering requirements through use.
---

Build the smallest useful slice, check it, and let the owner react. This recipe is optional; a clear ordinary edit does not need an iteration ledger.

- Reuse the task's checkout; use worktree when separate work needs isolation.
- Resolve what is known and what the owner needs to try. Record decisions only when their persistence helps (principle-state-outlives-the-session).
- Build a working slice, using tests where they help establish behavior (principle-test-agreed-decisions), and run appropriate checks (principle-prove-it-works).
- Present how to try it, what it demonstrates and what remains undecided. Fold feedback into the same task.

A request for a runnable demo can use poc. An explicit request for autonomous delivery can use yolo. A direct request to publish can use open-pr. These are choices, not graduation gates; ask only about actual unresolved scope or authority. If evidence disproves the premise, explain it and stop that approach.
