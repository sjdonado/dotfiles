# Proposal

## Why

The harness is two monoliths: a 346-line shared policy (`agents/AGENTS.md`) and workflow skills that each restate their own procedure. `yolo` alone is 62 dense lines that re-describe branching, verification, review, PR writing and check driving, and `proto` re-describes the ladder, notes and gates. A rule therefore lives in several places, a change to one workflow drifts from the others, and the expensive steps are welded to the workflows that use them: there is no way to open a PR without the whole `yolo` run, and every round of feedback in the wrong workflow buys an adversarial review. Worktrees still depend on herdr, which the setup no longer installs.

## What Changes

- **Principles as building blocks.** The shared rules move out of `agents/AGENTS.md` into small `principle-*` skills (for example deciding instead of asking, proving work with the oracle ladder, testing agreed decisions, grounding claims in evidence, stopping at a rabbit hole, keeping state outside the session, writing for the reader). Each is short, is not routed to on its own, and is loaded by the workflows that rely on it. `agents/AGENTS.md` shrinks to routing and the hard boundaries that must hold in every session: publication authority, secrets, never merging, never committing to the default branch.
- **Building-block skills.** Reusable steps become skills of their own: `worktree` (new), `open-pr` (new), `agent-review` and `verification` (existing). Workflows compose them instead of restating them.
- **Worktrees through worktrunk only.** Every task runs in its own worktrunk worktree on a new branch, created by the `worktree` block. The branch name comes from the Linear issue's git branch name when the task has one; otherwise the agent proposes a name and asks. New worktrees get no copy of `.agent/` notes. **BREAKING**: the herdr worktree rule, the branch-in-place default, the `harness-restart` skill and the evals' `HERDR_ENV` handling are removed.
- **`open-pr` as its own skill.** Committing, pushing, opening or refreshing a PR, the `WIP:` lifecycle and PR prose live in one skill, entered from `yolo` or directly by a request such as "open a PR". A PR body includes a mermaid diagram when the change is complex enough that a diagram explains it faster than prose.
- **`iteration` replaces `proto`.** **BREAKING** (rename): `iteration` runs in its own worktree on a new branch, where requirements are found and concepts proven through cheap rounds of owner feedback: local checks only, no adversarial review, nothing pushed. It ends in one of three states: a PoC (a runnable local demo with its ledger, nothing pushed), a hand-off to `yolo`, or a killed premise.
- **`yolo` builds on iteration.** `yolo` takes an accepted iteration ledger (or another settled contract) in its worktree and adds what iteration deliberately skips: tests, adversarial review, `open-pr`, and driving every check green. Adversarial review runs once, at `yolo`, over the whole accumulated diff.
- **git-bug through a skill, not a server.** **BREAKING**: the custom git-bug MCP server (`git-bug-mcp/`) is removed. A `git-bug` skill carries the git-bug rules now in `agents/AGENTS.md` and drives git-bug through its non-interactive CLI; `git bug push` stays a gated publication.
- **Workflows become thin.** `iteration`, `poc`, `yolo`, `feedback` and the other workflows name the principles and blocks they compose and keep only their own entry rule, steps and exit states.
- The evals follow: scenarios and expectations that name `proto`, branch-in-place or herdr are updated to the new names and the worktree rule.

## Capabilities

### New Capabilities

- `harness-structure`: how the harness is organized: the routing and hard boundaries in the shared policy, principle skills, building-block skills, and workflows that compose them.
- `task-worktrees`: where a task's branch is checked out: one worktrunk worktree per task, its naming, what it does not inherit, and how it is removed.
- `pull-request-opening`: how a PR is opened or refreshed: the entry points, the agreement it needs, its prose, the `WIP:` lifecycle and diagrams.
- `work-graduation`: the stages a task moves through (iteration, PoC, yolo), what each runs and skips, and what moves work from one stage to the next.

### Modified Capabilities

None: `openspec/specs/` holds no main specs yet. Requirements in the unarchived harness changes (`settle-workflow-routing-contract`, `default-yolo-and-session-tasks`, `improve-harness-effectiveness`, `harness-scenario-tracking`) that name `proto`, branch-in-place or herdr are superseded by this change; design.md says how they are reconciled.

## Impact

- `agents/AGENTS.md` (linked as the global policy into every harness), every skill under `agents/skills/` that references `proto`, `yolo`'s steps, the Workspace rule or PR writing, new `principle-*`, `worktree`, `open-pr`, `iteration` and `poc` skills, and the removal of `proto` and `harness-restart`.
- `worktrunk/config.toml` (no `.agent/` copy into new worktrees).
- `git-bug-mcp/` (deleted), its MCP entries in `opencode/opencode.json` and `pi/mcp.json`, and the README line that lists the configured MCP servers. Claude Code's MCP configuration lives outside this repository.
- `evals/` scenarios, expectations and runner; a paid `--all` run with transcript review is the acceptance evidence.
- The repository guide (`AGENTS.md`) and `agents/README.md` where they describe the workflows.
- No change to the setup declaration beyond `worktrunk/config.toml` and the two MCP configuration files.
