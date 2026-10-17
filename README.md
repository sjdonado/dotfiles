> Blazingly Fast Development Setup 🚀

## Getting started

1. Clone this repo into `~/.config/dotfiles`

### Bootstrap

The whole workspace is declared in `flake.nix` and `nix/`: packages, GUI apps, links into this repository, macOS settings and the setup steps that are not packages. Every install, change and upgrade goes through that declaration. Nothing is installed with `brew`, `mise`, `npm -g`, `go install` or a curl installer by hand.

- macOS: `./macos.sh`. It installs Nix and the Xcode command line tools if they are missing, then switches to the configuration for this Mac's hostname (`darwinConfigurations` in `flake.nix`). Every step skips itself when already done, so the same command sets up a new Mac and re-applies the declaration later.
- Linux, on any distribution: `./linux.sh`, or `curl -fsSL https://raw.githubusercontent.com/sjdonado/dotfiles/main/linux.sh | bash` on a box without the clone. It installs Nix, clones this repository and runs the first `home-manager switch`. NixOS is not needed.
- Apply a change to the declaration: `nix run ~/.config/dotfiles#sync`. Nix reads this repository as a git flake, so a new file must be staged (`git add`) before a sync sees it.
- Upgrade everything: `nix run ~/.config/dotfiles#upgrade`. It updates every pinned input in `flake.lock` (nixpkgs, home-manager, nix-darwin, nix-homebrew and each Homebrew tap), then syncs. Review and commit the `flake.lock` diff. Both commands take `--dry-run`.
- Verify a change before it reaches a machine: `verify/linux.sh` provisions a throwaway Ubuntu container, `verify/macos.sh` evaluates or builds the macOS configuration without applying it, and `verify/macos-host.sh` asserts this Mac after a sync (`sudo -iu <user> ~/.config/dotfiles/verify/macos-host.sh` checks another account). See `verify/README.md`.

### Where things are declared

| what | where |
| --- | --- |
| command-line tools on both platforms, links, setup steps | `nix/home/common.nix` |
| shell files on Linux (`~/.profile`, `~/.bashrc`, `~/.zshenv`, `~/.zshrc`) | `nix/home/linux.nix` |
| macOS command-line tools, launch agents, macOS setup steps | `nix/home/darwin.nix` |
| macOS defaults, login shell, Nix settings | `nix/darwin/system.nix` |
| casks, the Homebrew formulas Nix lacks, taps (App Store apps are listed there, commented out) | `nix/darwin/homebrew.nix` |
| tools packaged here from their upstream binaries | `nix/pkgs/` |
| `sync` and `upgrade` | `nix/apps.nix` |

### Day to day

The repository is the source of truth. Configs reach it through live links, and everything else through `nix/` and a sync.

- Edit a config without a sync. Every tracked config (`~/.config/fish/config.fish`, Ghostty, Zed, `~/.gitconfig`, Claude Code's `settings.json`, OpenCode) is a link into this clone, so editing the file here or through its link is the same edit, and the tool reads it on its next start. Tools that write their own settings (Zed, OpenCode's `kv.json`, Pi) write into the repository, so their changes show up in `git status`. Commit them like code.
- Change what is installed or linked through `nix/`, then run `nix run ~/.config/dotfiles#sync`. That covers a tool, an app, a new config link, a macOS setting or a setup step.
  - A command-line tool: find its nixpkgs name with `nix search nixpkgs <name>`, then add it to `home.packages` in `nix/home/darwin.nix` (macOS only) or `nix/home/common.nix` (both platforms).
  - Only when nixpkgs lacks it: add it to `brews` in `nix/darwin/homebrew.nix`. A formula from a third-party tap also needs the tap, as a flake input in `flake.nix` and an entry in `nix-homebrew.taps`.
  - A GUI app: add its cask to `casks` in `nix/darwin/homebrew.nix`. GUI apps stay casks even when nixpkgs packages them, because casks install real bundles into /Applications, which Launch Services, Spotlight and Raycast index.
  - Removing works the same way: the sync uninstalls Homebrew formulas and casks the file does not list (`cleanup = "uninstall"`), but never deletes their app data.
