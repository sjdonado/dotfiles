# Global agent conventions

These are contracts, shapes, and protocols. They must stay project-agnostic. Concrete commands, paths, and available data sources belong in a project's own `AGENTS.md`. Where a project declares nothing, infer it and record what you inferred, so a wrong guess is visible and correctable rather than silent.

## Command routing from plain language

The workflows in `commands/` are reachable only as `/name`. Skills are auto-invoked by description matching; commands are not. So a request phrased naturally would otherwise get an ad-hoc answer instead of the workflow designed for it, skipping that workflow's evidence gathering and confirmation gates. Route by intent:

| Plain language | Follow |
| --- | --- |
| "create a ticket for this", "file this", "make an issue" | `/create-ticket` |
| "look into X", "is it true that", "dig into whether" | `/research` |
| "what does X do", "why does Y happen", one bounded question | `/ask` |
| "how should we approach this", a pasted ticket, "triage this" | `/triage` |
| "implement this", "go build it", an approved plan | `/yolo` |
| a bullet list of changes to work already in a PR | `/feedback` |
| "address the review comments", "CI is red on my PR" | `/address-review` |
| "poke holes in this", "challenge this design" | `grill-me` |
| "think this through", "let's explore", an idea with no shape yet | `openspec-explore` |
| "spec this out", "write it up", a feature worth documenting | `openspec-propose` or `openspec-new-change` |
| "does the code match the spec" | `openspec-verify-change` |

Announce the routing in one line, so a wrong guess is cheap to correct.

Routing carries the workflow's constraints, not just its steps. Plain-language entry never downgrades a gate: ticket creation still confirms before writing to the tracker, `/yolo` still never merges, read-only workflows still make no edits.

Do not route when the request is conversational or a one-line lookup where the workflow costs more than the answer, or when two workflows match and the choice changes the outcome. In that case name both and ask.

Never route into *producing* a code or pull-request review. Review requires explicit human invocation and is never entered by routing or from another workflow. Addressing an existing review is different and is routable: that is `/address-review`.

Implementation always goes through `/yolo`, never `openspec-apply-change`. The OpenSpec skills own the input phase and the post-implementation phase (verify, sync, archive); `/yolo` owns writing the code, because only it carries the oracle ladder, adversarial review, and the escalation contract. When an OpenSpec change directory exists, `/yolo` implements from its artifacts and ticks off `tasks.md` as it goes.

When a request matches a workflow but omits something the workflow needs, follow the workflow and let its own steps handle the gap. Do not fall back to an ad-hoc answer.

## Planning

Every change needs an agreed contract before implementation. There are two ways to reach one, and exactly one of them is required.

**A written spec, for work worth documenting.** Use the `openspec-*` skills: explore to think it through, then propose or new-change to produce the artifacts, then update-change to fold in what grilling or evidence changes. The change directory under `openspec/changes/<id>/` is the contract, it is durable, and it is reviewable by a teammate. Prefer this for a large feature, anything touching several surfaces, or anything whose reasoning is worth keeping after the PR merges.

**Native plan mode, for everything else.** Cheaper, in-conversation, nothing to archive. Trace the relevant system end to end, identify the source of truth and lifecycle implications, clarify only load-bearing ambiguity, and recommend the smallest coherent change with specific files and verification steps.

Do not do both. An approved OpenSpec change is already the implementation contract, so re-entering plan mode to restate it adds a second approval gate over the same decisions. Go straight from the approved change to `/yolo`.

Whichever route, pressure-test before committing to it: run `grill-me`, interactively when you want to drive it, or in self-grill mode so the agent resolves what evidence and a repository search can settle and brings back only the questions that survive.

When a plan brief from `/triage`, a finding ledger from `/research`, or an OpenSpec change directory is present, treat it as the contract's input, not as a suggestion to re-derive. Do not re-investigate what it already grounded with a `path:line` or a linked number. Carry its verification concerns forward verbatim, and carry its open questions in as decisions with defaults. Re-run only evidence marked refuted or unchecked, or that predates the most recent deploy.

## Approval means autonomous execution

Approving a contract is the go-ahead to run to completion. This applies to every surface that can produce one: native plan mode, `ExitPlanMode`, an OpenSpec change proposal, or any skill or command used to reach agreement.

On approval, follow the `yolo` workflow without being asked. Treat the plan's final recommendation as the implementation contract, work fully autonomously, and do not stop until that workflow's terminal state is reached: a PR open with every resolved oracle green. Do not ask for confirmation to begin, between steps, before committing, or before pushing. Do not re-present the plan, summarize it back, or ask which part to start with.

Stop early only when implementation reveals that the plan is invalid against repository evidence, a load-bearing decision is genuinely unresolvable, or pre-existing unrelated changes cannot be safely separated. Otherwise pick the most reasonable minimal option, record it in the PR body, and continue.

Never merge the PR. Leave it open for human review.

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

Flaky or timed-out CI (re-run once; only a second failure counts as an attempt). Lint or format failures (auto-fix them). A branch behind its base (rebase and continue). Type errors in code you just wrote (that is the loop working). Dependency install, cache, or port collisions (re-run the project's provisioning). "I am not sure this design is optimal" (pick the minimal option, record it, continue).

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

Resolving review threads is deliberately **not** a rung. Threads only exist after a human reviews, which is after an autonomous run has finished, so `/address-review` owns them.

## Production evidence

A claim about runtime behavior, impact, frequency, or performance is load-bearing only if being wrong about it changes the decision. Check load-bearing runtime claims against production telemetry via the `evidence` skill, or mark them explicitly unchecked. Never state a number without its source deep link and timeframe. Where a telemetry capability is not configured for a project, say so and move on; absence of data is never a reason to block or to invent one.

## Code reviews

Agent-initiated review is adversarial and uses the `adversarial-review` skill as its protocol, rendering findings in `caveman-review`'s one-line format. `caveman-review` is a comment format, not a review procedure. Agent-initiated review never posts to the forge: findings are resolved in the working tree before pushing, and rejected findings are recorded in the PR body.

Human-requested review uses the harness's native review command. Never invoke it from another workflow or loop, and never ask for consent on its behalf.

## Commit messages

When writing any git commit message, follow the `caveman-commit` skill: Conventional Commits format, terse and exact, imperative subject <=50 chars, body only when the "why" is non-obvious. No AI attribution, no filler, no emoji.

## Writing

Never use em-dashes (—) in any prose, commit message, PR text, code comment, or other written output. Rewrite the sentence, or use a comma, colon, parentheses, or a period instead.

## Links

When rendering a link, always show the complete absolute URL as the visible text, including the scheme and host (for example, `https://example.com/path`). Never hide a URL behind Markdown alias text such as `[test](https://example.com/path)`. Never render relative URLs or bare paths as links.

## Naming MCP tools

These instructions load in more than one harness, and each prefixes MCP tool names differently. Always name a tool as its server plus its bare tool name, for example "the Linear MCP's `save_issue`". Never write a harness-specific prefix.
