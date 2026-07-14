> Blazyinly fast Development Setup 🚀

## Getting started

1. Clone this repo into `~/.config/dotfiles`

### Bootstrap

- macOS: run from the dotfiles directory: `./macos.sh`
- Linux (remote/dev box): `./linux.sh`
- Add `--install` to install or update dependencies (`./macos.sh --install` or `./linux.sh --install`). Without it, setup only updates directories, symlinks, and configuration.
- Update Brewfile: `/opt/homebrew/bin/brew bundle dump --describe --force --file=- > Brewfile`

### Text editor

- Run `nvim .`
- Update plugins: `:Lazy`
- Update LSP servers, DAP servers, linters, and formatters: `:Mason`

### Happy Hacking!

<img width="200" alt="image" src="https://media.tenor.com/y2JXkY1pXkwAAAAM/cat-computer.gif">