- Do not run `brew install` or `brew tap` by hand, from any account. Homebrew has one writer: the sync, which runs `brew` as the primary user, who owns `/opt/homebrew`. A formula installed by hand is uninstalled by the next sync, the taps are a read-only link to the pinned inputs, and `brew update` is disabled.
- Upgrade with `nix run ~/.config/dotfiles#upgrade` and commit the `flake.lock` diff.
- Files Nix builds, such as `~/.local/bin/claude` and `~/.local/bin/codex`, change only through `nix/` and a sync.
- An app that saves by replacing a file (an atomic save) turns its link into a regular file, which then stops tracking the repository. `verify/macos-host.sh` reports it as "is not a link", and the next sync restores the link and keeps the replaced file as `<path>.pre-nix`.

### More than one account on a Mac

A Mac has one nix-darwin system, so every account on it is listed in `flake.nix`, in the `darwin [ ... ]` list for the Mac's hostname. Any number of accounts works the same way; this setup is used with two. The first is the primary user, who owns Homebrew and the system settings. One sync, run from any of these accounts, applies the configuration to all of them.

- Every account has its own clone at `~/.config/dotfiles`, and its links point into that clone. A config change reaches another account when that account runs `git pull`, with no sync.
- A sync applies the declaration from the clone it runs in, so `git pull` first.
- Packages live once in the shared `/nix/store`, readable by every account, which is why secrets stay outside Nix. `sudo nix-collect-garbage -d` frees what no account's generation still uses.
- To add an account: add it to the list in `flake.nix`, clone this repository into its `~/.config/dotfiles` on the same branch, sync, then check it with `sudo -iu <user> ~/.config/dotfiles/verify/macos-host.sh`. The sync sets its login shell to fish.

### Tool versions

`flake.lock` pins every input, so two machines switched from the same commit get the same versions. Most tools come from nixpkgs-unstable. Three come from their upstream release binaries, in `nix/pkgs/`: OpenCode, because nixpkgs still has v1; Codex, because nixpkgs builds it from source; and Claude Code on macOS, because nixpkgs trails its releases and T3 Code flags an older version as outdated (Linux uses nixpkgs). Two macOS tools come from Homebrew formulas, because nixpkgs lacks them: `browser-router` and `cliclick`. `gcloud-cli`'s six formula dependencies are listed too, because cleanup keeps the dependencies of listed formulas but not of casks. Homebrew itself is pinned by nix-homebrew, and every tap is a flake input, so a cask version moves only when `flake.lock` does. The exception is casks that update themselves (1Password, Chrome, Slack, Zed): they can move ahead of the pin between switches.

Homebrew kept some versions off PATH (keg-only) because they share command names with the default version. Those are linked under `~/.local/opt/` instead: `jdk11`, `jdk17`, `llvm`, `openssl-4`, `zig-0_15`. GNU tools that would shadow the macOS ones keep Homebrew's names: `gsed`, `gawk`, the `g`-prefixed coreutils, and `telnet` alone from inetutils.

### Manual steps

The sync cannot do these. Everything else is declared.

- Choose default apps by hand, in each account: a file's Get Info, then Open with, then Change All. `duti` exits successfully but changes nothing on macOS 26 and later, so `macos/default-apps.duti` records the intent only.
- Install App Store apps by hand from the App Store. Their IDs stay listed, commented out, under `masApps` in `nix/darwin/homebrew.nix`; uncommenting them makes the sync install them, which needs an App Store sign-in.
- Open `~/Applications/BrowserRouter.app` once and accept it as the default browser.
- The Safari web apps (Gmail, Calendar, Google Meet) are created in Safari with File > Add to Dock. BrowserRouter routes to them by the IDs Safari generates, so a new web app needs its ID updated in `macos/browser-router.json`.
- Anarlog Dev is a local build, Claude Code URL Handler is created by Claude Code, and Safari is part of macOS.
- Secrets and logins, in each account: `.env` values, SSH keys and tool logins (OpenCode providers and MCP servers, Claude Code, Codex, `gh`).
- On a Linux box without systemd (a container or a typical Coder workspace), nothing restarts the Nix daemon after a restart. Run `linux.sh` again, which Coder does on workspace start.

### Agent harness

