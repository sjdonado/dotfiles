# Proposal

## Why

The workspace today has several sources of truth. mise.toml declares tools and Homebrew packages, `lib/links.sh` and the two installers create links and run setup steps, curl installers add claude and herdr, `go install` adds three Go tools, and about 24 apps in /Applications are declared nowhere. A change or an upgrade means knowing which of these owns the item, and mise cannot express system state (macOS defaults, launch agents, the login shell) at all. The owner wants one declarative source: every install, change and upgrade of this workspace happens through Nix, on macOS and on Linux.

A proto slice and an availability check already show this is possible without losing anything. home-manager switched 12 tools and 4 live links in a disposable Linux container, with an idempotent second run. Every current Homebrew formula, cask and mise tool has a Nix-managed source at the pinned nixpkgs commit (see design.md, "Package coverage").

## What Changes

- A flake at the repository root becomes the only declaration of the workspace. `flake.lock` pins nixpkgs, home-manager, nix-darwin, nix-homebrew and every Homebrew tap.
- **macOS**: nix-darwin owns system state: packages, Homebrew formulas and casks it cannot get from nixpkgs, Mac App Store apps, macOS defaults and app shortcuts, default apps (duti), the two launch agents, the login shell, keyboard layouts and BrowserRouter registration. home-manager runs inside it for the user.
- **Linux**: standalone home-manager on any distribution with Nix installed (no NixOS). It owns packages, links, shell environment blocks and the interactive fish hand-off that `linux.sh` appends today.
- Both platforms share one home-manager module for packages and links. Links into the repository stay live (out-of-store symlinks), so tools that write back into tracked files (nvim's plugin lockfile, opencode kv.json) keep working.
- Setup steps that are not packages (herdr plugins and integrations, codex config apply, bat cache, pss-sync, agent-browser's Chrome, nvim plugins and Mason tools) run as activation steps of the switch, so they also happen only through Nix.
- The upgrade path is `nix flake update` followed by the platform switch. Nothing else is needed.
- **BREAKING**: mise is removed: `mise.toml`, `mise.lock`, the `[tasks]` (bootstrap, pss-sync, upgrade) and every mise shim on PATH. `macos.sh` and `linux.sh` shrink to bootstrapping Nix and running the first switch. `lib/links.sh` is removed once home-manager owns every link.
- **BREAKING**: Homebrew is no longer run by hand. nix-homebrew owns the Homebrew installation, and nix-darwin's `homebrew` module removes undeclared formulas and casks on switch.
- Apps installed by hand today become declared: 11 as casks, 13 as Mac App Store apps.
- The verification under `verify/` moves to the new entry points: the Linux container check switches home-manager, and the macOS VM rehearsal runs nix-darwin in a disposable guest before the switch on this Mac.

## Capabilities

### New Capabilities

- `workspace-provisioning`: what a provisioned machine has and how it is changed: the single declarative source, the per-platform switch, the upgrade path, package and app coverage, links into the repository, system settings and activation steps, idempotence, and the named items that cannot be declared.
- `provisioning-verification`: how a provisioning change is proven before it reaches a real machine: the Linux container switch, the macOS VM switch, and the assertions both make.

### Modified Capabilities

None. `openspec/specs/` has no capabilities yet.

## Impact

- Added: `flake.nix`, `flake.lock`, `nix/` modules (shared home, Linux home, darwin system, Homebrew), `verify/nix/`.
- Removed: `mise.toml`, `mise.lock`, `lib/links.sh`, mise and Homebrew steps in `macos.sh` and `linux.sh`.
- Changed: `macos.sh`, `linux.sh` (Nix bootstrap and first switch), `verify/linux`, `verify/macos`, `verify/macos-vm`, `README.md`, `CLAUDE.md` (repository guide sections on provisioning and verification), `fish/config.fish` and any PATH logic that names mise shims, `herdr/config.toml` or scripts that call `mise`.
- Host: installs Nix on this Mac (a /nix APFS volume and the nix-daemon) and hands the existing /opt/homebrew to nix-homebrew. Installing Nix is a separate step that happens only after the VM rehearsal passes and the owner approves it.
- Not declarable, and named as exceptions: the Safari web apps (Gmail, Calendar, Google Meet), Anarlog Dev (a local build), Claude Code URL Handler (created by Claude Code), Safari.
