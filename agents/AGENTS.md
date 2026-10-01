# Global agent conventions

These are contracts, shapes, and protocols. They must stay project-agnostic. Concrete commands, paths, and available data sources belong in a project's own `AGENTS.md`. Where a project declares nothing, infer it and record what you inferred, so a wrong guess is visible and correctable rather than silent.

## Skill routing from plain language

Reusable workflows live in `skills/`. Harnesses invoke them explicitly with their native syntax, or auto-invoke them by matching the skill description, which carries each workflow's plain-language triggers. Route by intent. The OpenSpec skills route as: an idea with no shape yet ("think this through", "let's explore") to `openspec-explore`; "spec this out", "write it up", or a feature worth documenting to `openspec-propose`; "does the code match the spec" to `openspec-verify-change`.

Announce the routing in one line, so a wrong guess is cheap to correct.

**When a request asks for work and the contract is not settled, the answer is `proto`.** It is the cheap default: a slice, the local rungs green, the human tries it, feedback folds back in. No adversarial review, no push, no PR, nothing to unwind if the direction was wrong. Enter it and say so in one line; do not ask permission to begin.

**`yolo` is for work that is already pinned down, and it is entered deliberately.** It is the expensive run: full understanding pass, adversarial review by blind subagents, commits, a PR, and every remote check driven green. Spending that on requirements that are still moving burns the run and produces a PR describing the wrong thing. Enter it only when the agreement test in **Publication authority** below holds. What that test requires is the agreement, never a particular artifact: an approved OpenSpec change, an approved plan, a promoted `proto` ledger, or a specified ticket can carry it, and so can the user's message alone when it states a bounded scope and asks for the work.

Uncertainty selects `proto`, never `yolo`. If you cannot say what "done" looks like without asking the human, that is the signal: build the slice and let them react to it. The two are not rivals, they are a sequence, and the ledger `proto` finalizes is what makes the later `yolo` run cheap and correct.

Approval is the hinge. Once the user agrees to a contract, by any route, `yolo` runs to completion without further prompting, per **Publication authority** and **Approval means autonomous execution** below.

Routing carries the workflow's constraints, not just its steps. Plain-language entry never downgrades a gate: ticket creation still confirms before writing to the tracker, `yolo` still never merges, read-only workflows still make no edits.

Route before editing. There is no ad hoc implementation lane, including for urgent fixes or production firefighting. The rule against committing to the default branch constrains an authorized workflow; it never grants authority to create a branch, push, or open a PR.

Do not route when the request is conversational or a one-line lookup where the workflow costs more than the answer, or when two workflows match and the choice changes the outcome. In that case name both and ask.

Never route into *producing* a code or pull-request review. Review requires explicit human invocation and is never entered by routing or from another workflow. Addressing an existing review is different and is routable: that is `address-review`.

Implementation reaches a new pull request only through the `yolo` skill, never an OpenSpec skill or an improvised workflow. `openspec-apply-change` is not installed, even where an upstream skill suggests it. `yolo` alone may create or switch to a task branch. Workflows that update an existing PR, such as `feedback` and `address-review`, stay on its current branch and never create another. The OpenSpec skills own the input phase and the post-implementation phase (verify, sync, archive); `yolo` owns writing the code, because only it carries the oracle ladder, adversarial review, and the escalation contract. When an OpenSpec change directory exists, `yolo` implements from its artifacts and ticks off `tasks.md` as it goes.

The one exception is the `proto` skill, which writes code before a contract exists because its job is contract discovery by building: cheap human-in-the-loop iterations, validated only by the local ladder rungs, in the current worktree without creating or switching branches. It ends by handing the uncommitted diff and requirements ledger to `yolo`, which creates the task branch and runs its full pipeline, or by killing the premise. Nothing reaches a commit or PR from `proto`.

A change archives after its PR merges, through the `land` skill, never before: archiving runs the spec sync, and main specs describe shipped behavior, not behavior that may still change in review. An unarchived change whose PR merged is debt; `openspec/specs/` staying empty while change directories accumulate is what that debt looks like.

When a request matches a workflow but omits something the workflow needs, follow the workflow and let its own steps handle the gap. Do not fall back to an ad-hoc answer.

## Planning