OpenCode is the primary agent for daily work. Claude Code, Codex, and Pi remain installed for experiments. The agents share skills and global instructions from `agents/`; the sync links the managed configuration into each harness.

Authenticate OpenCode's provider with `/connect` or the CLI. The two configured MCP servers (ios-simulator, git-bug) start automatically; authenticate any server that requires it:

```sh
opencode auth login
opencode mcp auth <server>
```

OpenCode defaults to hosted GPT-6.1 Sol through OpenAI, with native code mode, background shell jobs, built-in Terminals, animations, and both MCP servers enabled at startup. LSP, automatic formatters, and snapshots are disabled. See `opencode/README.md` for setup and `agents/README.md` for harness details.

Experimental harness setup is documented in `agents/README.md` and `pi/README.md`. `pi-agent` also remains available for login and evals.

When experimenting with Codex, select the built-in `ansi` syntax theme with `/theme`. It uses the terminal's ANSI palette, so syntax colors follow Ghostty's live dark/light theme switch instead of staying pinned to a dark or light TextMate theme.

### Text editor

The editor is Zed, used with T3 Code. Neovim is installed plain, without `nvim/`, as `$EDITOR` for git. The full Neovim setup (the configuration in `nvim/`, its language servers and formatters, lazygit and tree-sitter) and herdr (`herdr/`) are commented out in `nix/home/common.nix`, ready to restore by uncommenting them and syncing.

### Default browser

Links are routed by [BrowserRouter](https://github.com/sjdonado/browser-router), its own repository now rather than a folder in here: it is the system default browser, matches every link against regexes and hands it to the browser that rule names. Nothing resident, no UI. Config reference and measured footprint are in that README.

What is local to this setup: the rules live at `macos/browser-router.json`, linked to `~/.config/browser-router/config.json`, so a routing change is a commit rather than a machine-local edit. Local dev servers and Cloudflare previews go to Helium. Linear links go to the Linear app. Gmail, Calendar and Google Meet go to their Safari web apps. Everything else goes to a Safari tab. The sync links that config, installs the app from the `sjdonado/tap` formula built from source, and registers the bundle with LaunchServices.

Making it the *default* browser is a system prompt, and so is letting it control Safari the first time. Neither can be answered by a script, which is why the sync stops at registration: the bundle is built and registered by then, and answering that prompt is the one step left.

```sh
open ~/Applications/BrowserRouter.app
```

### Footprint

These resident-memory (RSS) readings illustrate a workload, not a fixed per-agent RAM requirement or a benchmark of the current version:

| process | RSS at the snapshot |
| ----------------- | -------------------------------- |
| Ghostty | 95 MiB, one process |
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
| worktrunk | ~50 MiB |
| opencode | ~200 MiB |
| `~/.local/share/opencode` | ~9 GiB, growing with conversation history |

Inspect installed package sizes with `nix path-info` and state sizes with `du` (its output is in KiB):

```sh
for tool in opencode nvim wt; do
  nix path-info -Sh "$(readlink -f "$(command -v "$tool")" | cut -d/ -f1-4)"
done
du -sk "$HOME/.local/share/opencode" "$HOME/.cache/opencode"
```

OpenCode's data directory includes its conversation database, not just disposable caches. Do not delete the database, its WAL/SHM files, authentication files or service registration to reclaim space. Back up persistent state before investigating database growth; plan cache cleanup separately from history retention. Troubleshooting reference: https://opencode.ai/v2/docs/troubleshooting

### Capacity planning

Budget RAM for the shared OpenCode server, its clients, enabled MCP servers, the editor, and project processes. Measure the workload you run rather than deriving a stream limit from one RSS snapshot.

Budget disk per repository and its dependencies. Worktrees add another checkout and dependency tree. `wt step copy-ignored` uses APFS clonefile, which can share physical storage until files change; filesystem sharing means per-directory `du` totals are not always additive.

The default OpenAI model runs remotely, so local inference is not part of this setup's resource budget. Local builds, tests, dev servers, and MCP tools still need their own CPU and memory allowance.

### Happy hacking!

<img width="200" alt="image" src="https://media.tenor.com/y2JXkY1pXkwAAAAM/cat-computer.gif">
