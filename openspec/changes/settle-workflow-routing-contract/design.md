## Context

See proposal.md, Why. The constraints that shape the approach:

The authority rules are spread across four surfaces that can each answer the same question differently. `agents/AGENTS.md:100` ("Approval means autonomous execution") converts any approved plan into a run ending in an open PR. `agents/AGENTS.md:108` already states one branch and one PR but derives it from branch hygiene rather than from agreement. `agents/AGENTS.md:122` scopes external communication to "after the owning workflow authorizes the external write" without saying what authorizes the workflow. `agents/skills/yolo/SKILL.md:9` states the entry conditions as a list of artifacts. `agents/skills/feedback/SKILL.md:38` pushes on every full round. Per the repository guide, a shared invariant belongs once in `agents/AGENTS.md` and procedure belongs in the owning skill, and conflicting text is replaced at its source rather than overridden by a later exception.

The routing default is already shipped and must not be re-specified: PR #9 (`default-yolo-and-session-tasks`) merged the proto-default and the session task ledger into `agents/AGENTS.md`, and remains unarchived.

Behavioral acceptance is paid and batch-scoped. `bench/README.md:15` hashes the contents of `agents/AGENTS.md` and the copied skills into each run's provenance, so editing them marks every existing run `stale` without refunding it. A validated harness version therefore needs a new batch, which is a new budget, capped at 32 sessions.

The prior round of this work also established that a behavioral oracle can fail to observe the thing under test: task 4.9 of `default-yolo-and-session-tasks` records that both routing cases passed identically whichever workflow ran, because `LOCAL_ONLY` forbade the commits and pull requests that distinguish the expensive route. Any case here that tests whether an agent publishes must let it publish.

## Goals / Non-Goals

**Goals:**

- One place answers "what authorizes this write", and every skill defers to it.
- The gate is stated as a property of the agreement, so an agent cannot satisfy it with an artifact it produced itself.
- Every new requirement is observable in a bench case by a Git or forge side effect, not only by transcript wording.

**Non-Goals:**

- No change to the proto-versus-yolo routing default, or to the session task ledger.
- No change to the oracle ladder's shape or to the review protocol itself; `adversarial-review` and `verification` change only in where their inputs come from and at which tier they run.
- No new gate on reads, local edits, or local check runs. This change adds confirmation only around writes that leave the machine.
- No merge authority anywhere.

## Decisions

**Publication authority lives in `agents/AGENTS.md`, in one section, and skills only point at it.** The alternative, stating it in each skill, is what produced the current contradiction between `yolo`'s autonomous push and `feedback`'s automatic push. The section absorbs and replaces the parts of "Approval means autonomous execution" and "External communication" that currently imply authority, rather than sitting beside them. `agents/AGENTS.md:138` already lists a pushed branch, a comment, and a review reply as expensive to reverse, so the new section is the mechanism that list has been missing.

**The gate is agreement-shaped, not document-shaped.** Requiring a planning document would be easy to check and wrong: the user explicitly keeps a formal document optional, and observed failure (2) had green checks and an agent-written contract, which a document requirement would not have caught either. So the gate names four properties (purpose, whole scope, acceptance evidence, source of user agreement) and one exclusion (nothing the agent authored counts as the source). Alternative rejected: a checklist the agent ticks, which is another artifact it authors itself.

**Yolo keeps uninterrupted publication for its agreed scope, scoped to branch and PR.** The user superseded the earlier proposal that every run stop before its initial push. Scoping the exception by surface (branch and PR yes, issue and comment and review reply no) is cheaper to apply than scoping it by intent, and it matches where the damage differs: a pushed branch on a PR the user asked for is expected, a comment on someone's issue is not.

**Feedback publishes per batch, and approval does not accumulate.** `feedback` becomes local-by-default: apply, run the local ladder, report, ask. The approved batch then publishes with no further confirmation, so the round does not degrade into step-by-step prompting. Alternative rejected: keeping the automatic push and asking only on the first round, which is exactly the "past approval covers this act" pattern the change exists to remove.

**A `yolo` run already in flight finishes its authorized scope; feedback arriving during it waits.** The branch note records this overlap as unreconciled. Deciding it here: the run's authorization covers the scope the user agreed to, including driving its remote checks to green, so an interrupting message does not revoke it, and the agent does not publish the new scope as part of that run. The new scope becomes the first local feedback batch after the run reaches its terminal state. This would flip if the incoming message contradicts the premise of the work in flight, in which case the rabbit-hole rule already applies and the run escalates instead of finishing.

