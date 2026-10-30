# Spec Delta

## Purpose

Defines how one shell-based workspace declaration installs, updates, links, and repairs the required developer environment on macOS and Linux without Nix or mise.

## ADDED Requirements

### Requirement: One setup entry point
`setup.sh` SHALL detect macOS or Linux from the running system when no platform flag is given, SHALL accept a matching explicit platform flag, and SHALL stop before changing anything when the requested platform does not match the host.

#### Scenario: Platform detected
- **WHEN** `setup.sh` runs without a platform flag on a supported host
- **THEN** it applies the setup for the detected platform

#### Scenario: Platform mismatch
- **WHEN** a macOS setup is requested on Linux or a Linux setup is requested on macOS
- **THEN** the script exits non-zero before changing the host

### Requirement: Conventional package sources
The declaration SHALL use Homebrew for conventional macOS formulas, taps, and casks, distribution packages for adequate Linux system tools, and guarded vendor or release installers only where the platform package source is inadequate.

#### Scenario: macOS package installation
- **WHEN** macOS setup applies the declaration
- **THEN** every declared formula, tap, and cask is applied from the tracked Homebrew declaration

#### Scenario: Linux package installation
- **WHEN** Linux setup applies the declaration on a supported distribution
- **THEN** every required command is supplied by a declared distribution package or an explicit guarded installer

### Requirement: No Nix, mise, or Linuxbrew dependency
The completed setup SHALL NOT require Nix, nix-darwin, home-manager, mise, or Linuxbrew to install, update, link, verify, or run the declared workspace.

#### Scenario: Fresh machine setup
- **WHEN** setup runs on a supported machine without Nix, mise, or Linuxbrew
- **THEN** it completes without installing or invoking any of them

#### Scenario: Normal shell startup
- **WHEN** a configured account starts a login or non-interactive shell
- **THEN** no required command or configuration resolves through a Nix store, Nix profile, mise shim, or Linuxbrew prefix

### Requirement: Primary macOS account owns mutations
The macOS declaration SHALL identify one primary account. Only that account SHALL install, update, remove, or change machine-wide packages, applications, settings, ownership, or shared system state.

#### Scenario: Primary account applies setup
- **WHEN** the configured primary account runs setup or sync on macOS
- **THEN** the requested machine mutations are allowed to proceed

#### Scenario: Another account runs setup
- **WHEN** any other account runs macOS setup
- **THEN** the script exits before changing anything and names the configured primary account

#### Scenario: Another account runs sync
- **WHEN** any other account runs macOS sync without an upgrade request
- **THEN** no mutation occurs and only that account's read-only checks run

### Requirement: One macOS sync configures every declared account
The primary account's macOS sync SHALL apply the user-level declaration to every account listed for the Mac, using each account's own home and dotfiles checkout, then SHALL verify every listed account.

#### Scenario: Multi-account sync
- **WHEN** the primary account syncs a Mac with two declared accounts
- **THEN** packages and machine state are applied once and user-level links and steps are applied and checked for both accounts

#### Scenario: Removed secondary account
- **WHEN** a secondary account is removed from the declaration and then from macOS
- **THEN** Homebrew, machine state, and the primary account's workspace remain functional

### Requirement: Declared Homebrew set is authoritative
macOS sync SHALL upgrade declared Homebrew items and remove undeclared formulas and casks without deleting their application data. It SHALL retain dependencies that Homebrew requires for declared items.

#### Scenario: Undeclared item exists
- **WHEN** the primary account syncs and Homebrew contains an undeclared formula or cask
- **THEN** sync removes the item without using destructive application-data cleanup

#### Scenario: Declared cask dependency exists
- **WHEN** a declared cask requires formulas that cleanup would otherwise remove
- **THEN** the declaration retains those required formulas and sync succeeds

### Requirement: Live configuration links
Tracked user configuration SHALL be linked into each account from that account's dotfiles checkout so repository edits take effect without a package sync and tool write-backs reach the tracked file where intended.

#### Scenario: Configuration is edited in the repository
- **WHEN** a tracked linked configuration is changed in the dotfiles checkout
- **THEN** the consuming tool observes the change without rerunning setup

#### Scenario: Existing unmanaged destination
- **WHEN** setup encounters a real file at a managed link destination
- **THEN** it preserves one recoverable backup before installing the managed link

#### Scenario: Repeated setup
- **WHEN** setup runs again with an already correct link
- **THEN** it leaves the link unchanged and creates no additional backup

### Requirement: Required activation behavior is preserved
Shell provisioning SHALL preserve the declared macOS defaults, per-user settings, launch agents, keyboard layouts, BrowserRouter registration, application bindings, generated configuration, and guarded setup steps that remain part of the current workspace.

#### Scenario: Independent setup step fails
- **WHEN** a non-critical guarded setup step fails
- **THEN** the script reports that step by name, continues independent steps, and exits non-zero if the resulting required state is incomplete

#### Scenario: Launch agent definition changes
- **WHEN** sync applies a changed declared launch agent
- **THEN** the account receives the current definition without retaining a duplicate obsolete agent

### Requirement: Vendor-managed agent CLIs remain self-updating
Claude Code and Codex SHALL use their vendor-managed installations, remain reachable from `~/.local/bin`, and SHALL NOT be replaced by Homebrew, distribution packages, Nix, or mise.

#### Scenario: Agent CLI already installed
- **WHEN** setup finds a working vendor-managed Claude Code or Codex installation
- **THEN** it leaves that installation and version unchanged

#### Scenario: Agent CLI missing
- **WHEN** setup finds either vendor-managed CLI missing
- **THEN** it runs that CLI's guarded vendor installer and verifies the resulting command

### Requirement: Idempotent setup and sync
Running setup or sync repeatedly with the same declaration SHALL converge on the same packages, links, settings, agents, and generated files without duplicate shell blocks, duplicate agents, or accumulating backups.

#### Scenario: Second unchanged run
- **WHEN** setup or sync runs twice without a declaration change
- **THEN** the second run succeeds and leaves no additional managed state

### Requirement: Sensitive state remains outside provisioning
Provisioning SHALL NOT read, copy, display, generate, or store environment-secret files, SSH private keys, authentication tokens, or application logins.

#### Scenario: Fresh account requires authentication
- **WHEN** setup finishes for an account without tool credentials
- **THEN** it reports authentication as a manual step without inspecting secret files

### Requirement: Safe migration away from Nix
The migration SHALL establish and verify an independent shell-managed environment before uninstalling Nix. It SHALL preserve Homebrew, declared applications, account access, configuration data, and a usable login shell throughout the transition.

#### Scenario: Pre-migration verification fails
- **WHEN** the candidate shell setup or its non-mutating checks fail
- **THEN** Nix remains installed and no Nix-owned host state is removed

#### Scenario: Homebrew is still tied to Nix
- **WHEN** Homebrew's executable, taps, ownership, or required paths still depend on the Nix store
- **THEN** migration stops before Nix is uninstalled

#### Scenario: Migration succeeds
- **WHEN** the primary account has applied the shell setup and every declared account passes host verification without Nix or mise paths
- **THEN** the explicit removal step may uninstall Nix and remove obsolete Nix declarations
