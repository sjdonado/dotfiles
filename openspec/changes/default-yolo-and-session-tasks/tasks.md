## 0. Decide the acceptance budget first

- [x] 0.1 Put the bench question to the human before writing any instruction text: this change needs `bench/measure verify --behavior`, which is paid sessions capped at 26 per retained batch, and `improve-harness-effectiveness` still has tasks 3.5, 3.6 and 4.4 open against the same budget. Options are one combined batch covering both, a batch for this change alone, or shipping unvalidated and saying so in the PR. Do not spend sessions without an answer.

## 1. Default the route to yolo

- [x] 1.1 In `agents/AGENTS.md`, add the default to the routing section: an implementation request that names no workflow is `yolo`, including one arriving as a handoff or an approved plan. State that the agent's own judgement that requirements are uncertain is not a reason to pick `proto`.
- [x] 1.2 In the same section, make `proto` explicitly opt-in: it runs on the human's words (prototype, spike, rough, try it first), not on the agent's initiative.
- [x] 1.3 Reword `agents/skills/proto/SKILL.md` so nothing in it invites the agent to select it. Its content stays; only the invitation goes.
- [x] 1.4 Keep the OpenSpec offer explicit: for work worth documenting, the agent names the written-spec route in one line and proceeds on the answer rather than blocking.

## 2. Add the session task ledger

- [x] 2.1 Extend the continuity section of `agents/AGENTS.md` with `.agent/<branch-key>.tasks.md`: same directory and branch-key encoding as the note, OpenSpec's task shape, created when work has more than one step and no OpenSpec change covers it, written at the same checkpoints as the note.
- [x] 2.2 State the single-owner rule: with an OpenSpec change present its `tasks.md` is authoritative and no ledger exists; adopting a change mid-session folds the ledger in, deletes it, and says so.
- [x] 2.3 Add one line to the branch note's required content pointing at the ledger, so a reader of the note finds it.
- [x] 2.4 Update `agents/skills/yolo/SKILL.md` and `agents/skills/proto/SKILL.md` to tick the ledger where they already tick an OpenSpec `tasks.md`.
- [x] 2.5 Update `agents/skills/handoff/SKILL.md` to reference the ledger by path rather than restating the task list.
- [x] 2.6 Update `agents/skills/land/SKILL.md` to delete the ledger when the work merges, beside the archive step.
- [x] 2.7 Make the ledger reachable by a subagent: state that a subagent prompt passes its path rather than restating session state.

## 3. Add model-tier delegation

- [x] 3.1 Add the orchestrator role to `agents/AGENTS.md`: the tier holding the contract decides and delegates; mechanical execution against a settled contract belongs at a cheaper tier. No model names, no effort levels, no spawn thresholds.
- [x] 3.2 Specify the two offer points (before implementation, before verification) as a line of work rather than a blocking question, naming what would be handed over.
- [x] 3.3 Specify the autonomous behavior: `yolo` never stops for the offer, follows a recorded project preference, and continues undelegated when none exists.
- [x] 3.4 Specify that an answer is recorded as the project's preference so the question is asked once.
- [x] 3.5 State that the subagents a workflow already spawns, including `adversarial-review`'s reviewers, count toward the run's cost when deciding what else to delegate.

## 3b. Name the verification subagent

- [x] 3b.1 Add `agents/skills/verification/SKILL.md`: the counterpart to `adversarial-review`, running the ladder, repairing in scope, and reporting a verdict, with the never-redesign, never-push and unverified-not-passing constraints.
- [x] 3b.2 Point `yolo`'s ladder step at it, so the checks half is attributable whether or not it is delegated.
- [x] 3b.3 State in `AGENTS.md` that the two delegatable stretches are named, that `verification` is the usual cheap-tier candidate, and that a weak reviewer is not a saving.
- [x] 3b.4 State that waiting is never delegated, from this change's own bench run.

## 4. Validate

- [ ] 4.1 Run the local checks: `bench/measure verify --local`, and `openspec validate default-yolo-and-session-tasks --strict`.
- [x] 4.2 Write the bench scenarios this change needs, per `bench/README.md`: a request with an open shape taking the cheap route, and a fully specified ticket taking the expensive one. Declare expected artifacts and assertions before running anything.
- [ ] 4.5 Fix the `route-open-shape` oracle: its behavior assertion demands case preservation the prompt never states, so a defensible reading (`casefold`) fails it. Assert only what the prompt actually fixes, or state the requirement.
- [ ] 4.6 Investigate the `land-open` regression: it passed on luna before this change and fails on both models after. Reword `land` so its deletion step reads as conditional on a verified merge, then re-run that case.
- [ ] 4.3 Run the authorized batch from task 0.1, review transcripts, and write the `review.json` per passing run. Record an unavailable or unauthorized check as unverified, never as passing.
- [ ] 4.4 Report what the scenarios actually showed, including any instruction an agent did not follow. A passing local check is not acceptance.

## 5. Ship

- [ ] 5.1 Through `yolo`: branch, implement tasks 1 through 3, run the adversarial review on the accumulated diff, and open one PR. Never merge.
- [ ] 5.2 State in the PR body what is validated and what is not, and which decisions were made without asking.
