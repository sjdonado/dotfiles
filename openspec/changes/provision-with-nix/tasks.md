# Tasks

## 0. Done in proto (folded from .agent/main.tasks.md)

- [x] 0.1 flake.nix with nixpkgs and home-manager inputs and a Linux home configuration; 12 tools and 4 live links; `verify/nix/linux.sh` switched twice in nixos/nix:2.28.3 on aarch64 with the second switch keeping generation 1
- [x] 0.2 Availability check of every Homebrew formula, cask, mise tool and installer tool against nixpkgs 8edc0c72e3 for aarch64-darwin, with homepage identity and cache checks (`.agent/main.nix-map.tsv`)
- [x] 0.3 Apps in /Applications outside Homebrew listed: 11 with casks, 13 from the App Store, 4 not declarable

## 1. Flake skeleton

- [x] 1.1 Restructure the proto into the decision 1 layout (`nix/home/common.nix`, `nix/home/linux.nix`, `nix/home/darwin.nix`, `nix/darwin/system.nix`, `nix/darwin/homebrew.nix`), add nix-darwin and nix-homebrew inputs and every Homebrew tap as a non-flake input, and verify `nix flake show` (in the container) lists `darwinConfigurations`, both `homeConfigurations` and `apps.*.upgrade`
- [x] 1.2 Move the availability map into `openspec/changes/provision-with-nix/coverage.tsv` with one row per pre-change item and its declared source or named exception, and verify every row of `brew leaves`, `brew list --cask`, the mise `[tools]` and the installer tools on this Mac appears in it

## 2. Shared home module

