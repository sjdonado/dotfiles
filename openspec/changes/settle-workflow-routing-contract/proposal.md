## Why

Agents keep publishing on the user's behalf without an agreement that covers the act. Three observed cases: a request mixing a settled timer-sheet fix with an unresolved Live Activity experiment was routed whole into `yolo` on the strength of the settled subtask; an agent offered a `yolo` PR after green local checks without ever establishing that the session's purpose was settled; and an agent justified a fourth pull request from three earlier approved PRs, two unrelated blocked PRs, and default-branch hygiene. The current instructions invite this: `agents/AGENTS.md:100` turns any plan approval into a run that ends in an open PR, `agents/AGENTS.md:122` delegates external-write authority to "the owning workflow" without saying what grants it, and `agents/skills/feedback/SKILL.md:38` commits and pushes on every full round with no per-batch agreement. The proto-default routing rule already shipped (PR #9, `default-yolo-and-session-tasks`), so what is left unfixed is the authority question: what agreement makes a push, a pull request, or a message to someone else permitted.

## What Changes

- State the entry gate for `yolo` in terms of agreement, not artifact presence: a settled purpose, whole scope, acceptance evidence, and an identifiable source of user agreement. A formal planning document stays optional. A settled subtask cannot promote an unresolved experiment travelling with it. An agent-authored ledger, a passing check run, or a finished diff cannot supply the agreement by themselves.
- Name `yolo` as the single workflow exception to separate publication confirmation: an approved run already authorizes committing, pushing, and opening the PR for its agreed scope, and driving its required checks. Remove the earlier proposal that every run stop before its initial push; the user superseded it.
- Scope that exception to the branch and PR only. Issues, tracker comments, PR comments, and review replies stay outside it and need confirmation for the specific act.
- State what does not constitute authorization for an external write: an earlier approved PR, branch hygiene, a workflow's own rules, an unrelated open or blocked PR, or a note recording past approval. An existing specific authorization stays valid and is not re-asked.
- Make post-PR feedback behave like `proto`: local iterations accumulate on the same branch against the same PR, and publishing a batch needs approval for that batch. `feedback`'s automatic commit and push on a full round changes accordingly.
- Keep one line of work to one branch and one PR. A request for initial branch isolation does not by itself select `yolo`, and a separate line is the user's choice rather than a conclusion the agent converts into branch authority.
- Give commander's intent a home: the branch note's Contract opens with three fixed lines, Purpose, End state, Key tasks. Proto, yolo, handoff, `verification`, and Reviewer A read those lines by path instead of a paraphrase, and every human interaction that changes purpose or end state updates them first.
- Name the source of Reviewer A's requirements in priority order, verbatim: the change's specs and tasks, else the Contract block, else the ticket thread.
- Replace the delegation offer with a default: under `yolo`, `verification` runs in a subagent one tier below the orchestrator unless the project records otherwise; reviewers stay at the orchestrator's tier. Record this repository's preference in root `AGENTS.md`.
- Add an optional fork iteration to `proto`: when the End state is written and two or more approaches are plausible, one lower-tier subagent per approach in its own worktree, compared against the End state, presented as the iteration.
- Let the agent recommend `handoff`, and say when: at a checkpoint after purpose or end state changed twice, or after context compaction.
- Unblock `land`: open tasks that are paid behavioral acceptance do not block archive; they are recorded as unverified and the change archives. Merged notes move to `.agent/archive/`; no note is written for the default branch.
- Fold self-grill's evidence step into `openspec-propose` and yolo's understanding step, and drop the standalone grill-me prescription that no session invoked.
- Scope bench provenance per case to the instruction surfaces the case exercises, so an unrelated instruction edit does not stale every run.
- **BREAKING** for `feedback`: a full round no longer pushes on its own. Its checks still run locally; publication waits for approval of that batch.

## Capabilities

### New Capabilities

- `publication-authority`: what agreement authorizes a commit, a push, a pull request, or a message to anyone other than the user, which workflow holds that authority, and how it expires.
- `session-intent`: where purpose, end state, and key tasks are written, who reads them, and when they are refreshed.
- `delegation-default`: which stretches run in a subagent, at which relative tier, by default and without an offer.

### Modified Capabilities

None. `openspec/specs/` is empty: every change so far archives after merge, and the behavior this change governs lives in `agents/AGENTS.md` and the skills under `agents/skills/`.

## Impact

Edits `agents/AGENTS.md` (routing entry conditions, planning, continuity, approval, external communication, orchestration) and the `yolo`, `proto`, `feedback`, `address-review`, `adversarial-review`, `verification`, `handoff`, `land`, and `openspec-propose` skills under `agents/skills/`, plus root `AGENTS.md` for the recorded delegation preference and `bench/measure` for per-case provenance. The audit that motivated the additions is recorded in the branch note `.agent/docs%2Fhandoff-destination.md`, Carry forward. No installer, dependency, CI, or application configuration changes.

Behavioral acceptance governs whether this change can be called validated: these are agent instructions, so `bench/measure verify --behavior` applies per `bench/README.md`, and that is a paid batch the user must authorize. The earlier estimate of 14 sessions plus the existing matrix is stale, because the feedback and publication scope changed after it was written; the batch is recomputed in `design.md` and spent only on explicit authorization.

Two existing changes are context rather than substitutes. `default-yolo-and-session-tasks` merged as PR #9 and is unarchived, with its tasks 4.1, 4.3, 4.4, 4.8, 4.9, 5.1, and 5.2 still open. `improve-harness-effectiveness` is unarchived with its own behavioral acceptance open. Both compete for the same session budget.