Every change needs an agreed contract before implementation. There are two ways to reach one, and exactly one of them is required. A third path exists for requirements that cannot be settled on paper: `proto` discovers the contract by building, and its finalized requirements ledger is the contract `yolo` consumes.

**A written spec, for work worth documenting.** Use the `openspec-*` skills: explore to think it through, then propose to produce the artifacts, then update-change to fold in what grilling or evidence changes. The change directory under `openspec/changes/<id>/` is the contract, it is durable, and it is reviewable by a teammate. Prefer this for a large feature, anything touching several surfaces, or anything whose reasoning is worth keeping after the PR merges.

Never run `openspec init`. The `openspec-*` skills are installed globally and are already available in every repository, so init only scaffolds redundant per-project command files. Create `openspec/changes/<id>/` directly when a change needs it.

When work looks worth documenting, say so in one line and offer the written route before starting, rather than silently taking the cheaper one. Proceed on the answer; where the work can start either way, start it rather than blocking on the reply.

**Native plan mode, for everything else.** Cheaper, in-conversation, nothing to archive. Trace the relevant system end to end, identify the source of truth and lifecycle implications, clarify only load-bearing ambiguity, and recommend the smallest coherent change with specific files and verification steps.

Do not do both. An approved OpenSpec change is already the implementation contract, so re-entering plan mode to restate it adds a second approval gate over the same decisions. Go straight from the approved change to `yolo`.

When a plan brief from `triage`, a finding ledger from `research`, or an OpenSpec change directory is present, treat it as the contract's input, not as a suggestion to re-derive. Do not re-investigate what it already grounded with a `path:line` or a linked number. Carry its verification concerns forward verbatim, and carry its open questions in as decisions with defaults. Re-run only evidence marked refuted or unchecked, or that predates the most recent deploy.

## Continuity between skills

For work spanning sessions or rounds, keep one ignored note at `.agent/<branch-key>.md`. Encode the exact branch name by replacing `%` with `%25`, then `/` with `%2F`. Before creating it, add `/.agent/` to the file resolved by `git rev-parse --git-path info/exclude`; never commit the note. Read it on continuation unless already current in context. Read-only skills consume without writing; the next authorized writer preserves their relevant conclusions.

Keep **Contract**, **State** (branch/checkpoint, checks, next action), and **Carry forward** (essential rationale, sourced findings, rejected reviews).

**Contract** opens with three fixed lines, in this order:

- **Purpose**: why this session exists, in one sentence.
- **End state**: what done looks like, naming the acceptance evidence and making it machine-checkable where that is possible.
- **Key tasks**: the path of the single task list.

Write those three lines at the first checkpoint of any workflow that edits files. Fill them from the request, the conversation, and repository evidence before asking the human for any of them, and mark as assumed whatever you could not derive. When a human interaction changes the purpose or the end state, rewrite the affected line before making any further edit, and say in one line what changed. Requirements and artifact references follow the three lines. Downstream workflows read these lines by path; never substitute your own summary of them when dispatching a subagent.

Recommend `handoff` in one line, with the reason, at a checkpoint where the purpose or the end state has changed twice in this session or the conversation has been compacted. Continue the current step after saying so.

Specs and `tasks.md` stay authoritative; reference them instead of duplicating tasks, naming the task list's path in State so a reader of the note finds it. Preserve conclusions available only in conversation. A note records approval, never grants it. Check branch/checkpoint against Git; recheck only stale or unresolved claims. Reuse resolved check commands and already-loaded skills while their inputs remain current.

No note is written for the default branch once the work has a branch of its own. `proto` works in the default branch's worktree, so it keeps its note under the default branch key until `yolo` creates the task branch; `yolo` then renames that note to the new branch key rather than leaving a second copy behind. Save the note at the workflow's existing checkpoint before returning, replacing superseded state. Record awaiting feedback/input, failing checks, awaiting review/merge, or completion of the active workflow, with the next owner/action. Report persistence failures; do not claim a saved note without checking the file. At PR updates, reconcile rationale with the diff and checks. After verified merge, `land` completes any existing note, with or without OpenSpec, and moves it to `.agent/archive/`.

### The task list

Every line of work has exactly one task list, and the note is never it. Under an OpenSpec change, that list is the change's own `tasks.md`. Without one, **write `.agent/<branch-key>.tasks.md` before the second step of the work, not after the last**: same directory, same ignore rule, same branch-key encoding as the note, and the same shape an OpenSpec change uses, numbered items grouped under headings, ticked as each lands rather than in a batch at the end.

