> Blazingly Fast Development Setup 🚀

## Getting started

1. Clone this repo into `~/.config/dotfiles`

### Bootstrap

- macOS: run from the dotfiles directory: `./macos.sh`
- Linux (remote/dev box): `./linux.sh`
- Add `--install` to install or update dependencies (`./macos.sh --install` or `./linux.sh --install`). Without it, setup only updates directories, symlinks, and configuration.
- Add a macOS package: `mise bootstrap packages use brew:<name>` (or `brew-cask:<name>`), then tag it `{ os = "macos" }` in `mise.toml`.
- Upgrade everything with `mise run upgrade`: Homebrew's index, the declared bootstrap packages (mise included), the `[tools]` versions, Neovim plugins and Mason tools. It replaces `brew update && brew upgrade`, which also upgrades undeclared leftovers and misses mise's tools. Review the `mise.lock` and `nvim/nvim-pack-lock.json` diffs afterwards.
- Tools come from `mise.toml`, linked to `~/.config/mise/config.toml`, on both platforms. Adding one is a line of TOML rather than an installer block in each script. `[bootstrap.packages]` in the same file lists the macOS formulae and casks, which `mise bootstrap` installs through Homebrew; three tools keep their own installers, and `mise.toml` says which and why.
- Verify a change to an installer before running it for real: `verify/linux/run.sh` provisions a throwaway Ubuntu container, `verify/macos/run.sh` runs `macos.sh --links-only` against a throwaway `HOME`. Both run twice and assert idempotency. See `verify/README.md`.

### Tool versions

`mise.toml` declares the cross-platform tools: the runtimes, the search tools, the editor, the worktree tool, and the agent CLIs that install cleanly. `mise.lock` records the version and per-platform checksum each machine resolved, so two boxes provisioned a month apart get the same tool set, and a locked resolve needs no GitHub API calls at all. The same file says which tools deliberately stay out and why: Claude Code's npm wrapper needs its postinstall step (mise skips it), herdr ships from its own CDN, fish and mosh are the login environment rather than project tooling, and rustup keeps rust because a mise shim would shadow `rust-toolchain.toml` pins.

`[bootstrap.packages]` is wired on macOS: `./macos.sh --install` runs `mise bootstrap --only packages,task`, which installs every formula and cask and then the go installs in `[tasks.bootstrap]`. There is no Brewfile. The apt entries and `[dotfiles]` are still advisory: linux.sh and lib/links.sh provision those themselves, so editing one side without the other drifts them apart.

On macOS, Homebrew installs mise and its fish `vendor_conf.d` activates it. The fish configuration also puts mise shims first so a legacy curl or Homebrew binary cannot override a managed tool. On Linux the setup script puts `~/.local/share/mise/shims` first on `PATH` instead of using `mise activate`, because shims work in any shell without a hook, which is what herdr's non-login panes get.

A machine provisioned before this still has the Homebrew copies of the tools mise took over (bat, node, fd, fzf, ripgrep, uv, worktrunk, lazygit, pnpm, bun, neovim, opencode, codex). The mise versions shadow them, so nothing breaks; clear them when convenient with `brew uninstall` for each.

### Agent harness

OpenCode is the primary agent for daily work. Claude Code, Codex, and Pi remain installed for experiments. The agents share skills and global instructions from `agents/`; the platform setup scripts link the managed configuration into each harness.

Authenticate OpenCode's provider with `/connect` or the CLI. The four configured MCP servers start automatically; authenticate any server that requires it:

```sh
opencode auth login
opencode mcp auth <server>
```

OpenCode defaults to hosted GPT-6.1 Sol through OpenAI, with native code mode, background shell jobs, built-in Terminals, animations, and all four MCP servers enabled at startup. LSP, automatic formatters, and snapshots are disabled. See `opencode/README.md` for setup and `agents/README.md` for harness details.

Experimental harness setup is documented in `agents/README.md` and `pi/README.md`. `pi-agent` also remains available for login and evals.

When experimenting with Codex, select the built-in `ansi` syntax theme with `/theme`. It uses the terminal's ANSI palette, so syntax colors follow Ghostty's live dark/light theme switch instead of staying pinned to a dark or light TextMate theme.

### Text editor

Neovim, configured from `nvim/`, with the whole directory linked into `~/.config/nvim` so its plugin lockfile (`nvim-pack-lock.json`) is written back into this repository.

