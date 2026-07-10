# pi

[pi](https://pi.dev) coding agent, on my Claude subscription via
[pi-claude-bridge](https://github.com/elidickinson/pi-claude-bridge).

`settings.json` symlinks to `~/.pi/agent/settings.json` (via `bootstrap.sh`).
Defaults: provider `claude-bridge`, model `claude-opus-4-8` (1M context),
thinking `high`.

## Install

`bootstrap.sh` installs pi as a standalone bundle: private Node under
`~/.local/share/pi-node`, launched by a `~/.local/bin/pi` wrapper. No pnpm or
system Node dependency. Update:

```sh
~/.local/share/pi-node/current/bin/npm i -g \
  --prefix ~/.local/share/pi-node/current @earendil-works/pi-coding-agent
```

Packages in `settings.json` (`pi-claude-bridge`, `pi-mcp-adapter`,
`pi-copy-response`, `pi-quota-status`) auto-install on first launch.

## Agents

`extensions/subagent/` — task delegation to isolated-context `pi` subprocesses
([example](https://github.com/earendil-works/pi/tree/main/packages/coding-agent/examples/extensions/subagent)).
Symlinked into `~/.pi/agent/{extensions/subagent,agents,prompts}` by `bootstrap.sh`.

- `general` — full-capability agent, follows [`ponytail`](skills/ponytail) (laziest working solution).
- `scout` — fast recon, returns caveman-compressed context for handoff.

## Prompts

- `/triage <linear-id|url|paste>` — understand a ticket (bug, feature, or small
  change), investigate, propose approach with tradeoffs. Analysis only.
- `/plan <task>` — system-aware plan via [`plan-mode`](skills/plan-mode), smallest coherent solution. No impl.
- `/yolo <reqs>` — autonomous requirements→PR via [`ponytail`](skills/ponytail): clarify once, then implement and open a PR, no further input.
- `/address-review <pr>` — fix legit PR comments (reply w/ commit hash), reject
  others w/ reason, fix red CI + stale branch.

## Global config

`AGENTS.md` symlinks to `~/.pi/agent/AGENTS.md` — appended to the default system
prompt (not a replacement). Enforces `caveman-commit` style for commit messages.

Skills live in `skills` (symlinked to `~/.agents/skills`).

## Auth

Claude subscription OAuth (shared via the Agent SDK) — not versioned.
`~/.pi/agent/auth.json` + `mcp.json` (MCP tokens, codex token) stay local.
401 → refresh via `claude` login.
