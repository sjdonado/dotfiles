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

- `prefix+e` toggles a dedicated TTT tab in herdr: it opens on first press, focuses on the next, and returns you to the tab you came from when pressed inside it. Or run `ttt .` directly to open the current directory. herdr's own `edit_scrollback` sits on `prefix+shift+e`.
- Right-clicks in that tab reach TTT's own menu rather than herdr's pane menu. herdr has no config default for that, only per-pane state, so the local `ttt-tab` plugin sets it on the pane it opens and `panel-revive` re-asserts it after a session restore. Upstream's `ttt.editor` plugin is deliberately not used: it cannot route right-clicks and has no toggle-back.
- It covers reading, diffs, staging, commits, and GitHub PR review (`ttt . <pr-url>`), and is operable by mouse and touch, so a phone or tablet terminal works without modal key chords.
- Syntax highlighting is chroma, compiled into the binary, so there are no parsers to build and nothing like `tree-sitter` or Mason to keep current. The outline and symbol list come from LSP (`textDocument/documentSymbol`), so they appear only for languages with a server configured under `lsp.servers`; highlighting does not depend on that.
- Settings live in `ttt/settings.json`, linked file by file into `~/.config/ttt/` (a tracked `keybindings.json` is picked up the same way if one is added later). TTT rewrites that file with its complete settings whenever you change something in its settings UI, so the tracked copy is a full snapshot rather than a list of overrides, and a UI change overwrites what is tracked instead of merging with it. TTT also keeps its plugin state (`plugins.ttt.json`, `plugins/`) in that same directory, which is why the directory itself is not linked.
- Plugins are a manual step: install them from TTT's Plugins sidebar (`ctrl+k` then the Plugins panel) or with `Install from URL`. Provisioning them from a script would mean writing pre-granted permissions for third-party Lua into a state file TTT rewrites, which is not worth it for the one plugin in use (Markdown Preview, which is text-only).
- No image or mermaid rendering: TTT draws no images, so nothing here renders a diagram in the terminal. Doing it outside the editor costs chawan, pandoc and a headless-browser mermaid CLI on both platforms, which is more than it is worth.
- No automatic dark/light switching either: TTT carries one `theme` string with no appearance query, so the theme is whatever was last chosen with Switch Theme. The pair is `default-dark` and `default-light`.

### Deferred

Two things this setup does not do, both written up in `openspec/changes/switch-editor-to-ttt/design.md` so the next attempt starts from the measurement rather than a guess:

- **Markdown images and mermaid inside TTT.** TTT renders no images at all, so its markdown preview plugin is text-only. The first thing to measure is whether TTT's embedded terminal passes the Kitty graphics protocol through, since a nested terminal emulator eats it; that single test decides whether this is a plugin or a contribution to TTT's renderer.
- **Following the terminal's dark/light appearance.** TTT carries one `theme` string and no appearance query. `settings.reload` re-applies a theme live and `ttt --listen` accepts commands over HTTP, so an appearance hook could drive it; the obstacle is that `--listen` binds one fixed port, so several instances need assigned ports.

### Footprint

Measured on an Apple M5 with 32 GB of RAM, macOS 25.5, on 2026-09-11. Numbers are resident memory (RSS) and on-disk size, not virtual size. Reproduce them with the commands under each table; they are worth re-measuring rather than trusting, since every version bump moves them.

Editor startup, five runs through a real pty so the UI attaches:

| | command | time |
| --- | --- | --- |
| TTT | `script -q /dev/null ttt --exec "quit" .` | 20-60 ms, median 20 ms |

TTT is a single Go binary with no plugin manager, so there is nothing that grows with use: startup stays flat as the editor gets configured.

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
| neovim, macOS only, for an edit TTT cannot do | 33 MB |
| codex | 272 MB |
| opencode | 137 MB |
| claude | 310 MB per version, more as legacy releases pile up |
| `~/.claude` (transcripts, skills, history) | 1.7 GB |
| `~/.local/share/opencode` | 1.7 GB |
| `~/.codex` | 238 MB |
| `~/.config/herdr` (logs, session state) | 35 MB |

The editor is 14 MB and configures itself from one JSON file, so nothing accumulates underneath it: no plugin tree, no language-server package manager, no per-language parsers to build. What grows is everything the agents cache. `~/.claude` and `~/.local/share/opencode` are 3.4 GB against well under 1 GB of binaries, and Claude Code self-updates into a new directory per release, so its share depends on how many legacy versions have piled up rather than on the size of one install.

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
