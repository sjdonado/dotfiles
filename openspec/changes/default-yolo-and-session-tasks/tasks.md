## 0. Decide the acceptance budget first

- [x] 0.1 Put the bench question to the human before writing any instruction text: this change needs `bench/measure verify --behavior`, which is paid sessions capped per retained batch (26 at the time, 30 after this change adds two cases), and `improve-harness-effectiveness` still has tasks 3.5, 3.6 and 4.4 open against the same budget. Options are one combined batch covering both, a batch for this change alone, or shipping unvalidated and saying so in the PR. Do not spend sessions without an answer.

## 1. Default the route to proto, and enter yolo deliberately

Reversed on 2026-09-11 after the first pass had it backwards; the change id predates the reversal.

- [x] 1.1 In `agents/AGENTS.md`, state the default: work whose contract is not settled is `proto`, including a request arriving as a handoff. Uncertainty selects `proto`, never `yolo`.
- [x] 1.2 In the same section, give `yolo` explicit entry conditions: named by the human or a PR asked for, an approved change or plan or promoted ledger, a specified ticket, a round on a branch whose PR is open, or work small and mechanical enough that its shape is not in question.
- [x] 1.3 State the same rule at each skill's own entry point, so an agent landing directly in `proto` or `yolo` still reads it, and reconcile the surrounding prose that still said implementation always goes through `yolo`.
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
- [x] 4.5 Fix the `route-open-shape` oracle: its behavior assertion demands case preservation the prompt never states, so a defensible reading (`casefold`) fails it. Assert only what the prompt actually fixes, or state the requirement.
- [x] 4.6 Investigate the `land-open` regression: it passed on luna before this change and fails on both models after. Reword `land` so its deletion step reads as conditional on a verified merge, then re-run that case.
- [ ] 4.3 Run the authorized batch from task 0.1, review transcripts, and write the `review.json` per passing run. Record an unavailable or unauthorized check as unverified, never as passing.
- [x] 4.7 Resolved: the low task-list rate was the oracle, not the instruction. Every miss was on route-bounded, a single specified change that legitimately has no second step, and three models across two runners skipped the list there. The assertion is gone from that case; it stays on route-open-shape, where the work is genuinely iterative, and passed there for two of three models (gpt-6-astra and muse-spark-1.3; gpt-5.6-luna missed it).
- [ ] 4.9 The routing cases were rebuilt after adversarial review found they could not observe the route at all: both oracles passed identically whichever workflow ran, because `LOCAL_ONLY` forbade the commits and pull requests that define the expensive one. `route-bounded` now has a remote and the forge substitute and asserts commit, push and a PR attempt; `route-open-shape` asserts a sound slice, nothing committed, and no forge call. Validated offline against simulated cheap and expensive runs in both directions, but NOT yet exercised by a model batch: every routing result reported before this rebuild came from the weaker oracles.
- [ ] 4.8 Optional, unspent: re-run route-open-shape on gpt-5.6-luna to see whether the strengthened "before the second step" wording moves the one model that missed it.
- [ ] 4.4 Report what the scenarios actually showed, including any instruction an agent did not follow. A passing local check is not acceptance.

## 5. Ship

- [ ] 5.1 Through `yolo`: branch, implement tasks 1 through 3, run the adversarial review on the accumulated diff, and open one PR. Never merge.
- [ ] 5.2 State in the PR body what is validated and what is not, and which decisions were made without asking.
