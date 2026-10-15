> Blazingly Fast Development Setup 🚀

## Getting started

1. Clone this repo into `~/.config/dotfiles`

### Bootstrap

The whole workspace is declared in `flake.nix` and `nix/`: packages, GUI apps, App Store apps, links into this repository, macOS settings and the setup steps that are not packages. Every install, change and upgrade goes through that declaration. Nothing is installed with `brew`, `mise`, `npm -g`, `go install` or a curl installer by hand.

- macOS: `./macos.sh`. It installs Nix and the Xcode command line tools if they are missing, then switches to the configuration for this Mac's hostname (`darwinConfigurations` in `flake.nix`). Every step skips itself when already done, so the same command sets up a new Mac and re-applies the declaration later.
- Linux, on any distribution: `./linux.sh`, or `curl -fsSL https://raw.githubusercontent.com/sjdonado/dotfiles/main/linux.sh | bash` on a box without the clone. It installs Nix, clones this repository and runs the first `home-manager switch`. NixOS is not needed.
- Apply a change to the declaration: `nix run ~/.config/dotfiles#switch`. Nix reads this repository as a git flake, so a new file must be staged (`git add`) before a switch sees it.
- Upgrade everything: `nix run ~/.config/dotfiles#upgrade`. It updates every pinned input in `flake.lock` (nixpkgs, home-manager, nix-darwin, nix-homebrew and each Homebrew tap), updates the Neovim plugins in `nvim/nvim-pack-lock.json`, then switches. Review and commit both lockfile diffs. Both commands take `--dry-run`.
- Verify a change before it reaches a machine: `verify/linux.sh` provisions a throwaway Ubuntu container, `verify/macos.sh` evaluates or builds the macOS configuration without applying it, and `verify/macos-vm.sh` runs `macos.sh` in a disposable macOS VM. See `verify/README.md`.

### Where things are declared

| what | where |
| --- | --- |
| command-line tools on both platforms, links, setup steps | `nix/home/common.nix` |
| shell files on Linux (`~/.profile`, `~/.bashrc`, `~/.zshenv`, `~/.zshrc`) | `nix/home/linux.nix` |
| macOS command-line tools, launch agents, macOS setup steps | `nix/home/darwin.nix` |
| macOS defaults, login shell, Nix settings | `nix/darwin/system.nix` |
| casks, the Homebrew formulas Nix lacks, App Store apps, taps | `nix/darwin/homebrew.nix` |
| tools packaged here from their upstream binaries | `nix/pkgs/` |
| `switch` and `upgrade` | `nix/apps.nix` |

Add a command-line tool by adding its nixpkgs name to the right package list, then switch. Add a GUI app by adding its cask to `nix/darwin/homebrew.nix`. GUI apps stay casks even when nixpkgs packages them, because casks install real bundles into /Applications, which Launch Services, Spotlight and Raycast index. The switch uninstalls Homebrew formulas and casks the file does not list (`cleanup = "uninstall"`), but never deletes their app data.

### Tool versions

`flake.lock` pins every input, so two machines switched from the same commit get the same versions. Most tools come from nixpkgs-unstable. Two come from their upstream release binaries, in `nix/pkgs/`: OpenCode, because nixpkgs still has v1, and Codex, because nixpkgs builds it from source. Three macOS tools come from Homebrew formulas, because nixpkgs lacks them: `browser-router`, `cliclick` and `mole`. Homebrew itself is pinned by nix-homebrew, and every tap is a flake input, so a cask version moves only when `flake.lock` does. The exception is casks that update themselves (1Password, Chrome, Slack, Zed): they can move ahead of the pin between switches.

Homebrew kept some versions off PATH (keg-only) because they share command names with the default version. Those are linked under `~/.local/opt/` instead: `jdk11`, `jdk17`, `llvm`, `openssl-4`, `zig-0_15`. GNU tools that would shadow the macOS ones keep Homebrew's names: `gsed`, `gawk`, the `g`-prefixed coreutils, and `telnet` alone from inetutils.

