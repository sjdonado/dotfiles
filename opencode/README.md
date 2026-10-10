# OpenCode

Public OpenCode v2 configuration shared across macOS and Linux. Mise installs `@opencode/cli` and explicitly allows its postinstall script to select the native binary. Update the mise version and lock together rather than using OpenCode's self-updater.

## Tracked

- `opencode.json` - hosted default model, permissions, and optional MCP servers
- `cli.json` - terminal preferences with animations enabled and image previews, sidebar, and tabs disabled
- `AGENTS.md` - link to shared global instructions
- `skills/` - link to shared Agent Skills
- `kv.json` - legacy v1 preferences retained for migration; v2 uses `cli.json`

The setup scripts link the config entries individually into `~/.config/opencode/` and `kv.json` into `~/.local/state/opencode/`. They do not replace either directory, so OpenCode and Herdr can keep generated dependencies, model history, sessions, and integration plugins beside them.

MCP server definitions added to `opencode.json` are shared. All four servers connect automatically at startup. Use `/mcps` to manage connections, or set `disabled` to `true` in a project config under `mcp.servers` to keep a server disconnected. Project overrides replace the entire named server object, so repeat its command and other options. All four definitions explicitly use native code mode. Code mode changes how the agent calls tools; it does not eliminate the server process when connected.

LSP, automatic formatters, and filesystem snapshots are disabled. Run the project's typecheck and formatting commands when needed. Session undo does not restore files with snapshots disabled; use Git for file recovery.

Use the native `shell` tool with `background: true` for dev servers, watchers, and long-running jobs. It returns immediately, captures output, and notifies the session when the job finishes. Background jobs have no timeout unless one is supplied. Use the built-in Terminals interface for interactive terminal sessions. These native features replace `opencode-pty`; its tool names and separate observer web server are not installed. The setup prunes only repository-owned legacy PTY links.

Keep credentials out of the file: use OpenCode OAuth storage or environment references. Authentication and generated state remain machine-local under `~/.local/share/opencode/`, `~/.local/state/opencode/`, and `~/.cache/opencode/`. V2 uses one shared server for local clients by default. Use `opencode mini` for its minimal interactive interface without replacing the built-in agent tools.

Herdr installs its own dual-version server hook and v2 client integration. The client integration is retained in `cli.json` as `./herdr-opencode`, so the pane tracks its own conversation rather than the shared server's activity. Both installers refresh it through `herdr integration install opencode`; generated integration code stays machine-local.

## Process safety

Agent-issued `opencode ...` shell commands are denied. Use OpenCode's native task/subagent mechanism instead of recursively spawning CLI processes. This prevents review workflows from leaving large trees of orphaned `opencode run` workers.

Shared review-selection policy lives in `AGENTS.md`; upstream skill files remain unmodified.

## Setup

```sh
./macos.sh --install
# or
./linux.sh --install
```

Then authenticate providers and MCP servers on each machine:

```sh
opencode auth login
opencode mcp auth <server>
```

The default is the hosted `openai/gpt-6.1-sol` model, so OpenCode does not reserve laptop RAM for local inference. Connect OpenAI through `/connect` if it is not already available. Quit existing v1 clients and start OpenCode again after installing v2. V2 changes runtime and terminal configuration formats; the setup replaces only the repository-owned `tui.json` link with `cli.json` and preserves other local files.

For an existing machine, remove package-managed v1 before adopting v2 (`brew uninstall opencode` for the legacy Homebrew formula, or `mise uninstall --all github:anomalyco/opencode` for the old mise backend). Keep the old config in Git history while checking credentials, models, permissions, and plugins. Do not run v1 against the native v2 configuration. The full migration guide is https://opencode.ai/v2/docs/migrate-v1/.

Configuration documentation:

https://opencode.ai/v2/docs/config

https://opencode.ai/v2/docs/mcp-servers

https://opencode.ai/v2/docs/cli/config
