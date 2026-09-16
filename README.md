> Blazingly Fast Development Setup 🚀

## Getting started

1. Clone this repo into `~/.config/dotfiles`

### Bootstrap

- macOS: run from the dotfiles directory: `./macos.sh`
- Linux (remote/dev box): `./linux.sh`
- Add `--install` to install or update dependencies (`./macos.sh --install` or `./linux.sh --install`). Without it, setup only updates directories, symlinks, and configuration.
- Update Brewfile: `/opt/homebrew/bin/brew bundle dump --describe --force --file=- > Brewfile`
- Tools come from `mise.toml`, linked to `~/.config/mise/config.toml`, on both platforms. Adding one is a line of TOML rather than an installer block in each script. Homebrew keeps the GUI applications and the macOS-only CLIs; three tools keep their own installers, and `mise.toml` says which and why.
- Verify a change to an installer before running it for real: `verify/linux/run.sh` provisions a throwaway Ubuntu container, `verify/macos/run.sh` runs `macos.sh --links-only` against a throwaway `HOME`. Both run twice and assert idempotency. See `verify/README.md`.

### Tool versions

`mise.toml` declares the cross-platform tools: the runtimes, the search tools, the editor, the worktree tool, and the agent CLIs that install cleanly. `mise.lock` records the version and per-platform checksum each machine resolved, so two boxes provisioned a month apart get the same tool set, and a locked resolve needs no GitHub API calls at all. The same file says which tools deliberately stay out and why: Claude Code's npm wrapper needs its postinstall step (mise skips it), herdr and moshi-hook ship from their own CDNs, fish and mosh are the login environment rather than project tooling, and rustup keeps rust because a mise shim would shadow `rust-toolchain.toml` pins.

`[bootstrap.packages]` and `[dotfiles]` in that file declare the rest, every Brewfile entry, the apt base, and all the links, but they are proven and not yet wired: the scripts still provision everything themselves, so editing one side without the other drifts them apart.

On macOS, Homebrew installs mise and its fish `vendor_conf.d` activates it, so nothing here touches `PATH`. On Linux the setup script puts `~/.local/share/mise/shims` on `PATH` instead of using `mise activate`, because shims work in any shell without a hook, which is what herdr's non-login panes get.

A machine provisioned before this still has the Homebrew copies of the tools mise took over (bat, node, fd, fzf, ripgrep, uv, worktrunk, lazygit, pnpm, bun, neovim, opencode, codex). The mise versions shadow them, so nothing breaks; clear them when convenient with `brew uninstall` for each.

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

Neovim, configured from `nvim/`, with the whole directory linked into `~/.config/nvim` so its plugin lockfile (`nvim-pack-lock.json`) is written back into this repository.

- `prefix+e` toggles a dedicated nvim tab in herdr: it opens on first press, focuses on the next, and returns you to the tab you came from when pressed inside it. Or run `nvim` directly. herdr's own `edit_scrollback` sits on `prefix+shift+e` to keep that key free.
- Plugins are managed by Neovim's own `vim.pack`, not a plugin manager: `:PackUpdate` updates and `:PackList` lists what is installed, replacing lazy.nvim's `:Lazy`. `:MasonToolsSync` installs the language servers and formatters the config declares.
- Git lives in the editor. `gitsigns` gives hunks and inline blame (`<leader>h*`) and `git-conflict` handles merge markers, while `lazygit` (`<leader>gg`) is the git surface itself: staging, commits, diffs, log, branches and rebase, in a floating window over the editor. It comes from `mise.toml` with the other cross-platform tools. There is no separate lazygit panel.
- Markdown is read as plain highlighted text: treesitter colours it, and there is deliberately no rendered preview. Neither `:Glow` nor render-markdown.nvim is installed.
- A herdr restart restores the tab as a bare shell, so `panel-revive` restarts nvim in it the first time that pane is focused.

### Default browser

