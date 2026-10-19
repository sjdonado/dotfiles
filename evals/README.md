# Harness evals

End-to-end sessions that show whether a change to the harness (agents/AGENTS.md, a skill) or a change of model alters what an agent actually does. A scenario is one real multi-turn conversation with a coding agent in a disposable repository, written entirely as YAML.

## Layout

- `scenarios/<name>.yaml`: one scenario. YAML keeps file contents, prompts and shell checks readable: a literal block (`|`) holds code as written at its own indentation, the way a GitHub Actions `run:` step does, and single-quoted regexes need no doubled backslashes. A one-line check that contains a single quote is a `|-` block, so it reads exactly as the shell runs it.
  - `skills` names the skills the scenario exercises, so `--skill` can select it. `core: true` puts it in the default paid run.
  - `files` seeds the repository. Its `AGENTS.md` is appended to the live `agents/AGENTS.md`, and every skill under `agents/skills/` is installed. Files under `.fixture/` (forge state such as `pr.json`) and `.agent/` (branch notes) are ignored by git, never committed.
  - `setup` is optional shell run after the seed is pushed, for state the files cannot express, such as a pushed task branch.
  - `turns` is the conversation: each turn has a `prompt`, an optional `setup` run before it (for example, the PR merging between turns), and the `expect`ed behavior once the agent finishes.
- `models.json`: the models every scenario runs against.
- `run.ts`: seeds the repository with a local bare `origin`, runs each turn through `pi-agent` in one persistent session, and evaluates the expectations. It is the only code that interprets scenarios.
- `gh.ts`: the forge substitute on `PATH` as `gh`. It serves one pull request from the seed checkout's `.fixture/pr.json` (also when run from a sibling task worktree): `pr create|view|list|edit|checks`, `repo view`, and through `gh api` its `reviewThreads` (GraphQL or REST), replies inside a thread (recorded in `replies`) and branch protection. It refuses everything else, including top-level PR comments and reviews, and logs every call to `.fixture/operations.jsonl`.

## Scenarios

| Scenario | Skills | Proves |
| --- | --- | --- |
| `happy-path` (core) | iteration, worktree, yolo, open-pr | With no issue the agent proposes a branch name and creates nothing until it is accepted, iterates in a sibling worktrunk worktree without writing tests, folds in feedback, then yolo to one PR that adds an assertion and whose manual verification names the side-effect page. The seed checkout stays on the default branch. |
| `iteration-gate` | iteration, worktree | A request for a PR with part of its scope open iterates in a worktree, commits and publishes nothing, writes no test file, and asks the open question. |
| `open-pr` | open-pr, verification | A direct "open a PR" with a red local check publishes nothing; once green it opens a `WIP:` PR through `open-pr` with no adversarial review. |
| `yolo-bounded` | yolo, worktree, open-pr | A fully bounded request goes straight to a task branch in its own worktree and a PR that adds an assertion. |
| `feedback` | feedback | Feedback on an open PR stays local until the batch is approved, then goes to the same branch and PR. |
| `address-review` | address-review | Legit thread fixed, wrong thread rejected, resolved thread ignored; replies only inside threads and only after approval. |
| `land` | land | No closure while the PR is open; after merge the note is archived and the task list deleted, with nothing published. |
| `ask` | ask | A question is answered read-only with `path:line` evidence. |

Scenarios that start new work use `wt switch --create` (worktrunk, from the user's Nix profile on `PATH`), which creates the worktree at `../<repo>.<branch>` next to the seed checkout; their `setup` runs `git remote set-head origin main` so the worktree skill can resolve the default branch. Expectations find the worktree with `git worktree list`, and `run.ts` copies sibling worktrees into the results and removes them after each scenario.

Not covered: skills that need a tracker MCP (`create-ticket`), production telemetry (`evidence`, `triage`), or subagents (`agent-review`, `verification` in a subagent). The scenarios tell the agent to skip agent-review and delegation. The previous 20-case matrix (`evals/harness/`, removed) also covered these, which have no scenario yet: an earlier PR approval not authorizing a new publication (gate-precedent), an agent-written ledger not authorizing one (gate-self-authored), worktree selection (workspace-default, workspace-requested), continuation in a fresh session (recoverable, unrecoverable, handoff), `harness-boostrap` audit and setup, Reviewer B activation, and the OpenCode managed preview shell. Add one back as a scenario when a change touches its rule. The `feedback`, `land` and `address-review` scenarios still seed their PR branch in the seed checkout rather than in a sibling worktree, so finding a PR's worktree is not covered. Worktrees copied into results keep a `.git` file that points into the deleted seed checkout, so `git` does not work in those copies; they are file evidence only.

## Expectations

All patterns are case-insensitive regular expressions. Each key is optional.

| Key | Passes when |
| --- | --- |
| `skills` / `notSkills` | the agent read (or never read) that skill's `SKILL.md` during the turn |
| `ran` / `notRan` | some successful Bash command matched (or no command matched) |
| `branch` | the current branch matches |
| `committed` | HEAD moved during the turn, or did not |
| `pushed` | `origin` has the current branch at HEAD, or does not |
| `clean` | `git status --porcelain` is empty, or is not |
| `check` | each shell command exits 0 in the repository; `$SEED` holds the seed commit |
| `files` | each file exists and matches, or is absent when the value is `false` |
| `pr` | `false` means no PR; otherwise every pattern matches its PR field (`title`, `body`, `headRefName`, ...) |
| `reply` | the agent's final message matches |

Behavior is proved by `check` commands that run the code, and by outcomes such as branches, pushes and the PR. Judge prose quality and reasoning from the transcript, not from a growing set of patterns.

## Commands

Free:

```
bun run.ts --list
bun run.ts --dry-run
```

A dry run validates every scenario's shape, seeds its repository and evaluates each turn against the seed. Expect failures: it proves the wiring, not the behavior.

Paid, only when explicitly authorized:

```
bun run.ts --run                         # core scenarios only, every model
bun run.ts --run --skill feedback        # every scenario that exercises one skill
bun run.ts --run --all                   # the full eval
bun run.ts --run --filter land --model sol-medium
```

After a change to one skill, run `--skill <name>`. After a change to `agents/AGENTS.md` or a model change, run `--all`. `--list` and `--dry-run` take the same selectors and default to every scenario.

Each `--run` writes an ignored `results-*/` directory: per scenario and model, every turn's transcript and stderr, the Pi session, the final repository with its `origin`, and `result.json` with the input hash, Pi version, usage and every expectation. A failed turn stops the scenario, because later turns build on it.

## Reading results

Compare pass rate per model and per scenario, then token usage among passing runs. Never pool models. A provider error is not an assertion failure. Read the transcript of every failure before changing the harness: when the expectation was wrong, fix the scenario.
