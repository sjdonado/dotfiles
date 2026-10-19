# Design

## Context

See proposal.md, Why. Constraints that shape the approach:

- `agents/skills/` is one directory linked into every harness: `~/.claude/skills` and `~/.agents/skills` (Codex, OpenCode, pi) through `nix/home/common.nix`, and `agents/AGENTS.md` is linked as each harness's global policy. Anything placed there reaches every agent and every project.
- `openspec/specs/` is empty. Four harness changes are still unarchived (`settle-workflow-routing-contract`, `default-yolo-and-session-tasks`, `improve-harness-effectiveness`, `harness-scenario-tracking`) and carry requirements that name `proto`, branch-in-place and herdr.
- worktrunk 0.74 is declared for both platforms. `wt switch --create <branch> --base <ref> --no-cd --format json` creates a worktree without changing directory and prints the result as JSON; `--yes` approves prompts; `--no-hooks` skips hooks. The linked `worktrunk/config.toml` runs `wt step copy-ignored` before start, which today copies `.agent/` into every new worktree.
- The evals run real sessions against seeded repositories and assert skills read, commands run, branch and push state, files and PR fields. Seven scenarios exist; `happy-path`, `proto-gate` and `yolo-bounded` name `proto` or assume branch-in-place.

## Goals / Non-Goals

**Goals:**
- Every rule has one home, and workflows reach shared steps by composing skills.
- The expensive steps (tests, adversarial review, publication, remote checks) run once per task, at `yolo`.
- Worktrees are reproducible from one tool and one naming rule.

**Non-Goals:**
- Changing what publication authority allows. The agreement test, the per-batch approval after a PR is open and "never merge" keep their meaning; only their wording moves.
- Rewriting the upstream skills tracked in `skills-lock.json` (OpenSpec, handoff). They are referenced, not edited.
- New tracker integrations beyond reading a Linear issue's git branch name.

## Decisions

### 1. Three layers, decided by when a rule applies

A rule that must hold on every turn, whatever is running, stays in `agents/AGENTS.md`: publication authority (condensed), secrets and environment files, never merging, never committing to the default branch, the escalation stops, and the chat writing register (terse, no en or em dashes, full URLs). A rule that applies when a certain kind of step runs becomes a `principle-*` skill. A step that produces something becomes a building block. What remains in a workflow is its entry rule, its ordered steps and its exit states.

The initial principle set, mapped from today's sections of `agents/AGENTS.md`:

| principle | from |
| --- | --- |
| `principle-decide-then-declare` | When to ask, and when to decide |
| `principle-prove-it-works` | Oracle ladder |
| `principle-test-agreed-decisions` | Writing tests |
| `principle-evidence-over-assertion` | Production evidence; grounding in External communication |
| `principle-stop-at-the-rabbit-hole` | Rabbit-hole detector; do not escalate for (the surfaces that escalate on first touch stay in the policy as always-on stops) |
| `principle-delegate-down-a-tier` | Orchestrating, and what to hand down a tier |
| `principle-state-outlives-the-session` | Continuity between skills; the task list |
| `principle-write-for-the-reader` | Pull requests prose; External communication; Commit messages; technical Markdown |
| `principle-read-the-whole-ticket` | Reading a ticket |

`ponytail` stays the simplicity lens for Reviewer B. The git-bug section moves into the `git-bug` skill (decision 8). MCP scope and MCP naming stay as short sections of `agents/AGENTS.md` until a workflow needs them, then move. Rejected: keeping one policy file with better headings, because the drift comes from workflows restating it, which headings do not stop. Rejected: one skill per section verbatim, because several sections are halves of one rule (the rabbit-hole detector and the do-not-escalate list).

### 2. Principles are loaded by name and stay out of routing

Each principle's description and first line say it is not a workflow and is read when a step names it. A workflow names a principle at the step that needs it; the agent loads it by reading its `SKILL.md` or through the harness's skill tool, which are equivalent. (Implementation, 2026-10-18: the first draft set `disable-model-invocation: true`, which keeps Claude Code from listing a skill, but the repository's declared frontmatter check, the Codex skill validator, rejects any key outside name, description, license, allowed-tools and metadata. Upstream skills that carry other keys still load, so the validator is stricter than the harnesses; the key was dropped to keep the check green for the skills this repository owns; the cost is nine short descriptions in each harness's skill list.) Flip: a harness routes to a principle as if it were a workflow, in which case principles move to a directory no harness lists and workflows read them by path.

### 3. The `worktree` block

Steps: resolve the default branch; resolve the name (the Linear issue's git branch name through the Linear MCP's `get_issue` when the work is bound to an issue, otherwise propose a kebab-case name with a type prefix and wait for the user); run `wt switch --create <name> --base <default-branch> --no-cd --format json`; read the worktree path from the JSON; write the branch note and task list there; continue every later command with that absolute path. No `--yes`: when worktrunk reports that project hooks need approval, the block stops and asks. `worktrunk/config.toml` gains a pre-start step after `copy-ignored` that removes `.agent/` from the new worktree, so ignored files the app needs (such as `.env`) still arrive while notes do not. Rejected: `--require-include`, which would stop copying everything a repository has not listed in `.worktreeinclude`. Rejected: `git worktree add`, which bypasses worktrunk's layout and hooks.

