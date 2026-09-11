## 0. Decide the acceptance budget first

- [ ] 0.1 Put the bench question to the human before writing any instruction text: this change needs `bench/measure verify --behavior`, which is paid sessions capped at 26 per retained batch, and `improve-harness-effectiveness` still has tasks 3.5, 3.6 and 4.4 open against the same budget. Options are one combined batch covering both, a batch for this change alone, or shipping unvalidated and saying so in the PR. Do not spend sessions without an answer.

## 1. Default the route to yolo

- [ ] 1.1 In `agents/AGENTS.md`, add the default to the routing section: an implementation request that names no workflow is `yolo`, including one arriving as a handoff or an approved plan. State that the agent's own judgement that requirements are uncertain is not a reason to pick `proto`.
- [ ] 1.2 In the same section, make `proto` explicitly opt-in: it runs on the human's words (prototype, spike, rough, try it first), not on the agent's initiative.
- [ ] 1.3 Reword `agents/skills/proto/SKILL.md` so nothing in it invites the agent to select it. Its content stays; only the invitation goes.
- [ ] 1.4 Keep the OpenSpec offer explicit: for work worth documenting, the agent names the written-spec route in one line and proceeds on the answer rather than blocking.

## 2. Add the session task ledger

- [ ] 2.1 Extend the continuity section of `agents/AGENTS.md` with `.agent/<branch-key>.tasks.md`: same directory and branch-key encoding as the note, OpenSpec's task shape, created when work has more than one step and no OpenSpec change covers it, written at the same checkpoints as the note.
- [ ] 2.2 State the single-owner rule: with an OpenSpec change present its `tasks.md` is authoritative and no ledger exists; adopting a change mid-session folds the ledger in, deletes it, and says so.
- [ ] 2.3 Add one line to the branch note's required content pointing at the ledger, so a reader of the note finds it.
- [ ] 2.4 Update `agents/skills/yolo/SKILL.md` and `agents/skills/proto/SKILL.md` to tick the ledger where they already tick an OpenSpec `tasks.md`.
- [ ] 2.5 Update `agents/skills/handoff/SKILL.md` to reference the ledger by path rather than restating the task list.
- [ ] 2.6 Update `agents/skills/land/SKILL.md` to delete the ledger when the work merges, beside the archive step.
- [ ] 2.7 Make the ledger reachable by a subagent: state that a subagent prompt passes its path rather than restating session state.

## 3. Add model-tier delegation

- [ ] 3.1 Add the orchestrator role to `agents/AGENTS.md`: the tier holding the contract decides and delegates; mechanical execution against a settled contract belongs at a cheaper tier. No model names, no effort levels, no spawn thresholds.
- [ ] 3.2 Specify the two offer points (before implementation, before verification) as a line of work rather than a blocking question, naming what would be handed over.
- [ ] 3.3 Specify the autonomous behavior: `yolo` never stops for the offer, follows a recorded project preference, and continues undelegated when none exists.
- [ ] 3.4 Specify that an answer is recorded as the project's preference so the question is asked once.
- [ ] 3.5 State that the subagents a workflow already spawns, including `adversarial-review`'s reviewers, count toward the run's cost when deciding what else to delegate.

## 4. Validate

- [ ] 4.1 Run the local checks: `bench/measure verify --local`, and `openspec validate default-yolo-and-session-tasks --strict`.
- [ ] 4.2 Write the bench scenarios this change needs, per `bench/README.md`: entering yolo from a bare implementation request, entering yolo from a handoff with no written contract, `proto` only on an explicit ask, a ledger created and ticked then folded into an adopted OpenSpec change, and a delegation offer that does not stop an autonomous run. Declare expected artifacts and assertions before running anything.
- [ ] 4.3 Run the authorized batch from task 0.1, review transcripts, and write the `review.json` per passing run. Record an unavailable or unauthorized check as unverified, never as passing.
- [ ] 4.4 Report what the scenarios actually showed, including any instruction an agent did not follow. A passing local check is not acceptance.

## 5. Ship

- [ ] 5.1 Through `yolo`: branch, implement tasks 1 through 3, run the adversarial review on the accumulated diff, and open one PR. Never merge.
- [ ] 5.2 State in the PR body what is validated and what is not, and which decisions were made without asking.
