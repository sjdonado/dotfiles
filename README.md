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

### Text editor

- `prefix+e` toggles a dedicated TTT tab in herdr: it opens on first press, focuses on the next, and returns you to the tab you came from when pressed inside it. Or run `ttt .` directly to open the current directory. herdr's own `edit_scrollback` moves to `prefix+shift+e` to make room, the way `settings` moved to `prefix+,` when the lazygit panel still held that key.
- Right-clicks in that tab reach TTT's own menu rather than herdr's pane menu. herdr has no config default for that, only per-pane state, so the local `ttt-tab` plugin sets it on the pane it opens and `panel-revive` re-asserts it after a session restore. Upstream's `ttt.editor` plugin is deliberately not used: it cannot route right-clicks and has no toggle-back.
- It covers reading, diffs, staging, commits, and GitHub PR review (`ttt . <pr-url>`), and is operable by mouse and touch, so a phone or tablet terminal works without modal key chords.
- Syntax highlighting is chroma, compiled into the binary, so there are no parsers to build and nothing like `tree-sitter` or Mason to keep current. The outline and symbol list come from LSP (`textDocument/documentSymbol`), so they appear only for languages with a server configured under `lsp.servers`; highlighting does not depend on that.
- Settings live in `ttt/settings.json`, linked file by file into `~/.config/ttt/` (a tracked `keybindings.json` is picked up the same way if one is added later). TTT rewrites that file with its complete settings whenever you change something in its settings UI, so the tracked copy is a full snapshot rather than a list of overrides, and a UI change overwrites what is tracked instead of merging with it. TTT also keeps its plugin state (`plugins.ttt.json`, `plugins/`) in that same directory, which is why the directory itself is not linked.
- Plugins are a manual step: install them from TTT's Plugins sidebar (`ctrl+k` then the Plugins panel) or with `Install from URL`. Provisioning them from a script would mean writing pre-granted permissions for third-party Lua into a state file TTT rewrites, which is not worth it for the one plugin in use (Markdown Preview, which is text-only).
- No image or mermaid rendering, deliberately: TTT draws no images, and a standalone reader (mermaid to PNG, pandoc, chawan) was built and dropped as not worth chawan, pandoc and a headless-browser mermaid CLI across two platforms. It is recoverable with `git show 660215f:bin/mdp` if that judgement changes.
- No automatic dark/light switching either: TTT carries one `theme` string with no appearance query, so the theme is whatever was last chosen with Switch Theme. The pair is `default-dark` and `default-light`.

### Deferred

Two things this setup does not do, both written up in `openspec/changes/switch-editor-to-ttt/design.md` so the next attempt starts from the measurement rather than a guess:

- **Markdown images and mermaid inside TTT.** TTT renders no images at all, so its markdown preview plugin is text-only. The first thing to measure is whether TTT's embedded terminal passes the Kitty graphics protocol through, since a nested terminal emulator eats it; that single test decides whether this is a plugin or a contribution to TTT's renderer.
- **Following the terminal's dark/light appearance.** TTT carries one `theme` string and no appearance query. `settings.reload` re-applies a theme live and `ttt --listen` accepts commands over HTTP, so an appearance hook could drive it; the obstacle is that `--listen` binds one fixed port, so several instances need assigned ports.

### Footprint

Measured on an Apple M5 with 32 GB of RAM, macOS 25.5, on 2026-09-11, after Neovim and lazygit were removed. Numbers are resident memory (RSS) and on-disk size, not virtual size. Reproduce them with the commands under each table; they are worth re-measuring rather than trusting, since every version bump moves them.

Editor startup, five runs through a real pty so the UI attaches:

| | command | time |
| --- | --- | --- |
| TTT | `script -q /dev/null ttt --exec "quit" .` | 20-60 ms, median 20 ms |
| Neovim, retired | `script -q /dev/null nvim --startuptime /dev/null -c 'qa!'` | 1220-1240 ms (unexplained: 161-174 ms in August) |

The Neovim row is what the setup being removed actually cost on the day it was removed, with its 29 `vim.pack` plugins installed. This table previously recorded 161-174 ms for the same command in August; that gap was not diagnosed, and both figures are kept rather than quietly replacing one with the other. TTT is a single Go binary with no plugin manager, so there is nothing equivalent to grow.

