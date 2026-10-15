# Spec Delta

## Purpose

Defines what a provisioned macOS or Linux workspace contains and how it is changed: one declaration in this repository that produces packages, apps, links, system settings and setup steps, and that is the only way to install, change or upgrade any of them.

## ADDED Requirements

### Requirement: One declarative source
The repository SHALL hold the only declaration of the workspace. Every package, app, link, system setting and setup step the workspace has SHALL come from that declaration, and no other tool's configuration file in the repository SHALL declare any of them.

#### Scenario: Adding a tool
- **WHEN** the owner wants a new command-line tool on both platforms
- **THEN** the change is one entry in the declaration, applied by the platform switch, with no other file or command involved

#### Scenario: No second package list
- **WHEN** the repository is searched for package lists after the change
- **THEN** no mise configuration, Brewfile or installer-embedded package list exists

### Requirement: Platform switch
One command per platform SHALL apply the declaration to the current machine: on macOS it applies system and user state, and on Linux it applies user state on any distribution with Nix installed, without requiring NixOS.

#### Scenario: macOS switch
- **WHEN** the owner runs the macOS switch on a Mac with Nix installed
- **THEN** the declared packages, casks, App Store apps, links, system settings and setup steps are present afterwards

#### Scenario: Linux switch
- **WHEN** the owner runs the Linux switch as an unprivileged user on Ubuntu with Nix installed
- **THEN** the declared packages, links, shell environment and setup steps are present for that user, and no system file outside the Nix installation is changed

### Requirement: Upgrades through the declaration only
Upgrading SHALL be an update of the pinned inputs followed by the platform switch. No package manager, installer script or tool-specific update command SHALL be needed to upgrade a declared item.

#### Scenario: Routine upgrade
- **WHEN** the owner updates the pinned inputs and runs the platform switch
- **THEN** packages, casks, Homebrew taps and setup-step sources move to the versions the new pins select, and the lock change is a reviewable diff in the repository

#### Scenario: Homebrew not run by hand
- **WHEN** an item comes from Homebrew because Nix packages lack it
- **THEN** its tap is pinned with the other inputs and it is installed and upgraded only by the switch

### Requirement: Pinned, reproducible versions
Every input the declaration uses SHALL be pinned in a lock file tracked in the repository, so two machines switched from the same commit get the same versions.

#### Scenario: Two machines, one commit
- **WHEN** two Macs switch from the same repository commit
- **THEN** each declared package resolves to the same version on both

### Requirement: Nothing lost in the migration
The declaration SHALL cover every item the workspace had before the change: each Homebrew formula and cask, each mise tool, each tool installed by an installer script or `go install`, and each app in /Applications that can be declared. Items that cannot be declared SHALL be listed by name with the reason.

#### Scenario: Inventory comparison
- **WHEN** the pre-change inventory is compared with the declaration
- **THEN** every inventory item maps to a declared entry or to a named exception, and none is unaccounted for

#### Scenario: Same program, not same name
- **WHEN** a Nix package has the same name as a Homebrew formula but is a different program
- **THEN** the declaration uses the source that provides the original program

### Requirement: Undeclared Homebrew items removed
On macOS, the switch SHALL remove Homebrew formulas and casks that the declaration does not list, so the installed set always equals the declared set.

#### Scenario: Cask removed from the declaration
- **WHEN** the owner deletes a cask entry and runs the macOS switch
- **THEN** that cask is uninstalled

### Requirement: Live links into the repository
Configuration files the workspace links SHALL resolve to the files in the repository working tree, not to copies, so an edit in the repository takes effect without a switch and a tool that writes back to its configuration changes the tracked file.

#### Scenario: Editing a config
- **WHEN** the owner edits a linked configuration file in the repository
- **THEN** the tool reads the edit on its next start without a switch

#### Scenario: Tool writes back
- **WHEN** Neovim updates its plugin lockfile
- **THEN** the change appears as a diff in the repository

### Requirement: macOS system settings
On macOS the switch SHALL apply the declared defaults and app shortcuts, default apps for file types, the launch agents, fish as the login shell, the custom keyboard layouts and BrowserRouter's registration with Launch Services.

#### Scenario: Login shell
- **WHEN** the macOS switch completes on a machine whose login shell is zsh
- **THEN** fish is listed in /etc/shells and is the user's login shell

#### Scenario: Launch agents
- **WHEN** the macOS switch completes
- **THEN** the Caps Lock remapping and the Time Machine exclusion agents are loaded and point at scripts in the repository

### Requirement: Setup steps run by the switch
Setup that is not a package or a link (herdr plugins and integrations, the codex configuration merge, the bat theme cache, the Pi scheme, agent-browser's browser, Neovim plugins and tools) SHALL run as part of the switch. A failing step SHALL be reported by name and SHALL NOT stop the other steps.

#### Scenario: herdr not running
- **WHEN** the switch runs while no herdr server is running
- **THEN** the herdr plugin step reports that it was skipped and why, and every other step still runs

### Requirement: Idempotent switch
A second switch with no change to the declaration SHALL change nothing: no new generation of user state, no backup files, no duplicated shell blocks and no reinstalled packages.

#### Scenario: Second switch
- **WHEN** the platform switch runs twice in a row
- **THEN** the second run reports no changes and leaves no backup files

### Requirement: Tools found by non-interactive shells
Declared tools SHALL be on PATH for login and non-interactive shells on both platforms, including an agent hook, a herdr pane running a command and `ssh host command`.

#### Scenario: Non-interactive shell on Linux
- **WHEN** `env -i HOME=$HOME bash -lc 'nvim --version'` and `ssh host 'nvim --version'` run after the Linux switch
- **THEN** both find nvim

### Requirement: Named exceptions
Items the declaration cannot own SHALL be listed in the repository with the reason and the manual step, if any: the Safari web apps, Anarlog Dev, Claude Code URL Handler, Safari, and secrets such as .env files and SSH keys.

#### Scenario: Reading the exceptions
- **WHEN** the owner sets up a new Mac
- **THEN** the repository lists each manual step that remains after the switch, and nothing else is manual
