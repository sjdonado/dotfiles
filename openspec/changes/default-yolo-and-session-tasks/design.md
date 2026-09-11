## Context

See proposal.md for motivation. Four things in the current harness shape this design.

**The routing table says implementation goes through `yolo`, with no statement of when that is worth its cost.** `agents/AGENTS.md` maps "implement this" and "go build it" to `yolo` and `proto` to spikes, but never says which to pick when a request is simply work with an open shape. `yolo` is the expensive run: a full understanding pass, two blind reviewers, commits, a PR, and remote checks. Spending it before the contract holds still wastes all of that and leaves a PR describing something the human has already changed their mind about. `proto` costs a slice and the local rungs, and its ledger is what makes a later `yolo` run cheap and correct. So the missing instruction is the default, and it points at `proto`.

**Session state already has a home, and it is deliberately not a task list.** `AGENTS.md` mandates one ignored note at `.agent/<branch-key>.md` holding Contract, State, and Carry forward. It explicitly says specs and `tasks.md` stay authoritative and the note references rather than duplicates them, and it forbids an event log. So the note is prose about why and where, not a checklist of what. When no OpenSpec change exists there is no `tasks.md` for it to point at, and the State section absorbs a job it was designed not to do.

**Every harness surface reads the branch note; none of them read a to-do list.** `proto`, `yolo`, `address-review`, `feedback`, and `land` all read and write the note. A harness-native to-do list exists in each agent product, but it is per-session, per-product, and invisible to a subagent or to a different agent picking up the same branch. That is the gap the human is describing.

**Agent-instruction changes are gated on a paid behavioral batch.** `bench/README.md` and the project guide make `bench/measure verify --behavior` the acceptance for changes under `agents/`, capped per retained batch. `openspec/changes/improve-harness-effectiveness/` is unarchived at 17/20 with exactly that acceptance still open, so this change cannot claim validation without competing for the same budget.

## Goals / Non-Goals

**Goals:** the cheap route is the default and the expensive one is entered deliberately; task state survives a session boundary and is readable by a subagent without restating it; the expensive tier is spent on judgement rather than on typing; every instruction added stays general enough to survive a model or product change.

**Non-Goals:** replacing the branch note; replacing OpenSpec; adding an event log or any second tracking system; naming models, effort levels, or subagent thresholds; changing the adversarial-review protocol; changing what `yolo` verifies or its refusal to merge.

## Decisions

1. **State the default in the routing table, and give `yolo` explicit entry conditions.** `AGENTS.md` gains one rule: work whose contract is not settled is `proto`; `yolo` is entered when the human names it or asks for a PR, when an approved change, plan or promoted ledger fixes the contract, or when the work is bounded on its own (a specified ticket, a round on an open PR's branch, a small mechanical change). Uncertainty selects `proto`, never `yolo`. The skills state the same rule at their own entry points, so an agent that lands in one directly still reads it. Alternative rejected: leaving the choice to judgement, which is the current state and is how an expensive run gets spent on a moving target.

2. **The session task ledger is `.agent/<branch-key>.tasks.md`, a sibling of the branch note.** Same directory, same ignore rule, same branch-key encoding, so no new ignore entry and no new lifecycle. The note keeps Contract, State and Carry forward and gains one line pointing at the ledger; the ledger holds only the checklist, in OpenSpec's shape. The division is the one `AGENTS.md` already draws: the note says why and where, the ledger says what and how far.

   Alternatives rejected: a section inside the note, which makes every tick a rewrite of a prose document and blurs the separation the note already enforces; a file in the OS temp directory, which does not survive a reboot, is not discoverable by a subagent from the repository, and cannot be found by a later session that knows only the branch; a file inside the repository worktree, which would have to be gitignored per project and would show up in diffs.

3. **The ledger exists only in the absence of an OpenSpec change, and exactly one of the two is authoritative.** With a change directory present, `tasks.md` there is the list and no ledger is created. Adopting a change mid-session folds the ledger into `tasks.md` and deletes it, telling the human it moved. `land` deletes it on merge, beside the archive step it already runs. This keeps the invariant that there is never more than one checklist for one line of work.

4. **Delegation is offered as a line of work, not as a gate.** Before implementation and before verification, the agent says what it would hand to a cheaper tier and proceeds; the human can take it or ignore it. Under `yolo` the offer is not made at all, because `yolo`'s contract is that it does not stop: it follows a recorded project preference, or does the work itself. The answer, once given, is recorded as a project memory so the question is asked once rather than every session.

   The guidance names the split by role, not by model: the tier that holds the contract and decides is the expensive one, and mechanical execution against a settled contract belongs below it. Naming models would rot on the next release and would remove the judgement the human explicitly wants left to the agent.

5. **Cost accounting includes the subagents a workflow already spawns.** `adversarial-review` dispatches up to two reviewers per round, at the orchestrator's tier unless told otherwise. Any guidance about delegation that ignores them understates a run's cost by the most expensive part of its tail. The instruction says to count them; it does not prescribe a tier for them, because a reviewer that is too weak to find the bug is not a saving.

6. **Acceptance is declared, not assumed.** The task list ends with the behavioral batch and states plainly that local checks alone do not validate an instruction change. Because the budget is shared with the unarchived `improve-harness-effectiveness`, the first task is a decision for the human: authorize a combined batch that closes both, or accept this change as unvalidated and say so in the PR. The agent does not spend paid sessions on its own initiative.

## Risks / Trade-offs

- Defaulting to `proto` means a request that was in fact well specified now costs an extra human round trip before anything ships. Mitigation: the entry conditions for `yolo` are written to cover exactly those cases (a specified ticket, a follow-up round, a small mechanical change, or simply asking for a PR), so the default only catches work whose shape is genuinely open.
- A default toward the cheap route can be read as licence to linger in iterations. Mitigation: `proto` is told to hand off the moment the ledger says what done is, and not to keep iterating where the human is no longer learning anything.
- A second file per branch is a second thing to keep current, and a stale ledger is worse than none. Mitigation: it is written at the checkpoints the note is already written at, never separately, and both are read together on continuation.
- Delegating implementation to a cheaper tier can cost more than it saves when the handover prompt has to carry the whole contract. Mitigation: the offer is the agent's judgement call and it is told to skip it when the task is too small to be worth the handover.
- Instructions that stay deliberately general can be read as optional. Mitigation: the specs state the behavior as scenarios, and the behavioral bench is what tells us whether an agent actually follows them.
- The bench budget is genuinely contended. Mitigation: the task list makes that the first decision rather than discovering it at the end.