Resident memory per process, ranges across the instances that happened to be running (`ps -Ao rss,comm`; use `args` instead of `comm` to tell a herdr server from its client):

| process | RSS |
| ----------------- | -------------------------------- |
| Ghostty | 54 MB |
| `herdr`, server and client together | 14-30 MB each, 44 MB for the pair |
| `ttt` | 15-26 MB each |
| `claude` | 217-479 MB each, ~280 MB typical |
| `opencode` | 217 MB, one process per TUI |
| `codex` | not measured; its TUI would not stay resident long enough to sample, and no session was running |
| `wt` | none, it exits |

So the terminal plus the multiplexer is about 98 MB, and an editor adds roughly 20 MB per open tab. The shape of the conclusion has not changed with the editor swap: an agent is one to two orders of magnitude heavier than any tool it drives, and sixteen concurrent `claude` processes accounted for 4.6 GB against 155 MB for the entire terminal, multiplexer and editor stack beneath them.

On-disk, measured after `brew cleanup`, so each formula holds one version:

| | size |
| ---------------------------------------------- | --------------------------------------------------- |
| ttt | 14 MB |
| herdr | 21 MB |
| worktrunk | 22 MB |
| neovim binary, kept as a macOS-only escape hatch | 33 MB |
| codex | 272 MB |
| opencode | 137 MB |
| claude | 310 MB per version, more as legacy releases pile up |
| `~/.claude` (transcripts, skills, history) | 1.7 GB |
| `~/.local/share/opencode` | 1.7 GB |
| `~/.codex` | 238 MB |
| `~/.config/herdr` (logs, session state) | 35 MB |

**What the switch reclaimed:** 1.8 GB under `~/.local/share/nvim` (of which 1.3 GB was Mason packages, clangd and basedpyright alone accounting for most of it), 21 MB of nvim cache, 3.9 MB of nvim state, and the lazygit (18 MB), glow, difftastic (114 MB) and tree-sitter-cli binaries. Roughly 2 GB, and it removes the only part of the stack that grew without anyone deciding to grow it. The `neovim` binary stays in the Brewfile as an escape hatch for an edit TTT cannot do, so that hatch exists on macOS only: `linux.sh` no longer installs Neovim at all, and a remote box gets TTT and nothing else. What went either way is the configuration and the package tree that hung off it.

The tools themselves remain small; what grows is everything the agents cache. `~/.claude` and `~/.local/share/opencode` are 3.4 GB against well under 1 GB of binaries, and Claude Code self-updates into a new directory per release, so its share depends on how many legacy versions have piled up rather than on the size of one install.

Worktrees dominate everything else. `~/.herdr/worktrees` was 42 GB, because a single checkout of one React Native monorepo is 12-15 GB once its dependencies are installed, and each worktree gets its own copy. `wt step copy-ignored` uses APFS clonefile, so a fresh worktree costs almost nothing until files are modified, and `du` still reports the full size for each. Budget by repository, not by worktree count.

### Minimum requirements

Derived from the numbers above, for the full setup (herdr + an agent + TTT + worktrunk):

| RAM   | Concurrent agent streams | Notes                                                                                       |
| ----- | ------------------------ | ------------------------------------------------------------------------------------------- |
| 8 GB  | 1-2                      | The editor is no longer a factor; a second agent plus its dev server is what swaps.  |
| 16 GB | 4-6                      | Where parallel worktrees stop being the constraint.                                         |
| 32 GB | 10+                      | What the numbers above were measured on, with agents, editors and dev servers all resident. |

Disk: about 4.5 GB for the toolchain and agent state, of which 3.7 GB is agent caches and transcripts rather than binaries, then the installed size of one checkout of the repository multiplied by the number of live worktrees. Scale it to the toolchain, not the source: a React Native or Expo app is the expensive case, 10-15 GB per worktree, and almost all of it is prebuilt native modules and platform build artifacts rather than JS. A plain web or Node monorepo of comparable source size is a few hundred MB to 2 GB, and a Go or Rust repository less again.

CPU matters less than either. Agents are I/O and network bound while waiting on a model, so the practical ceiling is memory and disk, not cores.

### Happy hacking!

<img width="200" alt="image" src="https://media.tenor.com/y2JXkY1pXkwAAAAM/cat-computer.gif">
