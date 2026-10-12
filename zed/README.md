# Zed

Zed is an optional graphical editor alongside Neovim. The setup scripts link `settings.json` and `keymap.json` into `~/.config/zed`. Install Zed separately; these files do not provision the application.

The configuration keeps Vim mode, system light/dark themes, editor font sizes, project diagnostics, and TypeScript/JavaScript import updates on file moves. AI is disabled with `disable_ai: true`. No model providers, MCP servers, external agents, or agent shortcuts are configured. Agent management stays outside Zed.

The keymap retains terminal focus (`cmd-;`), Git (`cmd-shift-g`), recent projects (`cmd-ctrl-o`), the workspace sidebar (`cmd-[`), and the right dock (`cmd-]`). Other shortcuts use Zed defaults.
