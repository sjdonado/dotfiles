# OpenCode

Public OpenCode configuration shared across macOS and Linux.

## Tracked

- `opencode.json` - OpenCode Zen default model, permissions, and MCP servers
- `AGENTS.md` - link to shared global instructions
- `skills/` - link to shared Agent Skills
- `kv.json` - persisted public TUI preferences, including thinking visibility, timestamps, details, animations, and diff wrapping

The setup scripts link the config entries individually into `~/.config/opencode/` and `kv.json` into `~/.local/state/opencode/`. They do not replace either directory, so OpenCode and Herdr can keep generated dependencies, model history, sessions, and integration plugins beside them.

MCP server definitions added to `opencode.json` are shared. Keep credentials out of the file: use OpenCode OAuth storage or environment references. Authentication and generated state remain machine-local under `~/.local/share/opencode/`, `~/.local/state/opencode/`, and `~/.cache/opencode/`; only the explicitly linked `kv.json` UI preferences are shared from the state directory.

## Process safety

Agent-issued `opencode ...` shell commands are denied. Use OpenCode's native task/subagent mechanism instead of recursively spawning CLI processes. This prevents review workflows from leaving large trees of orphaned `opencode run` workers.

Shared review-selection policy lives in `AGENTS.md`; upstream skill files remain unmodified.

## Setup

```sh
./macos.sh
# or
./linux.sh
```

Then authenticate providers and MCP servers on each machine:

```sh
opencode auth login
opencode mcp auth <server>
```

The default is the hosted `opencode/gemini-3.8-flash` model through OpenCode Zen, so OpenCode does not reserve laptop RAM for local inference. Use Codex for OpenAI models and Claude Code for Anthropic models.

Configuration documentation:

https://opencode.ai/docs/config/

https://opencode.ai/docs/mcp-servers/
