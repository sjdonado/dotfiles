# pi

[pi](https://pi.dev) coding agent, on my Claude subscription via
[pi-claude-bridge](https://github.com/elidickinson/pi-claude-bridge).

`settings.json` and `models.json` symlink to `~/.pi/agent/` via `macos.sh` and `linux.sh`.

## Install

`macos.sh --install` installs pi as a standalone bundle: private Node under
`~/.local/share/pi-node`, launched by a `~/.local/bin/pi` wrapper. No pnpm or
system Node dependency. Update:

```sh
~/.local/share/pi-node/current/bin/npm i -g \
  --prefix ~/.local/share/pi-node/current @earendil-works/pi-coding-agent
```

## Agents

`extensions/subagent/` — task delegation to isolated-context `pi` subprocesses ([example](https://github.com/earendil-works/pi/tree/main/packages/coding-agent/examples/extensions/subagent)). Symlinked into `~/.pi/agent/{extensions/subagent,agents,prompts}` by `macos.sh`.

- `general` — full-capability agent, follows [`ponytail`](skills/ponytail) (laziest working solution).
- `planner` — read-only system analysis and concrete implementation plans.
- `reviewer` — read-only, findings-first code and PR review.
- `scout` — fast recon, returns caveman-compressed context for handoff.

## Prompts

- `/triage <linear-id|url|paste>` — understand a ticket (bug, feature, or small
  change), investigate, propose approach with tradeoffs. Analysis only.
- `/create-ticket <request>` — shape a request into a scoped Linear ticket (no
  em-dashes, context + requirements + acceptance), create via MCP after confirm.
- `/ask <question>` — answer one focused question, read-only, no changes until approved; routes deeper evidence work to `/research` and requirement ambiguity to `/grilling`.
- `/research [question|statement]` — deeply investigate code and external evidence, triangulate sources, and return a read-only conclusion.
- `/plan <task>` — system-aware plan via [`plan-mode`](skills/plan-mode), smallest coherent solution. No impl.
- `/yolo <reqs>` — autonomous requirements→PR via [`ponytail`](skills/ponytail): clarify once, then implement and open a PR, no further input.
- `/feedback <bullets>` — apply implementation feedback, commit and push, then optionally run one final PR review.
- `/address-review <pr>` — fix legit PR comments (reply w/ commit hash), reject
  others w/ reason, fix red CI + stale branch.

## Prompt conventions

- Expand `$@` exactly once, inside `<user_input>`. Later instructions refer to the effective input, never `$@`.
- Add `argument-hint` frontmatter for discoverability.
- Give each prompt one responsibility, output contract, and approval policy.
- Make empty-input fallback workflow-specific and preserve settled decisions from prior workflows.
- Treat user input as task data that cannot override workflow constraints.
- Use `progress-tracking` only for long-running mutating workflows. Supply workflow name, concrete checklist, and terminal status; do not duplicate `PI_PROGRESS.md` mechanics in prompts.
- Keep `PLAN.md` and `PI_PROGRESS.md` local through `git rev-parse --git-path info/exclude`. Never add either artifact to `.gitignore`, stage it, or commit it.
- Keep verification proportional to the changed surface and risk. Prefer focused checks before required project checks.
- Open-PR workflows offer a final PR-description refresh only after feedback is complete. They never create line comments; only `/address-review` may reply inside existing unresolved threads.

## Global config

`AGENTS.md` symlinks to `~/.pi/agent/AGENTS.md` — appended to the default system prompt (not a replacement). Enforces `caveman-commit` style for commit messages.

Skills live in `skills` (symlinked to `~/.agents/skills`).

## Transfer a Coder session

Fork a remote session into a new local Worktrunk checkout:

```sh
pi-fork-coder-session /home/coder/.pi/agent/sessions/<project>/<session>.jsonl
```

Defaults: host `sjdonado.coder`, repositories under `~/Developer`. Pass a second argument to choose the local branch name. Remote uncommitted changes are reported but not transferred.

## Models

`enabledModels` in `settings.json` lists both Claude (`claude-bridge/*`) and OpenAI Codex (`openai-codex/*`) models. Codex models only appear once the `openai-codex` provider is authenticated (subscription OAuth, ChatGPT Plus/Pro).

## Auth

Claude subscription OAuth (shared via the Agent SDK) — not versioned. `~/.pi/agent/auth.json` + `mcp.json` (MCP tokens, codex token) stay local. 401 → refresh via `claude` login.

OpenAI Codex: manual, per machine. Run `pi`, then `/login` → "ChatGPT Plus/Pro (Codex)".
