# pi agent configuration

This directory holds the managed configuration for `pi-agent`, the upstream standalone Pi CLI:

- `settings.json`: subscription provider and model defaults, native code mode, pinned background-task/subagent packages.
- `mcp.json`: developer MCP servers (agent-browser, chrome-devtools, ios-simulator, git-bug), exposed through code mode.
- `subagent-config.json`: fresh-context subagent defaults for the upstream extension.

These files link to `~/.pi/agent/`. Authentication stays in Pi's private agent directory; dotfiles contain no credentials. Use `pi-agent`'s `/login` for subscription sign-in.

The PSS Pi scheme lives in its own repository at `~/Developer/pi-skin-sjdonado` (https://github.com/sjdonado/pi-skin-sjdonado) and opens with `pss`. See its README for setup, commands, upgrade notes, and prototype limitations. This directory holds only `pi-agent` configuration.
