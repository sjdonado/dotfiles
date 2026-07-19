# OpenCode

Public OpenCode configuration shared across macOS and Linux.

## Tracked

- `opencode.json` - models, permissions, and the MCP-free Ollama primary profile
- `AGENTS.md` - link to shared global instructions
- `commands/` - link to shared slash commands
- `skills/` - link to shared Agent Skills
- `kv.json` - persisted public TUI preferences, including thinking visibility, timestamps, details, animations, and diff wrapping

The setup scripts link the config entries individually into `~/.config/opencode/` and `kv.json` into `~/.local/state/opencode/`. They do not replace either directory, so OpenCode and Herdr can keep generated dependencies, model history, sessions, and integration plugins beside them.

MCP server definitions added to `opencode.json` are shared. Keep credentials out of the file: use OpenCode OAuth storage or environment references. Authentication and generated state remain machine-local under `~/.local/share/opencode/`, `~/.local/state/opencode/`, and `~/.cache/opencode/`; only the explicitly linked `kv.json` UI preferences are shared from the state directory.

## Process safety

Agent-issued `opencode ...` shell commands are denied. Use OpenCode's native task/subagent mechanism instead of recursively spawning CLI processes. This prevents review workflows from leaving large trees of orphaned `opencode run` workers.

The `pr-review` skill is denied to automatic model invocation and is exposed through the human-only `/pr-review` command wrapper.

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

Configuration documentation:

https://opencode.ai/docs/config/

https://opencode.ai/docs/mcp-servers/
