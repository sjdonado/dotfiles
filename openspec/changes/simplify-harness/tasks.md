# Tasks

## 1. Building blocks

- [x] 1.1 Write `agents/skills/worktree/SKILL.md` per design decision 3 (Linear branch name, else propose and wait; `wt switch --create --base --no-cd --format json`; stop on hook approval; note and task list written in the new worktree; report path and `wt remove`). Verify by creating a worktree in a scratch repository with the documented command and reading its path from the JSON.
- [x] 1.2 Add the pre-start step to `worktrunk/config.toml` that removes `.agent/` after `copy-ignored`. Verify in a scratch repository with an ignored `.env` and an `.agent/note.md`: the new worktree has `.env` and no `.agent/`.
- [ ] 1.3 Write `agents/skills/open-pr/SKILL.md` per design decision 4 (agreement check, local ladder through `verification`, commit, push, `WIP:` PR or in-place refresh, body sections, mermaid rule, `--attach`, checks and mergeability green, `WIP:` removed). Verify with the quick_validate frontmatter check and the eval in 4.3.

## 2. Principles and the shared policy

- [x] 2.1 Create the `principle-*` skills in design decision 1's table, each with a description that opens "Not a workflow" (no `disable-model-invocation` key, which the repo's validator rejects; design decision 2), a first line saying it is not a workflow, and one rule as trigger, action and stop condition. Verify each passes the quick_validate frontmatter check.
- [x] 2.2 Reduce `agents/AGENTS.md` to routing, the always-on boundaries and a principles index, moving every other section into its principle. Verify with a grep that each moved rule's normative sentence exists in exactly one file under `agents/`.
  - 2026-10-19: a phrase check over 57 normative rules from the previous `agents/AGENTS.md` finds each in one owning file; the other hits are references by name (rabbit-hole, Conventional Commits types, `WIP:` in yolo's hand-off) or the git-bug, evidence and create-ticket link rules that predate this change.

## 3. Workflows

- [x] 3.1 Write `agents/skills/iteration/SKILL.md` from `proto`, composed of `worktree`, the principles it names and its three exit states; delete `agents/skills/proto/`. Verify no file under `agents/` or `evals/` names `proto` except dated history.
- [ ] 3.2 Write `agents/skills/poc/SKILL.md` per design decision 5. Verify with the quick_validate frontmatter check and the turn added in 4.2.
- [x] 3.3 Rewrite `agents/skills/yolo/SKILL.md` as a composition of `worktree` (reuse), `verification`, `agent-review` and `open-pr`, keeping its entry rule. Verify it restates no step those skills own (grep for their procedure sentences).
- [x] 3.4 Update `feedback`, `address-review`, `land`, `triage`, `research`, `ask`, `create-ticket`, `grill-me`, `harness-audit`, `harness-boostrap`, `verification` and `agent-review` to name principles and blocks instead of restating them; delete `agents/skills/harness-restart/`. Verify with a grep for herdr, `HERDR_ENV`, branch-in-place and `proto` under `agents/`.

## 4. Evals

- [ ] 4.1 Rename `proto-gate` to `iteration-gate` and update `happy-path` and `yolo-bounded` to expect a worktrunk worktree; drop the herdr handling in `evals/run.ts`. Verify with `bun evals/run.ts --dry-run`.
- [ ] 4.2 Add a turn where work without an issue starts: the agent proposes a branch name and waits. Verify with `--dry-run`.
- [ ] 4.3 Add an `open-pr` scenario: a direct "open a PR" on a task branch opens a `WIP:` PR through `open-pr`, runs no adversarial review, and a red local check blocks it. Verify with `--dry-run`.
- [ ] 4.4 Run `bun evals/run.ts --run --all` and review every transcript; record pass counts and usage against the last baseline in the PR.

## 5. Docs and older changes

- [x] 5.1 Update `agents/README.md` and the repository guide (`AGENTS.md`) to describe the three layers and the stage names. Verify with a grep for `proto` and herdr.
- [x] 5.2 Check the PRs of `settle-workflow-routing-contract`, `default-yolo-and-session-tasks`, `improve-harness-effectiveness` and `harness-scenario-tracking`, and add a dated superseded note to each, naming the requirements this change replaces. Verify each proposal carries the note and `openspec validate --strict` reports no error this change introduced, for each and this one.
  - 2026-10-18: all four PRs merged (#19, #9, #5, and a direct commit), but each still has open tasks (1, 7, 3, 9), so archiving them needs the owner to judge those tasks done or obsolete; archiving is left to a later `land` pass instead of this run (deviation from design decision 6, recorded in the PR). `improve-harness-effectiveness`, `harness-scenario-tracking` and this change validate; `settle-workflow-routing-contract` and `default-yolo-and-session-tasks` fail strict only on pre-existing long-requirement warnings in spec files this change does not touch.

## 6. git-bug

- [x] 6.1 Write `agents/skills/git-bug/SKILL.md` per design decision 8 and remove the git-bug section from `agents/AGENTS.md`. Verify by running the skill's read commands (`git bug bug`, `git bug bug show <id>`) in a repository that tracks bugs, and with the quick_validate frontmatter check.
- [x] 6.2 Delete `git-bug-mcp/`, its entries in `opencode/opencode.json` and `pi/mcp.json`, and the README line naming it. Verify with `python3 -m json.tool` on both files and `git grep git-bug-mcp` returning nothing outside dated history.

## 7. Setup carried from PR #34

- [x] 7.1 Land the staged setup change that missed PR #34: ngrok cask removed, notion cask added, herdr removed from the setup (its directory, commented steps and link, the Claude hook, the OpenCode plugin entry), tracked as provision-with-nix task 10.7. Verify with `verify/macos.sh` and `python3 -m json.tool` on the edited JSON.

## Workflow follow-up

- After the PR merges, `land` archives this change and syncs its specs into `openspec/specs/`.
