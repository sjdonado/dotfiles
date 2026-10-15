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
- [ ] 2.4 Move the Mason tools to Nix packages (decision 9): check each nixpkgs name with the evaluation script, add them to `home/common.nix`, remove mason.nvim and mason-tool-installer from `nvim/init.lua`, and verify in the Linux check that `nvim --headless` starts without errors and each server binary answers `--version`
  - The packages are declared and answer in the Linux check (a version command, or an LSP initialize request for the five servers with no version flag). Removing Mason from `nvim/init.lua` waits for group 7: this Mac's nvim finds its servers through Mason until the first switch puts the Nix ones on PATH.

## 3. Linux

- [x] 3.1 Write `home/linux.nix` (decision 11: rc files with PATH, git-identity unset, `ulimit -c 0`, `exec fish` hand-off, login shell untouched) and verify in the Linux check that `env -i HOME=$HOME bash -lc 'nvim --version'` and an interactive bash both resolve tools and that a second switch duplicates no block
- [x] 3.2 Rewrite the Linux check (now `verify/linux.sh`) for decision 12 (Ubuntu image, the Determinate installer installing upstream Nix, `home-manager switch` twice, assertions from the provisioning-verification spec), delete `verify/nix/`, and verify it passes on aarch64 and with `--platform linux/amd64`
  - aarch64 109 passed and amd64 110 passed, each on both runs, with upstream Nix 2.35.3 (the installer needs `--prefer-upstream-nix`; without it v3.23.2 installs Determinate Nix). Without systemd the installer is root-only, so linux.sh starts the daemon. Each check copies only the files in git's index, as the git flake sees them.
- [x] 3.3 Reduce `linux.sh` to installing Nix and running the first switch, and verify the Linux check runs it unmodified as its entry point
- [x] 3.4 Update `verify/README.md` and the Linux parts of `README.md` and `CLAUDE.md` (Verification, "Verifying a setup change"), and verify every command they quote runs as written
  - Linux parts: linux.sh, the verify scripts and `nix run .#switch`/`.#upgrade -- --dry-run` ran as quoted. The macOS commands (macos.sh, verify/macos-vm) run in groups 5 and 6.

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
  - Also `apps.switch`, which the installers and `upgrade` use. Dry runs checked in a Linux container; flake.lock and nvim-pack-lock.json unchanged.

## 5. VM rehearsal (no change to this Mac)

- [x] 5.0 Simplify `verify/` to one self-contained script per check (`verify/linux.sh`, `verify/macos.sh`, `verify/macos-vm.sh`, plus `verify/README.md`), drop `macos.sh --nix-only` so `macos.sh` is one script whose steps skip themselves, and get tart for the VM check from its pinned release instead of from Nix on this Mac; verify the Linux check on both architectures and the macOS fast loop pass
  - verify/linux.sh: aarch64 109/0 and amd64 110/0 on both runs. verify/macos.sh: 68/0, and the macOS (128) and both Linux (53) profiles available, prebuilt and collision-free. The VM check's tart download and guest steps run in 5.1.
- [ ] 5.1 Run `verify/macos-vm.sh` (DARWIN_CONFIG=verify-vm, `macos.sh` twice, the spec assertions) and verify a full run passes, recording the guest macOS version

## 6. First switch on this Mac (owner approval required)

- [ ] 6.1 Ask the owner to approve running `./macos.sh` on this Mac after 5.1 passed for the same commit; on approval run it (it installs upstream Nix, hands a non-stock /etc/shells to nix-darwin as /etc/shells.before-nix-darwin, and switches with `cleanup = "none"`) and verify every assertion of the provisioning-verification spec on the host, including `verify/macos.sh` building the system
- [ ] 6.2 Compare declared lists with `brew list`, `mas list` and /Applications, resolve every difference in the declaration, set `cleanup = "uninstall"`, switch again, and verify the installed set equals the declared set and a third switch changes nothing

## 7. Remove the old layer

- [ ] 7.1 Delete `mise.toml`, `mise.lock`, `lib/links.sh`, `~/.config/mise`, `~/.local/share/mise` and every mise reference on PATH or in configs (`fish/config.fish`, `herdr/config.toml`, `bin/`, the nvim comment), remove the `~/.config/mise/{config.toml,mise.lock}` links, remove Mason from `nvim/init.lua` (task 2.4; until then mason.setup prepends its bin directory to PATH), put `~/.local/bin`, `~/.opencode/bin`, `~/.bun/bin` and `/opt/homebrew/bin` after the Nix profile in `fish/config.fish` and assert in both checks that `claude` resolves into the Nix profile, drop `/opt/homebrew/lib/docker/cli-plugins` from `docker/config.json`, and remove `~/.local/bin/claude` left by the curl installer, and verify `rg -n 'mise' --glob '!openspec/**'` finds nothing outside history and that both checks still pass
- [ ] 7.2 Reduce `macos.sh` to installing Nix and running the first switch, and verify the VM rehearsal runs it as its entry point
- [ ] 7.3 Write the named exceptions and manual steps (Safari web apps and their BrowserRouter IDs, Anarlog Dev, Claude Code URL Handler, Safari, App Store sign-in, secrets, tool logins) into `README.md`, and update the macOS parts of `README.md` and `CLAUDE.md`, and verify every command they quote runs as written

## 8. Integration

- [ ] 8.1 From a clean checkout of the branch, run the Linux check on both architectures, the macOS fast loop and the VM rehearsal, and verify all pass with no skipped assertion
- [ ] 8.2 On this Mac, run `nix run .#upgrade` once and verify it updates `flake.lock` and the nvim lockfile, switches, and leaves the workspace passing the host assertions