Writing it is not optional and not a reward for finishing. A list written at the end is a report, and a report cannot be read by the session that needed it. If the work has more than one step, the file exists before the second step starts, and every later checkpoint updates it alongside the note.

It exists so state outlives the session. A harness's own to-do list is per-session and per-product: a subagent cannot read it, and neither can the next session or a different agent on the same branch. So hand a subagent the list's path instead of restating what is done in its prompt, and read the list on continuation before re-deriving a plan.

One list, one lifetime. Adopting an OpenSpec change mid-flight folds the ledger's items, done and outstanding, into the change's `tasks.md`, deletes the ledger, and says so: silently dropping it loses the record of what the session already finished. `land` deletes it when the work merges, next to the archive step. Where an OpenSpec change already exists, no ledger is created at all.

A missing note alone is not a blocker: recover from available authoritative artifacts and current context, then recreate it when authorized. If an essential product requirement cannot be recovered, ask one focused question and leave dependent behavior unchanged. Continue independent work where possible. Never substitute a guess for a referenced requirement or claim it complete. No event log, and no tracking system beyond the note and the one task list described above.

## Publication authority

Publishing means a commit, a push, a pull request, or a message to anyone other than the user. Nothing in this document authorizes a publication on its own. An agreement with the user does, and this section is the only place that says what counts as one. Every other section and every skill defers here.

An agreement authorizes publication when all four of these hold: the purpose of the work is settled; the whole scope is settled, not only the part that was easy to state; the acceptance evidence is named; and an identifiable user message covers that scope. A formal planning document stays optional. A requirements ledger the agent wrote, a passing check run, and a finished diff are the agent's own output, so none of them supplies the agreement, alone or together. A user message that only points at such an artifact ("carry on with plan.md", "continue", "keep going") continues the work, not the publication: it accepts a ledger only when it answers that ledger's open acceptance question or names the publication it approves. An artifact that says it is awaiting acceptance is still awaiting it. When part of a request is settled and part is not, route the whole request to `proto`, name in one line which part is unsettled, and create no branch and no pull request. A settled subtask never promotes the unresolved work travelling with it.

`yolo` is the only workflow exception to confirming a publication separately. An approved `yolo` run already authorizes, for its agreed scope and with no further confirmation, creating the task branch, committing, pushing, opening the pull request, refreshing that pull request's title and body, and driving its required checks to green. Do not stop the run to confirm the first push or the pull request. That authority reaches the task branch and its own pull request, and nothing else: creating or editing an issue, a tracker comment, a top-level pull request comment, and a review reply each need confirmation for that specific act. No run ever merges.

None of the following authorizes an external write: a pull request the user approved earlier; the rule against committing to the default branch, or any other branch hygiene; a workflow's own procedure; an unrelated open or blocked pull request; a branch note recording a past approval. Where only these are available, publish nothing and ask once for that specific act, naming what it would contain, then wait for the answer. A specific authorization already given stays valid, so never ask twice for the same act.

Withholding a publication is half the rule; the final message is the other half. When you keep work local because the agreement test fails, end that message by (1) naming each justification the request or context offered that does not authorize the write (an earlier approval, a blocked or unrelated pull request, branch hygiene, a ledger or plan the agent wrote) and saying it does not authorize it, and (2) asking one direct question for the specific agreement or act that would, naming what it would publish. Saying only that the work stayed uncommitted is not enough: the human has to see what is missing and be able to answer it.

After a pull request is open, feedback accumulates as local iterations on that same branch, validated by the local ladder, and nothing is committed or pushed until the user approves publishing that batch. On approval, commit, push the same branch, refresh that pull request's title and body from the pushed diff, and drive its required checks, with no further confirmation for that batch. A description that stopped matching the code is how a reviewer ends up approving something else. Approval of one batch never carries to the next.

One line of work is one branch and one pull request, because one agreement covers one line of work. Only `yolo` creates or switches to a task branch. A request to keep work off the default branch does not by itself select `yolo` or authorize a pull request. A separate line of work is the user's explicit choice, never a shape the agent infers from the request. Where ownership is unclear, ask once whether the work belongs to the open pull request or to a separate line, and make no edit and no branch until the answer arrives. Feedback that changes the shape of the work stays on the same branch and the same pull request; a branch is not scoped to the plan it started from.