- [x] 2.1 Declare every command-line package from coverage.tsv in `home/common.nix` (nixpkgs names from decision 4, `allowUnfree`), and verify the evaluation script reports each as available and prebuilt for aarch64-darwin, aarch64-linux and x86_64-linux, listing the ones a platform lacks
  - Done as the package check, now in `verify/macos.sh`: all three platforms evaluate, every package is prebuilt except the ones built locally by design (nix/pkgs, claude-code, the `only` wrappers, home-manager's generated files), and no two packages provide the same file. The macOS formula set went to `home/darwin.nix`, not `home/common.nix`, so Linux boxes keep the shared tool set (design decision 4).
- [x] 2.2 Declare every link `lib/links.sh` and the `[dotfiles]` table create as live links (decision 7), including per-file links for fish functions, ~/.local/bin, ghostty themes and bat themes, and verify with the Linux check that each resolves into the working tree
- [x] 2.3 Add the activation steps from decision 8 that apply to both platforms (herdr integrations and plugins, codex-config apply, bat cache, pss from a pinned input, agent-browser install, nvim plugin restore, fish history), each reporting its own failure, and verify with the Linux check that a run without a herdr server reports the herdr step as skipped and completes the rest
- [x] 2.4 ~~Move the Mason tools to Nix packages~~ Superseded: neovim is a plain editor for git (owner's decision, 2026-10-17); the language servers, formatters, lazygit, tree-sitter, the `nvim` link and the plugin step are commented out in `nix/home/common.nix`, and the checks skip them. Original task: Move the Mason tools to Nix packages (decision 9): check each nixpkgs name with the evaluation script, add them to `home/common.nix`, remove mason.nvim and mason-tool-installer from `nvim/init.lua`, and verify in the Linux check that `nvim --headless` starts without errors and each server binary answers `--version`
  - The packages are declared and answer in the Linux check (a version command, or an LSP initialize request for the five servers with no version flag). Removing Mason from `nvim/init.lua` waits for group 7: this Mac's nvim finds its servers through Mason until the first switch puts the Nix ones on PATH.

## 3. Linux

- [x] 3.1 Write `home/linux.nix` (decision 11: rc files with PATH, git-identity unset, `ulimit -c 0`, `exec fish` hand-off, login shell untouched) and verify in the Linux check that `env -i HOME=$HOME bash -lc 'nvim --version'` and an interactive bash both resolve tools and that a second switch duplicates no block
- [x] 3.2 Rewrite the Linux check (now `verify/linux.sh`) for decision 12 (Ubuntu image, the Determinate installer installing upstream Nix, `home-manager switch` twice, assertions from the provisioning-verification spec), delete `verify/nix/`, and verify it passes on aarch64 and with `--platform linux/amd64`
  - aarch64 109 passed and amd64 110 passed, each on both runs, with upstream Nix 2.35.3 (the installer needs `--prefer-upstream-nix`; without it v3.23.2 installs Determinate Nix). Without systemd the installer is root-only, so linux.sh starts the daemon. Each check copies only the files in git's index, as the git flake sees them.
- [x] 3.3 Reduce `linux.sh` to installing Nix and running the first switch, and verify the Linux check runs it unmodified as its entry point
- [x] 3.4 Update `verify/README.md` and the Linux parts of `README.md` and `CLAUDE.md` (Verification, "Verifying a setup change"), and verify every command they quote runs as written
  - Linux parts: linux.sh, the verify scripts and `nix run .#sync`/`.#upgrade -- --dry-run` ran as quoted. The macOS commands (macos.sh, verify/macos-vm) run in groups 5 and 6.

## 4. macOS configuration

- [x] 4.1 Write `darwin/homebrew.nix`: nix-homebrew with `autoMigrate` and pinned taps, the three formulas, all casks (23 current plus the 11 hand-installed apps), the 13 App Store apps by ID, `cleanup = "none"` for now, and verify every cask and App Store ID resolves (`brew info --cask`, `mas info`)
  - 34/34 casks and 3/3 formulas resolve with `brew info`; the 13 App Store IDs resolve through the App Store lookup API (`mas` is not installed). T3 Code joined the casks; the legacy iWork Keynote bundle has no listing and is a named exception.
- [x] 4.2 Write `darwin/system.nix`: Nix settings, `programs.fish` and `programs.zsh`, `environment.shells`, the guarded login-shell step, `system.defaults` from `macos/defaults.sh`, `CustomUserPreferences` from `macos/app-shortcuts.sh`, and verify the generated activation script contains each setting
  - App shortcuts run `macos/app-shortcuts.sh` as a step instead of `CustomUserPreferences` (design decision 8).
- [x] 4.3 Write `home/darwin.nix`: launch agents as `launchd.agents`, duti, keyboard layouts (copied), BrowserRouter copy and `lsregister`, `.ssh/config`, Docker config, `.hushlogin`, and verify the built home generation contains each file and agent
  - Verified on the evaluated configuration by `verify/macos.sh`; the build itself happens in the VM rehearsal (5.1).
- [x] 4.4 Rewrite the macOS fast loop (now `verify/macos.sh`) as the fast loop from decision 12 (build without activating) and verify it passes in the container or on the host once Nix is present
  - Container path: 68 passed, 0 failed.
- [x] 4.5 Add `apps.upgrade` (`nix flake update`, nvim plugin update into the tracked lockfile, then the platform switch) and verify `nix run .#upgrade -- --dry-run` prints the steps without changing anything
  - Also `apps.sync`, which the installers and `upgrade` use. Dry runs checked in a Linux container; flake.lock and nvim-pack-lock.json unchanged.

## 5. VM rehearsal (dropped 2026-10-17)

- [x] 5.0 Simplify `verify/` to one self-contained script per check (`verify/linux.sh`, `verify/macos.sh`, `verify/macos-vm.sh`, plus `verify/README.md`), drop `macos.sh --nix-only` so `macos.sh` is one script whose steps skip themselves, and get tart for the VM check from its pinned release instead of from Nix on this Mac; verify the Linux check on both architectures and the macOS fast loop pass
  - verify/linux.sh: aarch64 109/0 and amd64 110/0 on both runs. verify/macos.sh: 68/0, and the macOS (128) and both Linux (53) profiles available, prebuilt and collision-free. The VM check's tart download and guest steps run in 5.1.
- [x] 5.1 ~~Run `verify/macos-vm.sh`~~ Passed 160/160 on both runs (guest macOS 26.6.2), then dropped at the owner's request: `verify/macos-vm.sh` and `darwinConfigurations.verify-vm` are deleted, and its assertions became the read-only `verify/macos-host.sh`, run on this Mac after a switch. Original task: Run `verify/macos-vm.sh` (DARWIN_CONFIG=verify-vm, `macos.sh` twice, the spec assertions) and verify a full run passes, recording the guest macOS version

## 6. First switch on this Mac (owner approval required)

- [x] 6.1 Ask the owner to approve running `./macos.sh` on this Mac after `verify/macos.sh` passed for the same working tree; on approval run it (it installs upstream Nix, hands a non-stock /etc/shells to nix-darwin as /etc/shells.before-nix-darwin, hands a real /opt/homebrew/Library/Taps to nix-homebrew as Taps.pre-nix, and switches with `cleanup = "none"`) and verify every assertion of the provisioning-verification spec on the host, including `verify/macos.sh` building the system
  - Ran 2026-10-17 by the owner after `verify/macos.sh` passed. First attempt failed on two cask conflicts (libreoffice, notion) and was interrupted during App Store installs; the owner dropped those casks and the App Store apps, and the second run switched. `verify/macos-host.sh`: 155 passed, 0 failed.
- [x] 6.2 Compare declared lists with `brew list`, `mas list` and /Applications, resolve every difference in the declaration, set `cleanup = "uninstall"`, switch again, and verify the installed set equals the declared set and a third switch changes nothing
  - 2026-10-17: compared `brew list` with the declaration; every undeclared formula has a Nix replacement in coverage.tsv or was dropped by the owner (lazygit, mole, herdr), and the undeclared casks (codex, firefox, notion, search, orion) were dropped by the owner, who approved `cleanup = "uninstall"`. The switch uninstalled the five casks, but `brew bundle` refused the formula batch because six are `gcloud-cli` dependencies, and could not remove formulas whose taps are gone (bun, Ory cli, gcx, idb-companion, supabase) or 44 empty Cellar folders holding only a mise `.mise-staging.lock`. Those were removed by name. Result: `brew list --cask` equals the 29 declared casks, the formulas are `browser-router`, `cliclick` and the six `gcloud-cli` dependencies, and `verify/macos-host.sh` passes 156/0.

## 7. Remove the old layer

- [x] 7.1 Delete `mise.toml`, `mise.lock`, `lib/links.sh`, `~/.config/mise`, `~/.local/share/mise` and every mise reference on PATH or in configs (`fish/config.fish`, `herdr/config.toml`, `bin/`, the nvim comment), remove the `~/.config/mise/{config.toml,mise.lock}` links, remove Mason from `nvim/init.lua` (task 2.4; until then mason.setup prepends its bin directory to PATH), put `~/.local/bin`, `~/.opencode/bin`, `~/.bun/bin` and `/opt/homebrew/bin` after the Nix profile in `fish/config.fish` and assert in both checks that `claude` resolves into the Nix profile, drop `/opt/homebrew/lib/docker/cli-plugins` from `docker/config.json`, and remove `~/.local/bin/claude` left by the curl installer, and verify `rg -n 'mise' --glob '!openspec/**'` finds nothing outside history and that both checks still pass
  - Done 2026-10-17: mise.toml and mise.lock deleted, ~/.config/mise, ~/.local/share/mise, ~/.local/state/mise and the mise Cellar removed, the mise PATH line gone from fish/config.fish (Homebrew, ~/.local/bin and the rest appended after Nix, and the Nix profiles moved back to the front as the last line), the universal fish_user_paths cleared, ~/.local/bin/claude and ~/.local/bin/codex declared as links to the Nix builds (GUI apps such as T3 Code look there with the PATH they launched with; removing the curl link broke T3 Code), Mason removed (its root-owned remainder needs `sudo rm -rf ~/.local/share/nvim/mason`). `docker/config.json` no longer lists `/opt/homebrew/lib/docker/cli-plugins` (OrbStack links its own plugins into `~/.docker/cli-plugins`). verify/macos-host.sh asserts claude and codex resolve to /nix/store on PATH and in ~/.local/bin.
- [x] 7.2 Reduce `macos.sh` to installing Nix and running the first switch, and verify `verify/macos-host.sh` passes after it
  - `macos.sh` installs Nix (and the Xcode command line tools when missing), hands a non-stock `/etc/shells` and a real Homebrew `Taps` directory to nix-darwin, and switches; nothing else. It switched this Mac on 2026-10-17, and `verify/macos-host.sh` passes after it (primary account 162/0).
- [x] 7.3 Write the named exceptions and manual steps (Safari web apps and their BrowserRouter IDs, Anarlog Dev, Claude Code URL Handler, Safari, App Store sign-in, secrets, tool logins) into `README.md`, and update the macOS parts of `README.md` and `CLAUDE.md`, and verify every command they quote runs as written
  - 2026-10-17: README covers the day-to-day workflow (config edits through live links without a sync, `nix/` edits with `nix run .#sync`, nixpkgs before `brews`, taps as flake inputs, no `brew install` or `brew tap` by hand), more than one account on a Mac, current tool versions, and the manual steps (default apps per account, App Store apps, BrowserRouter, Safari web apps, the named exceptions, secrets and logins per account). `homebrew/macos-multi-user.md` is deleted: the sync is the only Homebrew writer, and `/opt/homebrew` is owned by the primary user (`sudo chown -R <primary user>:admin /opt/homebrew`). `umask 002`, which existed for shared Homebrew writes, is gone from `fish/config.fish`. The Raycast wrapper guide moved to `macos/` with Nix profile paths, and `/Applications/scrcpy.app` was relinked to the Nix profile of the account that built it. Quoted commands checked: `nix run .#sync -- --dry-run`, `nix run .#upgrade -- --dry-run`, `nix search nixpkgs`, the verify scripts; `sudo nix-collect-garbage -d` was not run.

## 8. Integration

- [x] 8.1 From a clean checkout of the branch, run the Linux check on both architectures, `verify/macos.sh`, and `verify/macos-host.sh` on this Mac, and verify all pass with no skipped assertion
  - 2026-10-17, on the final tree (each check copies git's index): `verify/linux.sh` 79/0 on both runs for aarch64 and for x86_64 (emulated), with the generation kept and no new backups on the second run; `verify/macos.sh` 61/0 with this Mac's Nix; `verify/macos-host.sh` 162/0 as the primary account. One reported skip: default apps are manual (duti changes nothing on macOS 26 and later).
- [ ] 8.2 Deferred past this PR (owner wraps it up, 2026-10-17): the first real upgrade moves every pin, which is its own reviewable change. `nix run .#upgrade -- --dry-run` prints `nix flake update` then the sync; the nvim lockfile is no longer part of it. Original task: On this Mac, run `nix run .#upgrade` once and verify it updates `flake.lock` and the nvim lockfile, switches, and leaves the workspace passing the host assertions

## 9. Second account

- [x] 9.1 Declare every account on the Mac in one nix-darwin system: `darwin [ <primary> <second> ]` in `flake.nix`, the first account primary (Homebrew, system settings), home-manager for both with links into each user's own clone, fish as login shell for both, and the Finder defaults moved to per-user `targets.darwin.defaults`; verify with `verify/macos.sh` that both users are configured
  - `verify/macos.sh` 61/0. The second account's managed paths: two real files (backed up as `*.pre-nix`) and the curl `~/.local/bin/claude` link (forced); nothing blocks the switch. The Homebrew cleanup of 2026-10-17 had removed the second account's login shell (`/opt/homebrew/bin/fish`); the owner pointed it at `/run/current-system/sw/bin/fish` with `sudo chsh`.
- [x] 9.2 In the second account's session: switch their clone to this branch, remove mise (`~/.config/mise`, `~/.local/state/mise`, `~/.cache/mise`), Mason and the `~/.config/nvim` link, and clear the universal `fish_user_paths`
- [x] 9.3 Switch from the primary account's session, then verify `verify/macos-host.sh` passes in the second account's session
  - 2026-10-17: run from the primary account's terminal with `sudo -u <second user>`. The switch activated home-manager for both users with no step failure, and `brew bundle` no longer tries to uninstall gcloud-cli's six dependencies, now declared as brews. `verify/macos-host.sh` as the second account: 156 passed, 0 failed (default apps reported as a manual skip).

## 9. Primary account and zsh (owner request, 2026-10-18)

- [x] 9.1 Make the first account in the Mac's list the primary account (flake.nix), which owns Nix's setup, Homebrew and the system settings; `macos.sh` and the sync run only from it, and `macos.sh` hands /opt/homebrew and other accounts' /Applications bundles to it
- [x] 9.2 zsh as every account's login shell, with `zsh/.zshrc` carrying the interactive setup fish had; Ghostty and herdr follow zsh; fish stays installed but is no login shell
- [ ] 9.3 From the primary account, run `macos.sh`, then `verify/macos-host.sh` in every account