Creating the branch moves from `yolo` to this block, which `iteration` and `yolo` both call. A local branch is not a publication, so publication authority is unchanged. The default-branch note key and the note-renaming step disappear, because work never starts on the default branch.

### 4. The `open-pr` block

Steps: confirm the branch is not the default branch; check the agreement (a direct "open a PR" names the publication for the current diff, unless the branch's iteration ledger has an open acceptance question, which it asks about once; from `yolo` the run's approval covers it); run the local ladder through `verification`; commit per `principle-write-for-the-reader`; push; open the PR as `WIP:` or refresh an existing one in place; write the body (problem, behavior, verification, manual verification surfaces, assumptions, rejected review findings when given), with a mermaid diagram when the change spans three or more components, a cross-process flow or a state machine; attach screenshots with `gh pr edit --attach`; drive required checks and mergeability green; remove `WIP:`. A direct `open-pr` runs no adversarial review; the user asks for `agent-review` when they want one. Rejected: keeping PR writing inside `yolo`, which is what forced every PR through the full run.

### 5. Stages: `iteration`, `poc`, `yolo`

`iteration` (the renamed `proto`) calls `worktree`, then loops build, local checks, present, fold in feedback, keeping the ledger in the branch note. Work stays uncommitted in its worktree, as in `proto`, because a commit is still a publication under the policy. Flip: the owner wants local checkpoint commits during iteration.

`poc` is a thin workflow entered from iteration or by "make it a PoC": it runs the local checks, makes the slice runnable end to end, records the run command, what it proves and what it fakes in the ledger, and publishes nothing. `yolo` is entered from an accepted ledger (iteration or PoC) or another settled contract; it reuses the worktree, writes the tests the ledger marks, runs `verification`, `agent-review` once over the whole diff, and `open-pr`. Its entry rule and the agreement test are unchanged.

### 6. Older unarchived changes

Each of the four is checked against the forge: a change whose PR merged is archived through `land` before this change's specs are written into `openspec/specs/`, and a requirement it carries that this change supersedes gets a dated note in that change pointing here. Rejected: editing their requirements in place, which rewrites what was agreed then.

### 7. Evals

`proto-gate` becomes `iteration-gate`; `happy-path` and `yolo-bounded` expect a worktrunk worktree instead of branch-in-place; one new scenario covers a direct "open a PR" (PR opened through `open-pr`, no adversarial review, `WIP:` lifecycle) and one turn covers naming (no issue: the agent proposes a name and waits). The runner drops its herdr environment handling. Acceptance is `bun evals/run.ts --dry-run`, then the paid `--run --all` with every transcript reviewed.

### 8. git-bug as a skill

The `git-bug` skill carries the git-bug section of `agents/AGENTS.md` (transport, the key in the agent, one identity, bug and feature shape) and maps each tool of the removed server to its CLI command: `git bug bug` (list, status filter), `git bug bug show <id>`, `git bug bug new -t -m`, `git bug bug comment new -m`, `git bug bug label new`, `git bug bug title edit`, `git bug user`, `git bug pull` and `git bug push`. `git-bug-mcp/`, its entries in `opencode/opencode.json` and `pi/mcp.json`, and the README line naming it are deleted; removing it from Claude Code's configuration outside this repository is a manual step named in the PR. Trade-off: the server read bugs from git plumbing while `git bug termui` held the lock; the skill does not, and reports the lock holder instead, as the policy already prescribes for writes. Rejected: reimplementing git-bug's operation folding in a script, 749 lines of server for one convenience. Flip: the owner often keeps termui open while agents work, in which case the skill gains a small read script.

## Risks / Trade-offs

- [A workflow step names a principle the agent never reads] → evals assert the skills each turn reads, and each principle is short enough that reading it costs less than skipping it.
- [Many small files cost more reads than one policy] → only the principles a step names are read, and the always-on policy shrinks; the paid eval run reports usage to compare against the current baseline.
- [Every task in its own worktree leaves worktrees behind] → the final report always gives `wt remove`, and the existing post-merge `wt step prune` hook reaps merged ones.
- [The policy is global, so other repositories' notes still say `proto`] → a branch note is read by its branch key whichever workflow wrote it, so `iteration` continuing on that branch reads a `proto` note as its own; a note under the default branch key is never read by a new worktree, the rename is mentioned in `agents/README.md`, and the owner moves any such live note by hand.
- [Approval prompts for project hooks stop an unattended run] → the stop is deliberate, and a repository that trusts its hooks can record that in its own `AGENTS.md`.

## Migration Plan

Built on its own branch from the default branch, in this order so each step is checkable: the two new blocks and the worktrunk config; the principles and the slimmed policy; the workflows rewritten on top of them, `proto` and `harness-restart` removed; evals updated; docs and the older changes reconciled. Rollback is reverting the PR: every file lives in this repository and the links do not change.
