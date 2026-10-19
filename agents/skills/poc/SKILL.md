---
name: poc
description: Freeze an iteration as a runnable local demo with its ledger, publishing nothing. Use from iteration, or for "make it a PoC", "turn this into a demo".
---

A PoC proves a concept end to end on this machine. It is the iteration's slice made runnable and honest about what it fakes, not a finished change: no tests, no adversarial review, nothing committed or pushed.

1. Work in the task's existing worktree; without one, this is `iteration`'s job first.
2. Make the slice runnable end to end with one command, and run the local rungs of the ladder green (`principle-prove-it-works`). Write no test files (`principle-test-agreed-decisions`).
3. Record a **Demo** section in the branch note's ledger: the run command, what the demo proves, what it fakes or skips, and what `yolo` would have to harden.
4. Run it, using the `run` skill when seeing it live helps, and present: how to run it, what it shows, and the Demo section. Save the note per `principle-state-outlives-the-session`.

Exit: the owner tries the demo. It stays a PoC, goes back to `iteration` for more rounds, or moves to `yolo` with the ledger as its contract once the owner accepts that scope. Report the worktree per the `worktree` block's report rule.