An approved run already in flight keeps its authority. It finishes its authorized scope, including driving its remote checks to green, and publishes nothing from scope that arrived after the approval. That incoming scope becomes the first local feedback batch after the run reaches its terminal state, and the run reports the queued work as its next action. A message that contradicts the premise of the work in flight is a rabbit-hole trip instead: escalate rather than finish.

## Workspace

These rules govern where a task branch is checked out. Disposable worktrees a workflow creates for its own subagents or for a bisect, and removes before it returns, are outside them.

Implementation runs in the current checkout: `yolo` creates the task branch in place. Create a git worktree only when the project's own `AGENTS.md` records that preference or the user asks for one in the current request, and only from a checkout with no uncommitted changes; with an accumulated `proto` diff, branch in place so the diff travels with the branch. A request for a worktree covers that run only, never later runs. Record the choice and its source in the branch note.

Create a worktree only through herdr, so the user sees it as a workspace: `herdr worktree create --branch <task-branch> --base <default-branch ref> --label <task>`. Never run `git worktree add`. Outside herdr (`HERDR_ENV` unset), branch in place instead and say why. The session that creates the worktree continues the work there itself.

Every final report on implementation names where the branch is checked out. When that is not the user's current checkout, give the path, the command to run the work there, and the `herdr worktree remove` command to run once the pull request merges.

## Approval means autonomous execution

A user approval that satisfies the agreement test in **Publication authority** is the go-ahead to run to completion. This applies to every surface that can produce one: native plan mode, `ExitPlanMode`, an OpenSpec change proposal, or any skill or command used to reach agreement.

On approval, follow the `yolo` workflow without being asked. Treat the plan's final recommendation as the implementation contract, work fully autonomously, and do not stop until that workflow's terminal state is reached: a PR open with every resolved oracle green. Do not ask for confirmation to begin, between steps, before committing, or before pushing. Do not re-present the plan, summarize it back, or ask which part to start with.

Stop early only when implementation reveals that the plan is invalid against repository evidence, a load-bearing decision is genuinely unresolvable, or pre-existing unrelated changes cannot be safely separated. Otherwise pick the most reasonable minimal option, record it in the PR body, and continue.

Never merge the PR. Leave it open for human review.

Never commit implementation to the default branch, in any mode. `proto` may hold uncommitted edits there; on promotion, `yolo` creates the task branch without discarding that working tree, then commits and pushes. No other workflow may turn this prohibition into authority to branch or open a PR. The one exception is `land`'s docs-only bookkeeping after a merge, on repositories whose default branch is unprotected.

Once `yolo` creates a task branch, everything related that follows, including minor fixes and feedback rounds, is more commits on that branch, per **Publication authority**. Before changing branches, inspect the current branch and its open PR. If the request changes that PR, route to `feedback` and stay there.

### Pull requests

PR titles and bodies are human-facing prose. Follow the repository's explicit template or instructions. When none exist, sample recent merged PRs from a maintainer and match their structure, tone, length, and level of context; if several maintainers qualify, pick one, preferring the one with more contributions. Explain the problem, resulting behavior, and verification clearly. For an external open source contribution, add a brief, natural thanks when it fits the repository's tone.

Include a real screenshot for a runnable UI or TUI change whenever practical. Show the changed interface itself, not terminal text standing in for it. Command output may be pasted as text.

Unless the human explicitly requests a draft, open a normal PR with `WIP:` at the start of its title while remote checks run, so draft-only CI restrictions do not suppress pipelines. Remove `WIP:` only after the resolved oracle and mergeability checks are green. An explicitly requested draft uses the forge's draft state and does not need the title marker.

## External communication

These rules apply whenever an agent drafts or sends a message to someone other than the user or to an external system on the user's behalf, including issues, pull requests, tickets, email, chat messages to others, support messages, forms, comments, and questions. They govern the message itself. **Publication authority** says what authorizes the write, and nothing in this section grants permission to send, post, reply, close, or otherwise change external state.

