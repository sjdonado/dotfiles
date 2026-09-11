> Blazyinly fast Development Setup 🚀

## Getting started

1. Clone this repo into `~/.config/dotfiles`

### Bootstrap

- macOS: run from the dotfiles directory: `./macos.sh`
- Linux (remote/dev box): `./linux.sh`
- Add `--install` to install or update dependencies (`./macos.sh --install` or `./linux.sh --install`). Without it, setup only updates directories, symlinks, and configuration.
- Update Brewfile: `/opt/homebrew/bin/brew bundle dump --describe --force --file=- > Brewfile`

### Agent harness

Claude Code, Codex, and OpenCode share skills and global instructions from `agents/`. Run the platform setup script to link them into all three harnesses.

Authenticate providers and configure MCP servers manually:

```sh
claude
codex login
opencode auth login
opencode mcp add
```

OpenCode defaults to Gemini 3.8 Flash through OpenCode Zen. Use Codex for OpenAI models and Claude Code for Anthropic models. See `agents/README.md` for harness details.

In Codex, select the built-in `ansi` syntax theme with `/theme`. It uses the terminal's ANSI palette, so syntax colors follow Ghostty's live dark/light theme switch instead of staying pinned to a dark or light TextMate theme.

### Text editor (TTT)

- `prefix+.` toggles a dedicated TTT tab in herdr: it opens on first press, focuses on the next, and returns you to the tab you came from when pressed inside it. Or run `ttt .` directly to open the current directory.
- Right-clicks in that tab reach TTT's own menu rather than herdr's pane menu. herdr has no config default for that, only per-pane state, so the local `ttt-tab` plugin sets it on the pane it opens and `panel-revive` re-asserts it after a session restore. Upstream's `ttt.editor` plugin is deliberately not used: it cannot route right-clicks and has no toggle-back.
- It covers reading, diffs, staging, commits, and GitHub PR review (`ttt . <pr-url>`), and is operable by mouse and touch, so a phone or tablet terminal works without modal key chords.
- Settings live in `ttt/settings.json`, linked file by file into `~/.config/ttt/` (a tracked `keybindings.json` is picked up the same way if one is added later). TTT rewrites that file with its complete settings whenever you change something in its settings UI, so the tracked copy is a full snapshot rather than a list of overrides, and a UI change overwrites what is tracked instead of merging with it. TTT also keeps its plugin state (`plugins.ttt.json`, `plugins/`) in that same directory, which is why the directory itself is not linked.
- Plugins are a manual step: install them from TTT's Plugins sidebar (`ctrl+k` then the Plugins panel) or with `Install from URL`. Provisioning them from a script would mean writing pre-granted permissions for third-party Lua into a state file TTT rewrites, which is not worth it for the one plugin in use (Markdown Preview, which is text-only).
- No image or mermaid rendering, deliberately: TTT draws no images, and a standalone reader (mermaid to PNG, pandoc, chawan) was built and dropped as not worth chawan, pandoc and a headless-browser mermaid CLI across two platforms. It is recoverable with `git show 660215f:bin/mdp` if that judgement changes.
- No automatic dark/light switching either: TTT carries one `theme` string with no appearance query, so the theme is whatever was last chosen with Switch Theme. The pair is `default-dark` and `default-light`.

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
