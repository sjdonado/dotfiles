# AI agents

Shared Claude Code and OpenCode commands, skills, and instructions.

## Layout

- `commands/` - shared `/address-review`, `/ask`, `/create-ticket`, `/feedback`, `/plan`, `/pr-review`, `/research`, `/triage`, and `/yolo` commands
- `skills/` - Agent Skills loaded on demand by both harnesses
- `AGENTS.md` - global instructions, linked as Claude Code's `CLAUDE.md` and OpenCode's `AGENTS.md`

The setup scripts link the same command and skill directories into both harnesses. There are no copied wrappers, custom subagent definitions, custom tools, or search plugins; the only custom agent is the OpenCode Ollama primary profile.

`pr-review` is human-only. Claude Code disables model invocation for the skill, while OpenCode denies automatic skill loading and exposes it only through the `/pr-review` command wrapper.

## Authentication

Authenticate each harness independently:

```sh
claude
opencode auth login
```

Use Claude Code directly for a Claude Pro/Max subscription. Do not route its OAuth credentials through OpenCode.

Configure MCP servers manually in each harness. OpenCode's public configuration is tracked under `opencode/`; credentials and generated runtime state stay machine-local. See `opencode/README.md`.

OpenCode documentation:

https://opencode.ai/docs/config/

https://opencode.ai/docs/mcp-servers/

Claude Code documentation:

https://code.claude.com/docs/en/mcp

## Ollama

Select the `ollama` primary profile instead of only switching the model. The profile uses `ollama/gemma4:e4b`, blocks delegation, and denies the current `linear_*` and `posthog_*` MCP tools so their schemas do not consume the local model's context.

When adding another OpenCode MCP server, also add its `<server-name>_*` deny rule to the `ollama` profile in `opencode/opencode.json`.

## Remove Pi

After Claude Code and OpenCode pass smoke tests, run:

```sh
~/.config/dotfiles/bin/cleanup-pi.sh
```

The cleanup keeps `~/.pi/agent/sessions` and other Pi user data by default. Remove all Pi data only when it is no longer needed:

```sh
~/.config/dotfiles/bin/cleanup-pi.sh --purge-data
```

Rollback before purging by restoring any timestamped command, skill, or instruction backups created by the setup script and reinstalling Pi with its original package manager.