- `prefix+e` toggles nvim as an overlay over the active pane: it opens on the first press and closes on the next, and closing restores the focus and zoom it covered. Or run `nvim` directly. herdr's own `edit_scrollback` sits on `prefix+shift+e` to keep that key free, and right-clicks inside the overlay reach the editor rather than herdr's pane menu.
- `prefix+l` toggles git-bug's termui the same way (macOS only: git-bug comes from `[bootstrap.packages]`). It refuses, with a message, outside a git repository or when no git-bug identity is active, so its first-run prompt never creates a stray identity; closing it frees git-bug's repository lock. herdr's `focus_pane_right` moves to `prefix+ctrl+l` (`prefix+shift+l` stays `swap_pane_right`).
- OpenCode drives a browser through agent-browser, https://github.com/vercel-labs/agent-browser. It comes from `mise.toml`, and the installers download the Chrome it drives with `agent-browser install`. `agent-browser/config.json` gives that Chrome a fixed profile directory, `~/.agent-browser/profile`, so the `chrome-devtools` MCP server can attach to the running browser for heap snapshots and performance traces instead of launching its own. That profile persists cookies and logins across agent sessions, unlike a per-launch temporary one. `opencode/opencode.json` registers both servers. For experiments with Claude Code or Codex, MCP registrations live in their own untracked config. If needed, remove the old `browser` server there (`claude mcp remove -s user browser`, `codex mcp remove browser`) and register both once, with `claude mcp add -s user` and `codex mcp add` followed by the same arguments: `agent-browser -- agent-browser mcp`, and `chrome-devtools -- npx -y chrome-devtools-mcp@latest --autoConnect --userDataDir ~/.agent-browser/profile --no-usage-statistics --no-performance-crux`.
- Plugins are managed by Neovim's own `vim.pack`, not a plugin manager: `:PackUpdate` updates and `:PackList` lists what is installed, replacing lazy.nvim's `:Lazy`. `:MasonToolsSync` installs the language servers and formatters the config declares.
- Git lives in the editor. `gitsigns` gives hunks and inline blame (`<leader>h*`) and `git-conflict` handles merge markers, while `lazygit` (`<leader>gg`) is the git surface itself: staging, commits, diffs, log, branches and rebase, in a floating window over the editor. It comes from `mise.toml` with the other cross-platform tools. There is no separate lazygit panel.
- Markdown is read as plain highlighted text: treesitter colours it, and there is deliberately no rendered preview. Neither `:Glow` nor render-markdown.nvim is installed.
- A herdr restart restores the tab as a bare shell, so `panel-revive` restarts nvim in it the first time that pane is focused.

### Default browser

Links are routed by [BrowserRouter](https://github.com/sjdonado/browser-router), its own repository now rather than a folder in here: it is the system default browser, matches every link against regexes and hands it to the browser that rule names. Nothing resident, no UI. Config reference and measured footprint are in that README.

What is local to this setup: the rules live at `macos/browser-router.json`, linked to `~/.config/browser-router/config.json`, so a routing change is a commit rather than a machine-local edit. Local dev servers and Cloudflare previews go to Helium, Linear, Slack, Notion and Google Workspace links (Meet, Calendar, Drive, Docs, Gmail) to the Search app, everything else to a Safari tab. `macos.sh` links that config, installs the app from the `sjdonado/tap` formula built from source, and registers the bundle with LaunchServices.

Making it the *default* browser is a system prompt, and so is letting it control Safari the first time. Neither can be answered by a script, which is why `macos.sh` stops at registration: the bundle is built and registered by then, and answering that prompt is the one step left.

```sh
open ~/Applications/BrowserRouter.app
```

### Footprint

Snapshot taken on an Apple M5 with 32 GiB of RAM and macOS 27.0.1 on 2026-10-10 at 10:51 UTC using OpenCode 2.0.26. These are historical measurements, not a benchmark of the newer pinned version. Memory values are resident memory (RSS), not virtual memory or peak usage. OpenCode processes were identified by their executable paths inside the current mise installation. Experimental agents are excluded from these tables.

| process | RSS at the snapshot |
| ----------------- | -------------------------------- |
| Ghostty | 95 MiB, one process |
| `herdr` | 29-43 MiB each, two processes |
| `nvim` | 5-22 MiB each, two processes |
| `opencode` | 164-684 MiB each, four processes |

OpenCode uses a shared server and separate clients, so process count is not the number of agent streams. Its row excludes separate MCP processes and project dev servers. RSS can count shared pages in more than one process; adding rows does not establish unique physical memory usage.

Inspect a fresh snapshot without dumping process arguments or environments:

```sh
ps -Ao pid,ppid,rss,comm
```

The RSS column from `ps` is in KiB; divide by 1024 for MiB.

The active tool packages and application state occupied the following space at the same snapshot. Package sizes include the current installed directory, not old Homebrew copies or package-manager caches.

| component | on-disk size |
| ---------------------------------------------- | ---------------- |
| neovim | 37 MiB |
| herdr | 23 MiB |
| worktrunk | 45 MiB |
| lazygit | 18 MiB |
| opencode | 177 MiB |
| `~/.local/share/opencode` | 8.6 GiB |
| `~/.config/herdr` | 65 MiB |

Re-measure installed package and state sizes with `du` (its output is in KiB):

```sh
for tool in npm:@opencode/cli github:neovim/neovim github:max-sixty/worktrunk github:jesseduffield/lazygit; do
  du -sk "$(mise where "$tool")"
done
du -sk "$(brew --prefix herdr)/" "$HOME/.local/share/opencode" "$HOME/.config/herdr"
```

The listed packages and state total about 9.0 GiB; OpenCode state accounts for most of it. MCP caches, the terminal application, experimental tools, and project checkouts are additional space.

### Capacity planning

Budget RAM for the shared OpenCode server, its clients, enabled MCP servers, the editor, and project processes. Measure the workload you run rather than deriving a stream limit from one RSS snapshot.

Budget disk per repository and its dependencies. Worktrees add another checkout and dependency tree. `wt step copy-ignored` uses APFS clonefile, which can share physical storage until files change; filesystem sharing means per-directory `du` totals are not always additive.

The default OpenAI model runs remotely, so local inference is not part of this setup's resource budget. Local builds, tests, dev servers, and MCP tools still need their own CPU and memory allowance.

### Happy hacking!

<img width="200" alt="image" src="https://media.tenor.com/y2JXkY1pXkwAAAAM/cat-computer.gif">
