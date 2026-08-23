> Blazyinly fast Development Setup 🚀

## Getting started

1. Clone this repo into `~/.config/dotfiles`

### Bootstrap

- macOS: run from the dotfiles directory: `./macos.sh`
- Linux (remote/dev box): `./linux.sh`
- Add `--install` to install or update dependencies (`./macos.sh --install` or `./linux.sh --install`). Without it, setup only updates directories, symlinks, and configuration.
- Update Brewfile: `/opt/homebrew/bin/brew bundle dump --describe --force --file=- > Brewfile`

### Agent harness

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
- Update plugins: `:PackUpdate` (`:PackUpdate!` skips the confirmation buffer, `:PackList` shows installed revisions). This config uses Neovim 0.12's built-in `vim.pack`, not lazy.nvim, so there is no `:Lazy`.
- Update LSP servers, DAP servers, linters, and formatters: `:Mason`

### Footprint

Measured on an Apple M5 with 32 GB of RAM, macOS 25.5, on 2026-08-22. Numbers are resident memory (RSS) and on-disk size, not virtual size. Reproduce them with the commands under each table; they are worth re-measuring rather than trusting, since every version bump moves them.

Neovim startup, five runs through a real pty so the UI attaches (`script -q /dev/null nvim --startuptime FILE -c 'qa!'`):

|                                            | time                       |
| ------------------------------------------ | -------------------------- |
| with UI                                    | 161-174 ms, median 163 ms  |
| headless (`nvim --headless --startuptime`) | 36-48 ms                   |
| of which `nvim/init.lua`                   | 38 ms sourcing, 18 ms self |

29 plugins, all through `vim.pack`, none lazy-loaded by a plugin manager. The single largest startup cost is Neovim's own `vim._core.defaults` at 114 ms, so the config is not what makes it feel slow: trimming plugins further buys back tens of milliseconds at most.

Resident memory per process, ranges taken across the instances that happened to be running (`ps -Ao rss,args`):

| process           | RSS                              |
| ----------------- | -------------------------------- |
| Ghostty           | 51 MB                            |
| `herdr server`    | 24 MB                            |
| `herdr` client    | 11 MB                            |
| `nvim`            | 5-38 MB each                     |
| Mason LSP servers | 38-54 MB each                    |
| `lazygit`         | 34 MB                            |
| `claude`          | 225-574 MB each, ~250 MB typical |
| `opencode`        | 280-840 MB, one process per TUI  |
| `wt`              | none, it exits                   |

So the terminal plus the multiplexer is about 85 MB, and everything after that scales per stream. An agent is one to two orders of magnitude heavier than any tool it drives: a handful of concurrent agents outweighs the 85 MB shell of the setup around them by an order of magnitude. Editors and LSP servers only matter once several worktrees each have their own.

On-disk, measured after `brew cleanup`, so each formula holds one version. Skipping cleanup roughly doubles the Homebrew rows, and it fails silently when another user in the `brew` group installed the older keg (see `homebrew/macos-multi-user.md`):

|                                                | size                                                |
| ---------------------------------------------- | --------------------------------------------------- |
| neovim                                         | 33 MB                                               |
| herdr                                          | 20 MB                                               |
| lazygit                                        | 18 MB                                               |
| worktrunk                                      | 22 MB                                               |
| opencode                                       | 137 MB                                              |
| claude                                         | 310 MB per version, more as legacy releases pile up      |
| nvim plugins (`~/.local/share/nvim/site/pack`) | 89 MB                                               |
| nvim Mason packages                            | 1.3 GB (clangd 368 MB, basedpyright 286 MB)         |
| nvim cache and state                           | 19 MB                                               |
| `~/.claude` (transcripts, skills, history)     | 475 MB                                              |
| `~/.local/share/opencode`                      | 1.4 GB                                              |
| `~/.config/herdr` (logs, session state)        | 37 MB                                               |

The tools themselves are small; what grows is everything they cache. Mason and the two agent state directories are 3.2 GB against about 230 MB of binaries. Agent version retention is its own line item: Claude Code self-updates into a new directory per release and leaves the old ones in place, so what it occupies depends on how many legacy versions have piled up rather than on the size of one install.

Worktrees dominate everything else. `~/.herdr/worktrees` was 42 GB, because a single checkout of one React Native monorepo is 12-15 GB once its dependencies are installed, and each worktree gets its own copy. `wt step copy-ignored` uses APFS clonefile, so a fresh worktree costs almost nothing until files are modified, and `du` still reports the full size for each. Budget by repository, not by worktree count.

### Minimum requirements

Derived from the numbers above, for the full setup (herdr + Claude Code or OpenCode + Neovim + lazygit + worktrunk):

| RAM   | Concurrent agent streams | Notes                                                                                       |
| ----- | ------------------------ | ------------------------------------------------------------------------------------------- |
| 8 GB  | 1-2                      | Workable for a single stream with an editor; a second agent plus its dev server will swap.  |
| 16 GB | 4-6                      | Where parallel worktrees stop being the constraint.                                         |
| 32 GB | 10+                      | What the numbers above were measured on, with agents, editors and dev servers all resident. |

Disk: about 5 GB for the toolchain and its caches (binaries, Mason, agent state), then the installed size of one checkout of the repository multiplied by the number of live worktrees. Scale it to the toolchain, not the source: a React Native or Expo app is the expensive case, 10-15 GB per worktree, and almost all of it is prebuilt native modules and platform build artifacts rather than JS. A plain web or Node monorepo of comparable source size is a few hundred MB to 2 GB, and a Go or Rust repository less again.

CPU matters less than either. Agents are I/O and network bound while waiting on a model, so the practical ceiling is memory and disk, not cores.

### Happy hacking!

<img width="200" alt="image" src="https://media.tenor.com/y2JXkY1pXkwAAAAM/cat-computer.gif">
