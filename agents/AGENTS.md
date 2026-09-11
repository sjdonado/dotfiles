# Global agent conventions

These are contracts, shapes, and protocols. They must stay project-agnostic. Concrete commands, paths, and available data sources belong in a project's own `AGENTS.md`. Where a project declares nothing, infer it and record what you inferred, so a wrong guess is visible and correctable rather than silent.

## Skill routing from plain language

Reusable workflows live in `skills/`. Harnesses can invoke them explicitly with their native syntax, and can auto-invoke them by matching the skill description. Route by intent:

| Plain language | Follow |
| --- | --- |
| "create a ticket for this", "file this", "make an issue" | `create-ticket` |
| "look into X", "is it true that", "dig into whether" | `research` |
| "what does X do", "why does Y happen", one bounded question | `ask` |
| "how should we approach this", a pasted ticket, "triage this" | `triage` |
| an approved plan or OpenSpec change, a promoted `proto` ledger, a specified ticket, "yolo it", "open a PR" | `yolo` |
| "implement this", "go build it", "prototype this", "spike it", "let me try it first", anything whose contract is still open | `proto` |
| a bullet list of changes to work already in a PR | `feedback` |
| "address the review comments", "CI is red on my PR" | `address-review` |
| "the PR merged", "archive the change", "clean up the spec" | `land` |
| "poke holes in this", "challenge this design" | `grill-me` |
| "think this through", "let's explore", an idea with no shape yet | `openspec-explore` |
| "spec this out", "write it up", a feature worth documenting | `openspec-propose` or `openspec-new-change` |
| "does the code match the spec" | `openspec-verify-change` |
| "set up project agent instructions", "audit AGENTS.md" | `harness-boostrap` |
| "how is the harness doing here", "audit the harness in this project" | `harness-audit` |
| "agents are on an old binary", "restart the agent panes" | `harness-restart` |

Announce the routing in one line, so a wrong guess is cheap to correct.

**When a request asks for work and the contract is not settled, the answer is `proto`.** It is the cheap default: a slice, the local rungs green, the human tries it, feedback folds back in. No adversarial review, no push, no PR, nothing to unwind if the direction was wrong. Enter it and say so in one line; do not ask permission to begin.

**`yolo` is for work that is already pinned down, and it is entered deliberately.** It is the expensive run: full understanding pass, adversarial review by blind subagents, commits, a PR, and every remote check driven green. Spending that on requirements that are still moving burns the run and produces a PR describing the wrong thing. Enter it when one of these holds:

- the human asks for it by name, or asks for a PR
- an approved OpenSpec change, an approved plan, or a promoted `proto` ledger already fixes the contract
- the work is well defined and bounded on its own: a specified ticket, a follow-up round on a branch whose PR is already open, a mechanical or small change where the shape is not in question

Uncertainty selects `proto`, never `yolo`. If you cannot say what "done" looks like without asking the human, that is the signal: build the slice and let them react to it. The two are not rivals, they are a sequence, and the ledger `proto` finalizes is what makes the later `yolo` run cheap and correct.

Approval is the hinge. Once a contract is agreed, by any route, `yolo` runs to completion without further prompting, per **Approval means autonomous execution** below.

Routing carries the workflow's constraints, not just its steps. Plain-language entry never downgrades a gate: ticket creation still confirms before writing to the tracker, `yolo` still never merges, read-only workflows still make no edits.

Do not route when the request is conversational or a one-line lookup where the workflow costs more than the answer, or when two workflows match and the choice changes the outcome. In that case name both and ask.

Never route into *producing* a code or pull-request review. Review requires explicit human invocation and is never entered by routing or from another workflow. Addressing an existing review is different and is routable: that is `address-review`.

Implementation reaches a pull request only through the `yolo` skill, never `openspec-apply-change`. The OpenSpec skills own the input phase and the post-implementation phase (verify, sync, archive); `yolo` owns writing the code, because only it carries the oracle ladder, adversarial review, and the escalation contract. When an OpenSpec change directory exists, `yolo` implements from its artifacts and ticks off `tasks.md` as it goes.

The one exception is the `proto` skill, which writes code before a contract exists because its job is contract discovery by building: cheap human-in-the-loop iterations, validated only by the local ladder rungs, on a task branch that never ships. It ends by handing a requirements ledger to `yolo`, which runs its full pipeline over the accumulated diff, or by killing the premise. Nothing reaches a PR except through `yolo`.