**The bench batch is new, small, and computed from what this change can break.** Because the instruction edits stale the existing batch, validation runs in a fresh batch under a fresh authorization. Smallest useful set: five new cases covering the gate, precedent-as-authority, and the feedback batch, plus four existing cases whose surfaces this change touches (`route-bounded`, `route-open-shape`, the external communication case, and the unchanged `handoff-v1` on Luna as the fixed first trial). Two models at low reasoning, so 9 cases times 2 equals 18 sessions, inside the 32 cap. The earlier 14-plus-32 estimate is superseded. No session runs without the user authorizing that batch.

**New cases give the agent a remote and a forge substitute.** Per task 4.9's finding, a case that forbids publication cannot observe whether the agent would have published. Each new case asserts Git and forge side effects: commits present or absent, pushes present or absent, PR count, and comment calls, using `bench/fixture_gh.py`. A transcript assertion alone is insufficient evidence for any of these requirements.

**Intent lives in the note's Contract, as three fixed lines, not a new file.** The audit (branch note, Carry forward) found `purpose` and `end state` absent from every workflow skill; the fix is a place, not a procedure. The note already exists at every checkpoint and every skill already reads it, so three fixed lines cost nothing to route to. Alternative rejected: a separate intent file, which is one more artifact to keep in sync and one more thing a subagent prompt has to name.

**Delegation is a default, not an offer.** `agents/AGENTS.md:188-192` offers before implementation and verification, then tells the autonomous path never to make the offer, so no preference is ever recorded and every subagent in the audited sessions ran at the top tier (27 dispatches, 26 at `opus`, in sessions `089e5991` and `33e62643`). Replacing the offer with a default that a project record can override removes the dead loop. The user's answer is recorded in root `AGENTS.md`: mechanical stretches delegate to a subagent one tier down.

**Grill-me is folded, not kept.** Ten sessions, zero invocations. Its self-grill step 2 (resolve assumptions from repository evidence before asking) is the useful part and belongs inline where plans are made.

**`land` archives past open paid-acceptance tasks.** Two merged changes are unarchived because their only open tasks are the behavioral batch that finding 4 shows can never be green at merge time. Archiving records those tasks as unverified rather than pretending they passed.

**Bench provenance scopes per case.** `bench/README.md:15` hashes all of `agents/AGENTS.md` and every copied skill into each run. The fix hashes, per case, the skills that case routes through and the `agents/AGENTS.md` sections they reference, so a Writing-section edit stops staling routing evidence. If the section boundary proves unstable, the fallback is hashing whole skill files only, which is still narrower than today.

## Risks / Trade-offs

Per-case provenance can under-stale: an edit to a shared section a case does not list still changes behavior. Mitigation: the section list per case is declared in `bench/scenarios.py` next to the prompt, reviewed with the case, and `verify --behavior` prints which surfaces each case hashed.

A fixed three-line intent head can be filled with boilerplate. Mitigation: the End state line must name acceptance evidence, and Reviewer A receives it verbatim, so an empty End state produces a review that says so.

Asking per feedback batch adds a stop the user did not previously have on every round, and a chatty agent is its own cost. Mitigation: the ask is one line at the end of a round that already reports its check results, approval covers the whole batch without further prompting, and an approval already given for the current batch is never re-asked.

An agreement-shaped gate is softer than a document check, so a model can talk itself into believing the contract is settled. Mitigation: the exclusion is concrete and testable (agent-authored ledger, passing checks, finished diff), and two bench cases attack exactly that path.

Four surfaces change at once, and a partial edit leaves a worse contradiction than the current state. Mitigation: the task order puts the `agents/AGENTS.md` section first and the skill edits after it, each skill pointing at the section rather than restating it, and a stale-variant search closes the implementation.

The new batch costs a fresh 18 sessions and the previous batch's evidence is lost to staleness, while `default-yolo-and-session-tasks` and `improve-harness-effectiveness` both still have open behavioral tasks against the same budget. Mitigation: the batch is presented for authorization with its exact count before any session runs, and the competing debt is named in the proposal's Impact.

An in-flight run that finishes its authorized scope can land a PR the user has already moved past. Mitigation: the run reports its terminal state and the queued feedback as the next action, and nothing from the new scope is published in that run.