### Manual steps

The switch cannot do these. Everything else is declared.

- Sign in to the App Store before the first macOS switch, so the App Store apps install. Removing an App Store app from `nix/darwin/homebrew.nix` does not uninstall it: delete the app by hand.
- Open `~/Applications/BrowserRouter.app` once and accept it as the default browser.
- The Safari web apps (Gmail, Calendar, Google Meet) are created in Safari with File > Add to Dock. BrowserRouter routes to them by the IDs Safari generates, so a new web app needs its ID updated in `macos/browser-router.json`.
- Anarlog Dev is a local build, Claude Code URL Handler is created by Claude Code, and Safari is part of macOS.
- Secrets: `.env` values, SSH keys and tool logins (OpenCode providers and MCP servers, Claude Code, Codex, `gh`).
- On a Linux box without systemd (a container or a typical Coder workspace), nothing restarts the Nix daemon after a restart. Run `linux.sh` again, which Coder does on workspace start.
- On Linux, the Chrome agent-browser downloads needs system libraries the switch does not install, because a switch changes nothing outside Nix. Install them once with `agent-browser install --with-deps`, which uses the distribution's package manager through sudo. There is no Chrome for Linux arm64 at all.

### Agent harness

OpenCode is the primary agent for daily work. Claude Code, Codex, and Pi remain installed for experiments. The agents share skills and global instructions from `agents/`; the switch links the managed configuration into each harness.

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
- `prefix+l` toggles git-bug's termui the same way (macOS only: git-bug is in `nix/home/darwin.nix`). It refuses, with a message, outside a git repository or when no git-bug identity is active, so its first-run prompt never creates a stray identity; closing it frees git-bug's repository lock. herdr's `focus_pane_right` moves to `prefix+ctrl+l` (`prefix+shift+l` stays `swap_pane_right`).
- OpenCode drives a browser through agent-browser, https://github.com/vercel-labs/agent-browser. It is declared in `nix/home/common.nix`, and the switch downloads the Chrome it drives with `agent-browser install`. `agent-browser/config.json` gives that Chrome a fixed profile directory, `~/.agent-browser/profile`, so the `chrome-devtools` MCP server can attach to the running browser for heap snapshots and performance traces instead of launching its own. That profile persists cookies and logins across agent sessions, unlike a per-launch temporary one. `opencode/opencode.json` registers both servers. For experiments with Claude Code or Codex, MCP registrations live in their own untracked config. If needed, remove the old `browser` server there (`claude mcp remove -s user browser`, `codex mcp remove browser`) and register both once, with `claude mcp add -s user` and `codex mcp add` followed by the same arguments: `agent-browser -- agent-browser mcp`, and `chrome-devtools -- npx -y chrome-devtools-mcp@latest --autoConnect --userDataDir ~/.agent-browser/profile --no-usage-statistics --no-performance-crux`.
- Plugins are managed by Neovim's own `vim.pack`, not a plugin manager: `:PackUpdate` updates and `:PackList` lists what is installed, replacing lazy.nvim's `:Lazy`. The language servers and formatters come from Nix (`nix/home/common.nix`) and resolve from PATH; there is no Mason.
- Git lives in the editor. `gitsigns` gives hunks and inline blame (`<leader>h*`) and `git-conflict` handles merge markers, while `lazygit` (`<leader>gg`) is the git surface itself: staging, commits, diffs, log, branches and rebase, in a floating window over the editor. It is declared in `nix/home/common.nix` with the other cross-platform tools. There is no separate lazygit panel.
- Markdown is read as plain highlighted text: treesitter colours it, and there is deliberately no rendered preview. Neither `:Glow` nor render-markdown.nvim is installed.
- A herdr restart restores the tab as a bare shell, so `panel-revive` restarts nvim in it the first time that pane is focused.

### Default browser

