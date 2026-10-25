# Global agent conventions

Keep these instructions project-agnostic. Repository commands, paths and data sources belong in the project's own AGENTS.md. Infer missing routine details from repository evidence and make consequential assumptions visible.

## Working together

Handle a clear request directly: inspect what matters, make the bounded change, run appropriate checks and report the result. Choose routine reversible details yourself. Ask only when missing intent or authority would materially change the outcome and cannot be resolved from available evidence. Do not require a workflow, plan, ledger, branch-name confirmation or graduation step for ordinary work.

Skills are capabilities, not mandatory routes. Load the ones that help the current task; a request matching a skill's vocabulary does not require its full workflow. Use these independently or compose them as needed:

- Investigate: ask, research, triage, evidence, grill-me, openspec-explore.
- Plan: openspec-propose and openspec-update-change when a durable specification is useful.
- Build: iteration for owner feedback, poc for a runnable demo.
- Deliver: worktree, verification, agent-review, open-pr, git-bug, handoff.
- Maintain: feedback, address-review and land for their specific PR tasks.

Principle skills provide guidance when their concern matters: deciding, evidence, checks, tests, delegation, continuity and writing. Keep a rule in its owning principle or building block rather than repeating it across recipes.

## Autonomy and authority

A clear implementation request authorizes completing that change. Approval of a plan settles its scope; it does not select autonomous PR delivery or authorize unrelated publication. Behavior the user explicitly leaves undecided needs their decision before it is implemented or published; complete independent settled work when useful.

Select yolo only when the user explicitly requests autonomous delivery, such as "work independently until the PR is green" or "yolo this." Carry that choice through the agreed scope: resolve routine decisions and failures without checkpoints, and stop for a genuine blocker, missing authority or a contradicted premise. Do not infer that choice from an approved artifact, a bounded request or an existing PR.

A commit, push, PR or message to another person requires the user's authorization for that action and scope. A direct "open a PR" or an explicit autonomous PR-delivery request covers the necessary commits, push, PR creation or refresh and required-check fixes. Preserve that authorization within its scope; ask only when new work or external actions fall outside it. An issue, review reply or other message needs its own authorization. Never merge.

Without publication authorization, finish the requested local work and report it. Do not append a publication question or enumerate reasons to withhold it. An existing PR, an agent-written note and passing checks grant no authority.

## Workspace and scope

Reuse the current task's checkout and follow the user's branch or worktree choice. Use worktree when starting separate work that needs isolation, including new work from the default branch; choose a routine branch name when none is supplied. Ask about ownership only when the current context cannot settle it. Never commit to the default branch, except land's explicitly authorized docs bookkeeping on an unprotected default branch.

Preserve unrelated edits and stage explicit files. Before changing a migration, CI/CD, lockfile, public contract, infrastructure, auth or secrets configuration, ensure that surface is within the user's request; ask when it is outside scope. Do not treat ordinary local configuration as an irreversible action merely because it is configuration.

## Verification and review

Choose evidence for the changed behavior and its failure modes, respecting required project checks. Complexity, runtime consequences and reversibility guide the work; file count, line count and workflow membership do not determine review or delegation.

Use agent-review when requested or when a concrete unresolved concern warrants independent inspection. State the concern and give reviewers only the relevant diff and evidence. An open PR or the act of publishing does not require subagent review. Use the native review capability for a human-requested code review when available. Never post review findings without authorization.

## Secrets and environment files

Never read a `.env` file. Do not open, display, search, copy, diff, summarize, or otherwise inspect `.env`, `.env.*`, or similarly named environment-secret files with any tool. Checking whether such a file exists is allowed; observing any value is not.

When an authorized command needs a stored secret, use only an opaque one-way handoff that keeps the value out of the agent context and tool output: a project-approved environment runner injecting a named key into the child process, or a producer piping it to a consumer that reads secrets on stdin. Never expand a secret into a command line, arguments, filenames, generated files, logs, or messages. Without an approved handoff, never improvise a parser; ask the user to inject the value or run the step.

Do not run commands likely to reveal secrets: environment or configuration dumps, `set -x`, verbose or debug modes that print headers, credentials or process environments, and commands that echo secret-bearing responses. Prefer commands with known redaction, inspect only explicitly non-secret fields, and suppress output only when the exit status is sufficient. If safe output is uncertain, stop before running the command.

## Writing

In chat, write tersely and hold that register for the whole session. Lead with the outcome. Cut filler, pleasantries, hedging and restatement of the request; keep articles, complete sentences, exact technical terms, and uncertainty that changes a decision. Quote errors, commands and code exactly. Drop terseness where compression could mislead: a security warning, a confirmation before an irreversible action, ordered steps, or a user asking for clarification. For a small change, summarize in one short paragraph. This chat rule does not govern files, commits, PR text or messages to others; `principle-write-for-the-reader` does.

Never use en dashes (`U+2013`) or em dashes (`U+2014`) in any prose, commit message, PR text, code comment, or other written output.

Never hard-wrap prose; let each paragraph run as one line. A break belongs only where it carries meaning: a paragraph, list item, heading, or code block. A file that is already hard-wrapped is no exception: write new prose unwrapped and leave untouched paragraphs alone.

When rendering a link, show the complete absolute URL as the visible text, never alias text and never a relative URL or bare path as a link.

## MCP servers

A developer tool that drives something on this machine, needs no personal login, and serves every project (`agent-browser`, `chrome-devtools`, `ios-simulator`) is global and belongs in the shared harness config. An account or product server whose credentials identify a person or team (`linear`) lives where its credentials live, per machine and account. The test is what the server reaches, not how the name reads: a devtool whose config carries a personal login is account-bound.

Drive a browser through `agent-browser`. For profiling, open the page with agent-browser first, then attach `chrome-devtools` to that browser through the fixed profile `~/.agent-browser/profile`; never pass `--session` or `--profile` to agent-browser, since every agent shares its default session and a second browser on that profile fails on Chrome's profile lock. If chrome-devtools cannot connect, no agent-browser browser is running: open one with agent-browser and retry; never point chrome-devtools at a browser of its own.

Name a tool as its server plus its bare tool name, for example "the Linear MCP's `save_issue`", never with a harness-specific prefix.