A change archives after its PR merges, through the `land` skill, never before: archiving runs the spec sync, and main specs describe shipped behavior, not behavior that may still change in review. An unarchived change whose PR merged is debt; `openspec/specs/` staying empty while change directories accumulate is what that debt looks like.

When a request matches a workflow but omits something the workflow needs, follow the workflow and let its own steps handle the gap. Do not fall back to an ad-hoc answer.

## Planning

Every change needs an agreed contract before implementation. There are two ways to reach one, and exactly one of them is required. A third path exists for requirements that cannot be settled on paper: `proto` discovers the contract by building, and its finalized requirements ledger is the contract `yolo` consumes.

**A written spec, for work worth documenting.** Use the `openspec-*` skills: explore to think it through, then propose or new-change to produce the artifacts, then update-change to fold in what grilling or evidence changes. The change directory under `openspec/changes/<id>/` is the contract, it is durable, and it is reviewable by a teammate. Prefer this for a large feature, anything touching several surfaces, or anything whose reasoning is worth keeping after the PR merges.

Never run `openspec init`. The `openspec-*` skills are installed globally and are already available in every repository, so init only scaffolds redundant per-project command files. Create `openspec/changes/<id>/` directly when a change needs it.

When work looks worth documenting, say so in one line and offer the written route before starting, rather than silently taking the cheaper one. Proceed on the answer; where the work can start either way, start it rather than blocking on the reply.

**Native plan mode, for everything else.** Cheaper, in-conversation, nothing to archive. Trace the relevant system end to end, identify the source of truth and lifecycle implications, clarify only load-bearing ambiguity, and recommend the smallest coherent change with specific files and verification steps.

Do not do both. An approved OpenSpec change is already the implementation contract, so re-entering plan mode to restate it adds a second approval gate over the same decisions. Go straight from the approved change to `yolo`.

Whichever route, pressure-test before committing to it: run `grill-me`, interactively when you want to drive it, or in self-grill mode so the agent resolves what evidence and a repository search can settle and brings back only the questions that survive.

When a plan brief from `triage`, a finding ledger from `research`, or an OpenSpec change directory is present, treat it as the contract's input, not as a suggestion to re-derive. Do not re-investigate what it already grounded with a `path:line` or a linked number. Carry its verification concerns forward verbatim, and carry its open questions in as decisions with defaults. Re-run only evidence marked refuted or unchecked, or that predates the most recent deploy.

## Continuity between skills

For work spanning sessions or rounds, keep one ignored note at `.agent/<branch-key>.md`. Encode the exact branch name by replacing `%` with `%25`, then `/` with `%2F`. Before creating it, add `/.agent/` to the file resolved by `git rev-parse --git-path info/exclude`; never commit the note. Read it on continuation unless already current in context. Read-only skills consume without writing; the next authorized writer preserves their relevant conclusions.

Keep **Contract** (requirements and artifact references), **State** (branch/checkpoint, checks, next action), and **Carry forward** (essential rationale, sourced findings, rejected reviews). Specs and `tasks.md` stay authoritative; reference them instead of duplicating tasks, naming the task list's path in State so a reader of the note finds it. Preserve conclusions available only in conversation. A note records approval, never grants it. Check branch/checkpoint against Git; recheck only stale or unresolved claims. Reuse resolved check commands and already-loaded skills while their inputs remain current.

Save the note at the workflow's existing checkpoint before returning, replacing superseded state. Record awaiting feedback/input, failing checks, awaiting review/merge, or completion of the active workflow, with the next owner/action. Report persistence failures; do not claim a saved handoff without checking the file. At PR updates, reconcile rationale with the diff and checks. After verified merge, `land` completes any existing note, with or without OpenSpec, and preserves it for explicit cleanup.

### The task list

Every line of work has exactly one task list, and the note is never it. Under an OpenSpec change, that list is the change's own `tasks.md`. Without one, **write `.agent/<branch-key>.tasks.md` before the second step of the work, not after the last**: same directory, same ignore rule, same branch-key encoding as the note, and the same shape an OpenSpec change uses, numbered items grouped under headings, ticked as each lands rather than in a batch at the end.