Links are routed by [BrowserRouter](https://github.com/sjdonado/browser-router), its own repository now rather than a folder in here: it is the system default browser, matches every link against regexes and hands it to the browser that rule names. Nothing resident, no UI. Config reference and measured footprint are in that README.

What is local to this setup: the rules live at `macos/browser-router.json`, linked to `~/.config/browser-router/config.json`, so a routing change is a commit rather than a machine-local edit. Local dev servers and Cloudflare previews go to Helium. Linear links go to a Pake app built from `pake/` (see `pake/README.md`). Slack, Notion and Google Workspace links (Meet, Calendar, Drive, Docs, Gmail) go to the Search app. Everything else goes to a Safari tab. The switch links that config, installs the app from the `sjdonado/tap` formula built from source, and registers the bundle with LaunchServices.

Making it the *default* browser is a system prompt, and so is letting it control Safari the first time. Neither can be answered by a script, which is why the switch stops at registration: the bundle is built and registered by then, and answering that prompt is the one step left.

```sh
open ~/Applications/BrowserRouter.app
```

### Footprint

These resident-memory (RSS) readings illustrate a workload, not a fixed per-agent RAM requirement or a benchmark of the current version:

| process | RSS at the snapshot |
| ----------------- | -------------------------------- |
| Ghostty | 95 MiB, one process |
| `herdr` | 29-43 MiB each, two processes |
| `nvim` | 5-22 MiB each, two processes |
| `opencode` | 164-684 MiB each, four processes |

Disk usage and RAM usage are different budgets. OpenCode uses a shared server and separate clients, so process count is not the number of agent streams. MCP processes, browsers and project dev servers add their own resource use.

Inspect current resident memory without dumping process arguments or environments:

```sh
ps -Ao pid,ppid,rss,comm
```

The RSS column from `ps` is in KiB; divide by 1024 for MiB.

RSS can count shared pages in more than one process, so adding rows does not establish unique physical memory usage. Measure your active workload rather than assuming a fixed per-agent RAM cost.

Use these rounded disk sizes as approximate guidance. Installed versions, history and caches change with use; package figures exclude old installations and package-manager caches.

| component | approximate on-disk size |
| ---------------------------------------------- | ---------------- |
| neovim | ~40 MiB |
| herdr | ~25 MiB |
| worktrunk | ~50 MiB |
| lazygit | ~20 MiB |
| opencode | ~200 MiB |
| `~/.local/share/opencode` | ~9 GiB, growing with conversation history |
| `~/.config/herdr` | ~70 MiB |

Inspect installed package sizes with `nix path-info` and state sizes with `du` (its output is in KiB):

```sh
for tool in opencode nvim wt lazygit herdr; do
  nix path-info -Sh "$(readlink -f "$(command -v "$tool")" | cut -d/ -f1-4)"
done
du -sk "$HOME/.local/share/opencode" "$HOME/.cache/opencode" "$HOME/.config/herdr"
```

OpenCode's data directory includes its conversation database, not just disposable caches. Do not delete the database, its WAL/SHM files, authentication files or service registration to reclaim space. Back up persistent state before investigating database growth; plan cache cleanup separately from history retention. Troubleshooting reference: https://opencode.ai/v2/docs/troubleshooting

### Capacity planning

Budget RAM for the shared OpenCode server, its clients, enabled MCP servers, the editor, and project processes. Measure the workload you run rather than deriving a stream limit from one RSS snapshot.

Budget disk per repository and its dependencies. Worktrees add another checkout and dependency tree. `wt step copy-ignored` uses APFS clonefile, which can share physical storage until files change; filesystem sharing means per-directory `du` totals are not always additive.

The default OpenAI model runs remotely, so local inference is not part of this setup's resource budget. Local builds, tests, dev servers, and MCP tools still need their own CPU and memory allowance.

### Happy hacking!

<img width="200" alt="image" src="https://media.tenor.com/y2JXkY1pXkwAAAAM/cat-computer.gif">
