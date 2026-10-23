---
name: iteration
description: Find the requirements by building, in cheap rounds of owner feedback inside the task's own worktree, then graduate to a PoC or yolo, or kill the premise. Use when requirements are still open, such as "implement this", "go build it", "try it", "spike it", "let me try it first".
---

The default route into implementation. A loop with the owner inside it: build the smallest slice, make it green locally, let the owner try it, and let what they learn change the requirements. Everything expensive (tests, adversarial review, publication) is deferred to `yolo`, so a round of feedback costs one slice and the local checks.

Input: a tracker issue, an explore conclusion, a handoff document, or a plain description. None is a contract: the contract is this workflow's output. A handoff says what is known and tried; its open questions are what to build against.

## Setup

1. Changes to an open PR belong to `feedback`; if ownership is unclear, ask and stop before editing.
2. Create the task's worktree with the `worktree` block, or reuse it on continuation.
3. Resolve the local rungs of the ladder (type check, lint, existing tests) per `principle-prove-it-works`. The remote rungs do not exist here.
4. Write the branch note and the task list per `principle-state-outlives-the-session`. The note's Contract carries the requirements ledger: confirmed and assumed requirements, deferred behavior, and the decisions a test must pin later.

## Each round

1. **Build** the smallest slice that gives the owner something new to react to, after saving any changed End state. Aim at a working version: write no test files (`principle-test-agreed-decisions`), prove the slice by running it.
2. **Check** with the local rungs only, green before showing. No adversarial review, no commit, no push. One exception: a slice that touches data, auth, concurrency, migration, or a public contract gets a single Reviewer B pass from `agent-review` before it is shown.
3. **Checkpoint** the note: ledger, rationale, checks, and the awaiting-feedback next action. Report a failed save.
4. **Present** what was built, how to try it (the `run` skill when seeing it live helps), what the round taught, and what changed in the ledger. Stop and wait; stopping every round is the design here.
5. **Fold feedback in**: update the code, the ledger, or both, saying what survived, changed, or died. A requirement reversed twice is a `grill-me` target.

**Forks, optional.** Once End state is written and two approaches are worth comparing, build each in a disposable worktree through a subagent one tier below (`principle-delegate-down-a-tier`), compare them against End state, and present the comparison as the round.

## Exit states

Exactly one:

- **PoC.** The owner wants a runnable demo, not a finished change: continue with `poc`.
- **Yolo.** The owner says the shape is right. Finalize the ledger (confirmed requirements, decisions with rejected alternatives, decisions a test must pin, marked unit or journey, and anything left prototype-quality), present it, and wait: the ledger is the agent's own output and promotes only once the owner accepts that scope. On acceptance, `yolo` continues in this worktree with the ledger as its contract.
- **Kill.** The work disproved the premise, which is a success. Record what died and the evidence, leave the worktree for the owner to remove, and offer `create-ticket` or `openspec-explore` for what replaces it.

Never commit, push, open a PR, or merge from this workflow. Asked to ship from here, route to `yolo` or `open-pr` with the ledger's acceptance.