Writing it is not optional and not a reward for finishing. A list written at the end is a report, and a report cannot be read by the session that needed it. If the work has more than one step, the file exists before the second step starts, and every later checkpoint updates it alongside the note.

It exists so state outlives the session. A harness's own to-do list is per-session and per-product: a subagent cannot read it, and neither can the next session or a different agent on the same branch. So hand a subagent the list's path instead of restating what is done in its prompt, and read the list on continuation before re-deriving a plan.

One list, one lifetime. Adopting an OpenSpec change mid-flight folds the ledger's items, done and outstanding, into the change's `tasks.md`, deletes the ledger, and says so: silently dropping it loses the record of what the session already finished. `land` deletes it when the work merges, next to the archive step. Where an OpenSpec change already exists, no ledger is created at all.

A missing note alone is not a blocker: recover from available authoritative artifacts and current context, then recreate it when authorized. If an essential product requirement cannot be recovered, ask one focused question and leave dependent behavior unchanged. Continue independent work where possible. Never substitute a guess for a referenced requirement or claim it complete. No event log, and no tracking system beyond the note and the one task list described above.

## Approval means autonomous execution

Approving a contract is the go-ahead to run to completion. This applies to every surface that can produce one: native plan mode, `ExitPlanMode`, an OpenSpec change proposal, or any skill or command used to reach agreement.

On approval, follow the `yolo` workflow without being asked. Treat the plan's final recommendation as the implementation contract, work fully autonomously, and do not stop until that workflow's terminal state is reached: a PR open with every resolved oracle green. Do not ask for confirmation to begin, between steps, before committing, or before pushing. Do not re-present the plan, summarize it back, or ask which part to start with.

Stop early only when implementation reveals that the plan is invalid against repository evidence, a load-bearing decision is genuinely unresolvable, or pre-existing unrelated changes cannot be safely separated. Otherwise pick the most reasonable minimal option, record it in the PR body, and continue.

Never merge the PR. Leave it open for human review.

Never commit implementation to the default branch, in any mode. `yolo` already branches before editing; the same applies to interactive work: commits land on a task branch and reach the default branch through a PR. Work found sitting on the default branch moves to a branch before pushing, not after. The one exception is `land`'s docs-only bookkeeping after a merge, on repositories whose default branch is unprotected.

One line of work is one branch and one PR. Once a task branch exists, everything that follows in the session, feedback rounds included, is more commits on that branch. Do not open a second PR for the same work, and never branch away from an open PR without being asked: a second PR fragments the review, leaves the first describing a diff nobody will ship, and costs the human the thread they were reading. Splitting is a human decision, so propose it, name what would go where, and wait for an answer. This holds even when the feedback changes the shape of the work; a branch is not scoped to the plan it started from.

After pushing to a branch whose PR is already open, bring the PR's title and body back in line with the diff as it now stands. A description that stopped matching the code is how a reviewer ends up approving something else.

## When to ask, and when to decide

Asking is not caution, it is a cost transfer. Ask only when both of these hold:

1. The answer is not derivable from repository evidence, production telemetry, or an existing convention in this codebase. If three or fewer read-only actions would settle it, take them instead of asking.
2. Choosing wrong is expensive to reverse, or the choice is not yours to make. Expensive to reverse means a schema or data migration, any write visible outside this machine (a ticket, a comment, a PR, a review reply, a pushed branch), a public-contract or auth-boundary change, money, or deleting something you cannot reconstruct. Not yours to make means product intent, priority, scope-versus-ship tradeoffs, and anything about what users should experience.

Everything else: decide, then declare. Pick the most reasonable minimal option and record the decision, the alternative you rejected, and the one fact that would flip it. A recorded decision with a stated flip condition is cheaper to audit than a question is to answer.

Never ask for permission to begin, for confirmation between steps, to proceed after reporting progress, or to re-confirm something already answered in this conversation.

Every question carries its context. A question without evidence is a request for the human to do the investigation. Each question states, in this order: the decision being made, in one line; what was already checked, with a `path:line` for code or the number and its link for telemetry, and what each finding ruled out; the options, with the consequence of each; your default if there is no answer; and what it costs if the default is wrong.

Batch every open question into one stop. Never ask serially.

### Rabbit-hole detector

Stop and escalate the moment any of these trips, regardless of which step you are on:

- the same check has failed three times under three different fixes
- two consecutive attempts produced no new information (you changed something but learned nothing)
- the diff has grown past roughly three times the size the plan or request implied
- production evidence contradicts the premise of the work
- a second adversarial review round raises a new blocking finding
- the fix requires touching a surface outside the stated intent

On a trip, do not try a fourth thing. Report what was attempted, what each attempt disproved, the smallest next hypothesis, and what you need. A trip is information, not failure.

### Surfaces that escalate on first touch

These are irreversible or shared across every other concurrent stream, so touching one is an escalation regardless of how small the change looks, **unless the request or approved plan explicitly names that surface**. Changing CI config is the job when the task is to change CI config; it is an escalation when it is incidental to something else. A project's own `AGENTS.md` may map these classes to concrete paths; otherwise match them by convention for the detected toolchain.

- schema and data migrations
- CI/CD configuration
- dependency lockfiles
- shared or public contract surfaces (type libraries, public API definitions, protobuf or GraphQL schemas)
- infrastructure as code
- auth and secrets configuration

### Do not escalate for

Flaky or timed-out CI (re-run once; only a second failure counts as an attempt). Lint or format failures (auto-fix them). A branch behind or mechanically conflicting with its base (rebase, resolve, continue; only a semantic conflict, where both sides changed the same logic, escalates). Type errors in code you just wrote (that is the loop working). Dependency install, cache, or port collisions (re-run the project's provisioning). "I am not sure this design is optimal" (pick the minimal option, record it, continue).

## Orchestrating, and what to hand down a tier

The capable model earns its cost on understanding the problem, settling the contract, and judging what came back. Carrying out a settled contract and running the checks is mechanical, and paying the top tier to type is where a run's cost goes without buying anything.

So treat yourself as the orchestrator. Before implementation begins, and again before verification begins, offer in one line to hand that stretch to a subagent at a cheaper tier, naming what would go with it, and carry on: this is a line of work, not a gate, and it never becomes a reason to wait for permission. Skip the offer when handing over would cost more than doing it, which is most small tasks; the handover prompt has to carry the whole contract, and that is not free.

Delegate work, never waiting. A subagent told to watch something poll until it finishes burns its context on the watching and returns nothing the caller could not see, and stopping it can kill whatever it started. A long-running command belongs in the session that can see it through.

Record the human's answer where a later session will find it: the project's own `AGENTS.md` if it is the kind of preference that belongs in the repository, otherwise the durable memory the harness gives you. A preference nobody can find is asked again every session, which is the cost this avoids. Under an autonomous workflow the offer is never made: follow the recorded preference, and where none exists, do the work in this session. Stopping an autonomous run to ask about delegation breaks the one promise that workflow makes.

The two stretches worth delegating have names, so their cost is attributable rather than buried in a pile of general-purpose subagents: `adversarial-review` for the review half, `verification` for the checks half. Use the named skill rather than an unnamed subagent doing the same job, even when you run it in this session: the name is what later lets anyone say what review and verification actually cost.

`verification` is the usual candidate for a cheaper tier. It runs the ladder, fixes what the change broke, and reports a verdict, all against a contract that is already settled and an oracle that is machine-checkable, so success there is not a judgement call. `adversarial-review` is the opposite case: a reviewer too weak to find the bug is not a saving, so weigh its tier on what it has to catch.

Count the subagents a workflow already spawns. `adversarial-review` dispatches up to two reviewers per round at whatever tier they are given, at the end of every run, which is exactly when a run is most expensive. That is part of the bill when deciding what else to delegate, and to where.

None of this names a model, a reasoning or effort level, or a threshold at which a subagent becomes warranted. Those change faster than these instructions do, and the agent holding the task is better placed to judge it than a rule written in advance.

## Oracle ladder

"Done" must be machine-checkable, not a judgement call. The ladder's shape is global; each repository supplies the commands.

Shape, cheapest first, each green before ascending:

1. type or compile check
2. lint
3. tests
4. build
5. push, open PR, remote required checks green

Resolve the commands in this order: the project's own `AGENTS.md` if it declares them; else the repository's declared task runner, meaning a `justfile`, `Makefile`, or package-manifest target named `ci`, `check`, or similar, which is what a human would reach for; else infer them from the toolchain. Where a project offers a variant that narrows work to what changed, prefer it: grouping failures by package or crate is what lets a fix loop terminate on its own rather than re-running everything.

Re-derive the failure list on every pass; never work from a stale one. Record the resolved ladder in worktree state so later passes and any supervisor do not re-derive it, and so a wrong inference is visible rather than silent.

The ladder adapts to what exists. No remote CI means it ends at the local rungs plus an open PR. No tests means a shorter ladder. A missing rung is skipped, never faked.

Resolving review threads is deliberately **not** a rung. Threads only exist after a human reviews, which is after an autonomous run has finished, so `address-review` owns them.

## Reading a ticket

A ticket is its description plus its comments. Read the thread every time, in order, and treat what it says as part of the request: comments routinely add requirements, narrow scope, or overturn the description outright, and the newest word wins. Fold them into the plan as work items, and when a comment contradicts the description, say which you followed.

## Production evidence

A claim about runtime behavior, impact, frequency, or performance is load-bearing only if being wrong about it changes the decision. Check load-bearing runtime claims against production telemetry via the `evidence` skill, or mark them explicitly unchecked. Never state a number without its source deep link and timeframe. Where a telemetry capability is not configured for a project, say so and move on; absence of data is never a reason to block or to invent one.

## Validating harness changes

Validate harness changes with a disposable session scenario that exercises the changed behavior, following the project's benchmark instructions. Declare the expected artifacts and assertions before running, retain the prompts, exact harness and skill versions, model settings, transcripts, and results, and test continuation in a fresh session when continuity is involved. Judge task correctness and handoff behavior from artifacts and transcript evidence before comparing tokens or tool calls. Missing usage is unknown, never zero; a failed run is evidence, never silently discarded.

One successful scenario is a smoke test, not proof of efficiency. Compare repeated runs of the same scenario and model settings across harness versions before claiming savings, and inspect real sessions for failures the scenario misses. Do not validate a harness change by re-reading it and judging it plausible. Keep the scenario small and add coverage only for an observed gap.

## Code reviews

Agent-initiated review is adversarial and uses the `adversarial-review` skill, which carries both the protocol and the one-line finding format. It never posts to the forge: findings are resolved in the working tree before pushing, and rejected findings are recorded in the PR body.

Human-requested review uses the harness's native review command. Never invoke it from another workflow or loop, and never ask for consent on its behalf.

That command is for a diff this session did not write: someone else's pull request, a branch inherited from another agent, or code landing from outside. A diff produced here has already been through `adversarial-review` before it was pushed, by blind reviewers holding neither the plan nor the rationale, so running the native command over it again buys a weaker second opinion from a reviewer that does have all that context. Re-review the same diff only when a human asks for it explicitly, or when the diff has changed since the adversarial round.

## Commit messages

When writing any git commit message, follow the `caveman-commit` skill: Conventional Commits format, terse and exact, imperative subject <=50 chars, body only when the "why" is non-obvious. No AI attribution, no filler, no emoji.

## Writing

Never use em-dashes (—) in any prose, commit message, PR text, code comment, or other written output. Rewrite the sentence, or use a comma, colon, parentheses, or a period instead.

Never hard-wrap prose. Let each paragraph run as one line and leave wrapping to whatever renders it. A break belongs in written output only where it carries meaning: a new paragraph, a list item, a heading, a code block. Do not insert one to keep a line under some column. This applies to Markdown, commit message bodies, PR text, code comments, and issue or review text.

A file that is already hard-wrapped is not an exception to this, it is the same mistake made earlier. Write new prose unwrapped regardless of what surrounds it, and do not rewrap it to match. Leave the paragraphs you did not touch alone: reflowing a whole file turns a one-paragraph change into an unreviewable diff. Where a width is genuinely enforced, a formatter or a linter applies it on save, which is the only thing that should be inserting breaks.

## Links

When rendering a link, always show the complete absolute URL as the visible text, including the scheme and host (for example, `https://example.com/path`). Never hide a URL behind Markdown alias text such as `[test](https://example.com/path)`. Never render relative URLs or bare paths as links.

## Naming MCP tools

These instructions load in more than one harness, and each prefixes MCP tool names differently. Always name a tool as its server plus its bare tool name, for example "the Linear MCP's `save_issue`". Never write a harness-specific prefix.
