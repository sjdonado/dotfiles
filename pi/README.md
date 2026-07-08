# pi

[pi](https://pi.dev) coding agent, configured to run on my Claude
subscription via [pi-claude-bridge](https://github.com/elidickinson/pi-claude-bridge).

`settings.json` symlinks to `~/.pi/agent/settings.json` (done by `bootstrap.sh`).
Defaults: provider `claude-bridge`, model `claude-opus-4-8` (1M context),
thinking level `high`.

## Install (also automated in bootstrap.sh)

```sh
curl -fsSL https://pi.dev/install.sh | sh
pi install npm:pi-claude-bridge
```

Extensions in `settings.json` `packages` auto-install on first launch.

## Subagents

`extensions/subagent/` — task delegation to isolated-context `pi` subprocesses
([example](https://github.com/earendil-works/pi/tree/main/packages/coding-agent/examples/extensions/subagent)).
Symlinked into `~/.pi/agent/{extensions/subagent,agents,prompts}` by `bootstrap.sh`.

- `agents/` — scout (recon, haiku), planner, reviewer, worker (sonnet).
- `prompts/` — workflow presets: `/implement`, `/scout-and-plan`,
  `/implement-and-review`, and `/bugfix`.

`/bugfix <linear-id|url|term>` — fetches the Linear issue, scouts the codebase for
root cause, and returns fixes with pros/cons (or asks for clarification). Analysis
only, never implements.

## openspec

[@fission-ai/openspec](https://github.com/Fission-AI/OpenSpec) installed globally
(`npm i -g @fission-ai/openspec@latest`). Run `openspec init` per project.

## Auth

Uses the Claude Code subscription OAuth token (shared via the Agent SDK) —
not versioned here. `~/.pi/agent/auth.json` and Claude creds stay local.
If runs return 401, refresh the token by logging in with `claude`.