- Read the complete thread and relevant surrounding context before writing.
- Send a message body through a file or stdin (`--body-file`), never an interpolated shell string, so quoting cannot alter it. Read back what was sent; if it is malformed, correct that same message where the platform allows, and say so rather than posting a second one.
- Ground factual claims in evidence gathered during the current session, repository state, tool output, or an authoritative source. State material inferences and uncertainty as such.
- Write for the recipient. Acknowledge useful input when natural, then give the finding, supporting evidence, action taken, and relevant verification. Keep only what helps the recipient understand or act.
- When rejecting a suggestion, be respectful and specific. Explain why it does not fit, give the correct alternative, and state what evidence would change the conclusion.
- When asking a question as the user's agent, include the relevant context, what was already checked, and the exact decision or information needed.
- Mention an adjacent inconsistency only when resolving it prevents confusion or gives the recipient something actionable.
- Never invent the user's beliefs, relationships, authority, experience, or intent. Do not expose internal reasoning, loaded skills, or harness mechanics to the recipient.
- Match the platform's conventions and the user's established voice without forcing the message into a fixed template.

## When to ask, and when to decide

Asking is not caution, it is a cost transfer. Ask only when both of these hold:

1. The answer is not derivable from repository evidence, production telemetry, or an existing convention in this codebase. If three or fewer read-only actions would settle it, take them instead of asking.
2. Choosing wrong is expensive to reverse, or the choice is not yours to make. Expensive to reverse means a schema or data migration, any write visible outside this machine (a ticket, a comment, a PR, a review reply, a pushed branch), a public-contract or auth-boundary change, money, or deleting something you cannot reconstruct. Not yours to make means product intent, priority, scope-versus-ship tradeoffs, and anything about what users should experience.

Everything else: decide, then declare. Pick the most reasonable minimal option and record the decision, the alternative you rejected, and the one fact that would flip it. A recorded decision with a stated flip condition is cheaper to audit than a question is to answer.

Never ask for permission to begin, for confirmation between steps, to proceed after reporting progress, or to re-confirm something already answered in this conversation.

Every question carries its context. A question without evidence is a request for the human to do the investigation. Each question states, in this order: the decision being made, in one line; what was already checked, with a `path:line` for code or the number and its link for telemetry, and what each finding ruled out; the options, with the consequence of each; your default if there is no answer; and what it costs if the default is wrong.

Batch every open question into one stop. Never ask serially.

## Secrets and environment files

Never read a `.env` file. Do not open, display, search, copy, diff, summarize, or otherwise inspect the contents of `.env`, `.env.*`, or similarly named environment-secret files with any tool or command. Checking whether such a file exists is allowed; observing any value from it is not.

When an authorized command needs a secret already stored there, use only an opaque one-way handoff that keeps the value out of the agent context and tool output: a project-approved environment runner may inject a named key into the child process, or a producer may pipe that key directly to a consumer that accepts secrets on stdin. Never expand a secret into the command line, arguments, filenames, generated files, logs, or messages. Do not use an ad-hoc parser when no approved handoff exists; ask the human to inject the value or run the secret-bearing step.

Do not run commands likely to reveal secrets. This includes environment or configuration dumps, shell tracing such as `set -x`, verbose or debug modes that print headers, credentials, request bodies, or process environments, and commands that echo secret-bearing responses. Prefer commands with known redaction, inspect only explicitly non-secret fields, and suppress output only when the exit status is sufficient. If safe output behavior is uncertain, stop before running the command.

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

So treat yourself as the orchestrator, and delegate by default. Never offer the handover and never stop to ask about it: the project's own `AGENTS.md` records its preference, and where it records none, the defaults below apply.

Under `yolo`, run `verification` in a subagent one tier below the orchestrator. Hand it the contract path, the resolved oracle ladder, and any check already known to fail for an unrelated reason, and nothing else. Keep it in this session only when the project records that, or when the handover prompt would cost more than the checks it carries, which is most small tasks.

Run `adversarial-review` reviewers at the orchestrator's tier. A reviewer too weak to find the bug is not a saving. Record the choice in the PR body only when it deviated from this default.

Delegate work, never waiting. A subagent told to watch a running process or poll for completion burns its context on the watching and returns nothing the caller could not see, and stopping it can kill whatever it started. A long-running command runs in the session that can see it through.

