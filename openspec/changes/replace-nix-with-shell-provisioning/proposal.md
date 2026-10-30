# Proposal

## Why

Nix now adds more operational complexity than value to this personal workspace: routine package changes require flake evaluation, host recovery includes Nix daemon and store concerns, and the same result can be maintained with conventional package managers plus idempotent shell scripts. Replace it with a setup that is easier to inspect, repair, and run directly while preserving package coverage, multi-account ownership, and verification.

## What Changes

- **BREAKING** Remove Nix, nix-darwin, home-manager, flake inputs, Nix packages, and mise from workspace provisioning.
- Make a normal Homebrew `Brewfile` the macOS declaration for command-line packages, taps, and GUI casks.
- Keep one configured primary macOS account as the only account allowed to install, update, clean up, or change machine-wide state. Other accounts can run read-only checks.
- Rebuild `setup.sh` and `sync.sh` as idempotent shell entry points that apply packages, links, macOS settings, launch agents, and guarded setup steps without Nix.
- Provision Linux with distribution packages where adequate and explicit vendor or release installers for required tools that the distribution does not supply adequately. Do not install Linuxbrew or a runtime manager.
- Preserve the vendor-managed Claude Code and Codex installations required by their self-update commands and T3 Code integration.
- Preserve the current live-link behavior, declared account coverage, command checks, package cleanup policy, and disposable verification for both platforms.
- Migrate the existing host safely before uninstalling Nix, including Homebrew ownership and taps, shell paths, launch agents, configuration links, and Nix-created system state.

## Capabilities

### New Capabilities

- `workspace-provisioning`: Defines shell-based package, configuration, account ownership, update, cleanup, and migration behavior on macOS and Linux.
- `provisioning-verification`: Defines disposable and host checks that prove setup completeness, idempotency, account isolation, and independence from Nix and mise.

### Modified Capabilities

None.

## Impact

- Replaces `flake.nix`, `flake.lock`, `nix/`, and the Nix-specific parts of `setup.sh`, `sync.sh`, `verify/`, and repository documentation.
- Restores a shared shell linking and activation layer, based on current behavior rather than restoring the obsolete pre-Nix scripts verbatim.
- Adds a Homebrew `Brewfile` and explicit Linux package and installer declarations.
- Changes package versioning and rollback from Nix generations and a flake lock to Homebrew, distribution packages, vendor installers, and any source-specific locks or pinned releases.
- Changes the live macOS host only during an explicit migration task after non-mutating verification passes; planning and implementation checks must not uninstall Nix prematurely.
