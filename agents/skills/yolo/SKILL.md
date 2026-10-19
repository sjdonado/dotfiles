---
name: yolo
description: Finish an agreed task autonomously, through tests, adversarial review, a PR, and every check green, building on an accepted iteration ledger or another settled contract. Use for "yolo it", "finish it", or work whose agreement meets the shared policy's Publication authority.
---

Enter only when the shared policy's agreement test holds: purpose, whole scope and acceptance evidence settled, and a user message covering that scope. An artifact's presence never satisfies it alone. If any part is unsettled, run `iteration` instead.

The contract, cheapest first, each valid only while the user accepted its scope: an iteration ledger or PoC Demo section, plus the work in its worktree; an approved OpenSpec change (tick its `tasks.md` as items land, and do not re-derive what it settled); a tracker issue handed over for implementation (`principle-read-the-whole-ticket`); an approved plan; a plain request whose scope the user stated. A triage brief, research ledger or handoff without a settled contract is `iteration`'s input.

Then run to the terminal state without further interaction, following `principle-stop-at-the-rabbit-hole` and `principle-delegate-down-a-tier`.

1. **Understand.** Read Purpose, End state and Key tasks from the OpenSpec change or the branch note by path. Investigate what exists, the real requirement and the smallest sufficient change. Rank the assumptions it depends on and resolve what you can (`principle-evidence-over-assertion`); if evidence refutes the premise, escalate.
2. **Clarify once**, only as `principle-decide-then-declare` allows, plus the branch name when the `worktree` block needs one. If the request changes an open PR, route to `feedback`. Batch every question into one stop.
3. **Worktree.** Continue in the iteration's worktree, or create one with the `worktree` block. Write or update the note and task list (`principle-state-outlives-the-session`), carrying the ledger forward.
4. **Implement** the agreed scope and harden what the ledger marks prototype-quality. Write the tests the ledger or acceptance criteria call for (`principle-test-agreed-decisions`).
5. **Verify** with `verification`, to the local rungs green (`principle-prove-it-works`).
6. **Audit** the final diff against every requirement and `git status --short`: only intended files and changes.
7. **Review** with `agent-review`, once, over the whole accumulated diff. Fix, reject with a reason, or escalate each finding, in the working tree.
8. **Publish** with `open-pr`, handing it the Manual verification surfaces, Assumptions, Refuted evidence and Rejected review findings. It drives the checks green and removes `WIP:`.

Stop early only when the contract proves invalid against repository evidence, a load-bearing decision is genuinely unresolvable, or pre-existing changes cannot be separated. Otherwise pick the minimal option and record it in the PR.

**Terminal state is every resolved check green, not "PR opened."** Report the PR URL, each rung's final state, and the worktree per the `worktree` block's report rule. If a rung cannot go green, escalate with what each attempt disproved. Save the note and task list with the PR, checks and next action; awaiting review is not merged.