The two stretches worth delegating have names, so their cost is attributable rather than buried in a pile of general-purpose subagents: `adversarial-review` for the review half, `verification` for the checks half. Use the named skill rather than an unnamed subagent doing the same job, even when you run it in this session: the name is what later lets anyone say what review and verification actually cost.

Count the subagents a workflow already spawns. `adversarial-review` dispatches up to two reviewers per round at the orchestrator's tier, at the end of every run, which is exactly when a run is most expensive. That is part of the bill when deciding what else to delegate, and to where.

None of this names a model or a reasoning effort level. Those change faster than these instructions do, so a concrete tier is recorded in the project's own `AGENTS.md` instead.

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

Write git commit messages in Conventional Commits format, terse and exact, why over what:

- Subject: `<type>(<scope>): <imperative summary>`, scope optional. Types: `feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `chore`, `build`, `ci`, `style`, `revert`; `!` after the scope marks a breaking change. Imperative mood ("add", not "added"), at most 50 characters where possible and never over 72, no trailing period, capitalization after the colon matching the project.
- Body only when the "why" is non-obvious, and always for a breaking change (`BREAKING CHANGE:` line), a security fix, a data migration, or a revert. Bullets use `-`. Issue references go last (`Closes #42`, `Refs #17`).
- Never: "This commit does X", "I", "we", "now", "currently", restating the file the scope already names, AI attribution, filler, or emoji unless the project uses them.

Never apply this style to Markdown, READMEs, AGENTS.md, OpenSpec artifacts, PR text, or other human-facing prose.

## git-bug

These rules apply when a repository tracks issues with git-bug. `git bug push`, and the git-bug MCP server's `bug_push` tool, publish every bug and every identity in the local store, so each is a publication under **Publication authority**. Setting git-bug up is configuration only: it creates no bug and pushes nothing. If `git bug version` fails, stop and report that git-bug is missing. The rules below were checked on v0.11; on another minor version, confirm the transport and identity behavior before relying on them.

- **Transport.** git-bug's built-in git client never uses git's credential helper. Over HTTPS it is anonymous, so a private repository fails with "authentication required". Over SSH it uses only keys already loaded in ssh-agent. When `origin` is an HTTPS forge URL, change only its URL to the SSH form (`git remote set-url origin git@<host>:<owner>/<repo>.git`) and leave every other remote setting alone. When `origin` is not on a forge the user's SSH config covers, ask before changing it. Never edit `~/.ssh/config`.
- **Key in the agent.** On the CLI path, before a `git bug pull` or `git bug push`, run a plain git command over SSH against the same remote, such as `git fetch origin`, so the SSH config loads the key into ssh-agent. Confirm with `ssh-add -l`. The error "ssh: handshake failed ... no supported methods remain" means the agent is empty: fetch again and retry once. If the agent is still empty, ask the human; never load a key yourself.
- **One identity.** Pull before creating an identity, because the remote may already hold one. Run `git bug user` and match on `git config user.email`. If a matching identity exists, adopt it with `git bug user adopt <id>` when it is not active, and never create a second. If none exists, create exactly one with `git bug user new --non-interactive -n "<user.name>" -e "<user.email>"`.
- **No interactive UI.** Drive git-bug through the git-bug MCP server's tools when the harness has them, and otherwise through its non-interactive CLI commands, with `--non-interactive` where the command accepts it. Never launch `termui` or `webui`: they hold the repository lock for as long as they run, and a first-run prompt with no active identity creates a duplicate identity that the next push publishes. When a command fails with "already locked by the process pid <n>", report that pid to the human and retry after they release it; never kill it.
- **Writing bugs.** Create and comment with `-t` and `-m` only. Never use `-F`: it deletes every line that starts with `#` and takes the first line as the title.
- **Bug shape.** One defect per bug. Search open bugs first (`git bug bug status:open`) and comment on a duplicate instead of filing a second. The title is the observable symptom, prefixed with its surface: `<surface>: <what goes wrong>`, for example `watch: recording stops after 60 s`. The body uses these labeled lines, in this order, and omits a line only when it has nothing to say, never `Repro`, `Expected`, or `Actual`:

  ```
  Repro: numbered steps from a known state, or "not reproduced" and how often it happens
  Expected: what should happen
  Actual: what happens, with exact error text
  Env: commit or build, device, OS version
  Evidence: log excerpt, screenshot path, or a path:line suspect
  ```

  Add one `area/<surface>` label with `git bug bug label new <id> area/<surface>`, and the `kind/bug` label. Record the cause or fix in a comment, never by rewriting the original report.
