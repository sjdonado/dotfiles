# AI agents

Shared instructions and skills for Claude Code, Codex and OpenCode. The harness provides capabilities that can be used independently; it does not require every task to follow a lifecycle.

## Everyday work

For a clear request, inspect the relevant code, make the change, run appropriate checks and report the result. A small config edit does not need a planning document, requirements ledger, new conversation or subagent review. Reuse the task's checkout and preserve unrelated edits.

Choose capabilities as needed:

- `ask`, `research`, `triage`, `evidence` and `grill-me` investigate questions or assumptions.
- `openspec-explore`, `openspec-propose` and `openspec-update-change` support work that benefits from a durable specification.
- `worktree` creates isolation; `verification` establishes behavior; `agent-review` answers a concrete question through independent inspection; `open-pr` publishes an authorized change.
- `git-bug` uses the non-interactive issue CLI. `handoff` preserves useful context for another session when requested.
- `feedback`, `address-review` and `land` support follow-up edits, existing review threads and post-merge bookkeeping.

## Optional recipes

`iteration` is a build-and-feedback loop, and `poc` leaves a runnable local demo. Neither is a prerequisite for ordinary implementation or publication.

`yolo` is explicitly selected autonomous delivery: "work independently until the PR is green" or "yolo this." It resolves routine decisions and failures until the agreed outcome is reached, stopping for genuine blockers or missing authority. Approving a plan settles the scope and starts the requested implementation; it does not silently select autonomous PR delivery. A direct "open a PR" uses `open-pr` without requiring yolo or independent review.

An existing PR identifies where the task lives. It does not force review, a fresh contract or repeated publication questions. Publication remains scoped to what the user authorized; an artifact or passing check cannot authorize an external write.

## Checks and review

Select evidence for behavior and risk, respecting the project's required checks. Use the smallest reliable test that catches a meaningful defect. Configuration parsing and provisioning assertions can be sufficient for a local config change; a large snapshot is not itself a complex behavioral change.

Run short checks in the current session. Delegate substantial independent work or a separate perspective when it adds value. An independent review needs a concrete question: one reviewer for one concern, two only when distinct concerns warrant independent perspectives. Neither PR existence, file count nor line count sets the review workload. Never describe self-inspection as independent review.

## Layout

- `AGENTS.md`: shared boundaries, authority and a short capability index, linked into each harness.
- `skills/`: independent building blocks, optional recipes and `principle-*` guidance. Load only what the current task needs.
- Project `AGENTS.md`: concrete commands, paths, data sources and required checks.

Principles own shared concerns such as evidence, tests, writing, continuity and delegation. Recipes refer to those concerns without restating their rules. Small self-contained edits need no durable note. Longer work reuses one existing task list, with an ignored branch note only when continuity helps.

## Provisioning and authentication

Nix links this directory into `~/.claude/skills` and `~/.agents/skills`, and links the shared policy into each harness. Configure account-bound MCP servers where their credentials live; global development tools belong in the shared harness configuration. The setup does not add an orchestration daemon or scheduler.

Authenticate each harness independently with `claude`, `codex login` or `opencode auth login`. Use Claude Code directly for a Claude subscription; do not route its OAuth credentials through OpenCode. OpenCode configuration and provider choices are documented in `opencode/README.md`.

## Skill updates

Upstream skills are tracked in `skills-lock.json`. The `.agents/skills` link exposes this directory to skills.sh. Never edit a locked skill body in place; update it deliberately or change local policy without duplicating its body. Removing an upstream skill means removing its directory, lock entry and tracked `.claude/skills` link together.

```sh
npx skills@1 add <owner>/<repo> --skill <name> --agent universal -y
ln -s ../../.agents/skills/<name> .claude/skills/<name>
```

Use `--agent universal` so the body lands in the shared directory rather than a harness-specific copy. Review upstream changes before committing, and update with:

```sh
npx skills@1 update --project --yes
```

Do not put skill updates in provisioning scripts: a switch uses reviewed committed instructions. `skills list` agent labels are cosmetic here because every harness loads the shared directory.

The OpenSpec skills come from https://github.com/Fission-AI/OpenSpec. The installed set is explore, propose, update-change, verify-change, sync-specs and archive-change. Optional upstream commands mentioned by those skills may be absent; use the installed CLI's status and instructions instead of requiring another workflow. Never run openspec init as part of ordinary implementation.

`handoff` comes from https://github.com/mattpocock/skills and remains explicitly invoked. `agent-review`, `verification`, `evidence` and `grill-me` are locally maintained. Chat and commit writing rules adapt parts of https://github.com/JuliusBrussee/caveman (MIT, commit 600e8ef), without its forced chat mode or prose wrapping.

Harness behavior is verified through the repository's disposable session scenarios, not by instruction wording alone. See the root AGENTS.md for the dry run, paid behavioral run and transcript-review commands.