Links are routed by [BrowserRouter](https://github.com/sjdonado/browser-router), its own repository now rather than a folder in here: it is the system default browser, matches every link against regexes and hands it to the browser that rule names. Nothing resident, no UI. Config reference and measured footprint are in that README.

What is local to this setup: the rules live at `macos/browser-router.json`, linked to `~/.config/browser-router/config.json`, so a routing change is a commit rather than a machine-local edit. Local dev servers and Cloudflare previews go to Helium, everything else to a Safari tab. `macos.sh` links that config and then rebuilds and re-registers the app on every run, non-interactively.

Making it the *default* browser is a system prompt, and so is letting it control Safari the first time. Neither can be answered by a script, which is why `macos.sh` passes `--no-default-prompt` and the first install is worth running by hand:

```sh
curl -fsSL https://raw.githubusercontent.com/sjdonado/browser-router/main/install.sh | sh
```

### Footprint

Measured on an Apple M5 with 32 GB of RAM, macOS 25.5, on 2026-09-11. Numbers are resident memory (RSS) and on-disk size, not virtual size. Reproduce them with the commands under each table; they are worth re-measuring rather than trusting, since every version bump moves them. The Neovim rows were re-measured on 2026-09-16, when it came back as the editor.

Resident memory per process, ranges across the instances that happened to be running (`ps -Ao rss,comm`; use `args` instead of `comm` to tell a herdr server from its client):

| process | RSS |
| ----------------- | -------------------------------- |
| Ghostty | 54 MB |
| `herdr`, server and client together | 14-30 MB each, 44 MB for the pair |
| `nvim` | ~30 MB per tab |
| `claude` | 217-479 MB each, ~280 MB typical |
| `opencode` | 217 MB, one process per TUI |
| `codex` | not measured; its TUI would not stay resident long enough to sample, and no session was running |
| `wt` | none, it exits |

So the terminal plus the multiplexer is about 98 MB, and an editor adds roughly 30 MB per open tab. An agent is one to two orders of magnitude heavier than any tool it drives, and sixteen concurrent `claude` processes accounted for 4.6 GB against 155 MB for the entire terminal, multiplexer and editor stack beneath them.

On-disk, measured after `brew cleanup`, so each formula holds one version:

| | size |
| ---------------------------------------------- | --------------------------------------------------- |
| neovim | 37 MB |
| herdr | 21 MB |
| worktrunk | 22 MB |
| lazygit | 18 MB |
| codex | 272 MB |
| opencode | 137 MB |
| claude | 310 MB per version, more as legacy releases pile up |
| `~/.claude` (transcripts, skills, history) | 1.7 GB |
| `~/.local/share/opencode` | 1.7 GB |
| `~/.codex` | 238 MB |
| `~/.config/herdr` (logs, session state) | 35 MB |

What grows is everything the agents cache. `~/.claude` and `~/.local/share/opencode` are 3.4 GB against well under 1 GB of binaries, and Claude Code self-updates into a new directory per release, so its share depends on how many legacy versions have piled up rather than on the size of one install.

Worktrees dominate everything else. `~/.herdr/worktrees` was 42 GB, because a single checkout of one React Native monorepo is 12-15 GB once its dependencies are installed, and each worktree gets its own copy. `wt step copy-ignored` uses APFS clonefile, so a fresh worktree costs almost nothing until files are modified, and `du` still reports the full size for each. Budget by repository, not by worktree count.

### Minimum requirements

Derived from the numbers above, for the full setup (herdr + an agent + nvim + worktrunk):

| RAM   | Concurrent agent streams | Notes                                                                                       |
| ----- | ------------------------ | ------------------------------------------------------------------------------------------- |
| 8 GB  | 1-2                      | A second agent plus its dev server is what swaps; the editor is not a factor. |
| 16 GB | 4-6                      | Where parallel worktrees stop being the constraint.                                         |
| 32 GB | 10+                      | What the numbers above were measured on, with agents, editors and dev servers all resident. |

Disk: about 4.5 GB for the toolchain and agent state, of which 3.7 GB is agent caches and transcripts rather than binaries, then the installed size of one checkout of the repository multiplied by the number of live worktrees. Scale it to the toolchain, not the source: a React Native or Expo app is the expensive case, 10-15 GB per worktree, and almost all of it is prebuilt native modules and platform build artifacts rather than JS. A plain web or Node monorepo of comparable source size is a few hundred MB to 2 GB, and a Go or Rust repository less again.

CPU matters less than either. Agents are I/O and network bound while waiting on a model, so the practical ceiling is memory and disk, not cores.

### Happy hacking!

<img width="200" alt="image" src="https://media.tenor.com/y2JXkY1pXkwAAAAM/cat-computer.gif">