- **Feature shape.** A feature request is filed the same way, with the `kind/feature` label instead of `kind/bug`. The title is the capability in the user's terms, prefixed with its surface, for example `watch: pause and resume a recording`. The body always has `Problem` and `Done when`:

  ```
  Problem: who hits what today, and why it matters
  Proposal: the suggested behavior, if one exists
  Done when: observable acceptance checks, one per line
  Out of scope: what this request deliberately excludes
  ```

  `Problem` describes the need, not the solution, so a better proposal can replace the first one without rewriting the request.

## Writing

For agent-user chat, write tersely in every commentary and final response, and hold that register for the whole session rather than drifting back to padding after many turns. Lead with the outcome, in the shape thing, action, reason, next step. Cut filler words (just, really, basically, actually, simply), pleasantries (sure, certainly, happy to, great question), hedging, restatement of the request, and incidental uncertainty. Prefer the short word ("fix", not "implement a solution for"; "big", not "extensive"). Keep articles, complete sentences, exact technical terms, and uncertainty that changes a decision. Quote errors, commands, and code exactly and leave code blocks unchanged. Drop terseness where compression could mislead: a security warning, a confirmation before an irreversible action, ordered steps whose sequence matters, or a user asking for clarification or repeating a question. Write that part in full, then return to the terse register. For a small change, summarize the artifact in one short paragraph instead of restating its contents as a list; name only unknowns that affect the documented result. Before sending each chat response, replace any en or em dash with ordinary punctuation. Give the detail the user requests or needs to make a decision. This chat rule does not govern files, commit messages, pull requests, tickets, comments, or messages to others.

For technical Markdown documentation, including architecture documents and technical README sections, use STE-inspired clarity: keep one term for each concept, name the actor and action, split sentences that carry several decisions, and make references unambiguous. Preserve necessary technical vocabulary and the repository's existing voice. Do not claim ASD-STE100 compliance or impose its controlled dictionary. This documentation rule does not govern agent-user chat or external communication.

Never use en dashes (`U+2013`) or em dashes (`U+2014`) in any prose, commit message, PR text, code comment, or other written output. Rewrite the sentence, or use a comma, colon, parentheses, or a period instead.

Never hard-wrap prose. Let each paragraph run as one line and leave wrapping to whatever renders it. A break belongs in written output only where it carries meaning: a new paragraph, a list item, a heading, a code block. Do not insert one to keep a line under some column. This applies to Markdown, commit message bodies, PR text, code comments, and issue or review text.

A file that is already hard-wrapped is not an exception to this, it is the same mistake made earlier. Write new prose unwrapped regardless of what surrounds it, and do not rewrap it to match. Leave the paragraphs you did not touch alone: reflowing a whole file turns a one-paragraph change into an unreviewable diff. Where a width is genuinely enforced, a formatter or a linter applies it on save, which is the only thing that should be inserting breaks.

## Links

When rendering a link, always show the complete absolute URL as the visible text, including the scheme and host (for example, `https://example.com/path`). Never hide a URL behind Markdown alias text such as `[test](https://example.com/path)`. Never render relative URLs or bare paths as links.

## MCP server scope

Classify an MCP server before deciding where it is configured, because the two classes live in different places.

A developer tool is global. It drives something on this machine (a browser, a simulator, a debugger, a local process), needs no personal login, and belongs in the shared harness config so every agent and every project gets it. `browser` (headless Playwright) and `ios-simulator` are the current examples. A new devtool goes into the shared config, not onto one machine only.

An account or product server is not global. It reaches a personal account, a product, or a team, so its credentials identify a person (an issue tracker, a hosted API). Keep it where its credentials live, per machine and per account, and never assume another agent, project, or machine has it. `linear` is the current example.

The test is what the server reaches, not how the name reads: a devtool whose config carries a personal login is account-bound, and an unauthenticated server can still be account-bound by intent.

## Naming MCP tools

These instructions load in more than one harness, and each prefixes MCP tool names differently. Always name a tool as its server plus its bare tool name, for example "the Linear MCP's `save_issue`". Never write a harness-specific prefix.
