> Blazyinly fast Development Setup 🚀

## Getting started

1. Clone this repo into `~/.config/dotfiles`

### Bootstrap

- macOS: run from the dotfiles directory: `./macos.sh`
- Linux (remote/dev box): `./linux.sh`
- Add `--install` to install or update dependencies (`./macos.sh --install` or `./linux.sh --install`). Without it, setup only updates directories, symlinks, and configuration.
- Update Brewfile: `/opt/homebrew/bin/brew bundle dump --describe --force --file=- > Brewfile`

### AI coding

Claude Code and OpenCode share commands, skills, and global instructions from `agents/`. Run the platform setup script to link them into both harnesses.

Authenticate providers and configure MCP servers manually:

```sh
claude
opencode auth login
opencode mcp add
```

Use the OpenCode `ollama` primary profile for the local model; it excludes MCP tools. See `agents/README.md` for migration and cleanup details.

### Text editor

- Run `nvim .`
- Update plugins: `:Lazy`
- Update LSP servers, DAP servers, linters, and formatters: `:Mason`

### Happy Hacking!

<img width="200" alt="image" src="https://media.tenor.com/y2JXkY1pXkwAAAAM/cat-computer.gif">
