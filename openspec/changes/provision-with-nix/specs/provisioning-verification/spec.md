# Spec Delta

## Purpose

Defines how a change to provisioning is proven on disposable machines before it reaches a real one, and what those checks assert, so a green check means a machine set up from nothing ends up as declared.

## ADDED Requirements

### Requirement: Linux check in a disposable container
A check SHALL apply the Linux switch from the working tree, uncommitted changes included, in a disposable container with Nix, twice, and assert the result after each run. It SHALL need only Docker on the host.

#### Scenario: Check passes
- **WHEN** the Linux check runs on a working tree whose declaration is correct
- **THEN** it exits zero and prints each assertion it made with its result

#### Scenario: Check fails visibly
- **WHEN** a declared tool fails to run or a link points elsewhere
- **THEN** the check names the failing tool or link and exits non-zero

### Requirement: macOS checks before and after a switch
A check SHALL evaluate and build the macOS configuration from the working tree without applying it, and a second, read-only check SHALL assert the Mac itself after a switch. Neither SHALL change the host's packages, settings or Homebrew.

#### Scenario: Before a switch
- **WHEN** a macOS provisioning change is ready
- **THEN** the configuration check runs and passes before the switch runs on the Mac

#### Scenario: After a switch
- **WHEN** a switch on the Mac completes
- **THEN** the host check asserts the result and names every failing tool, link or setting

### Requirement: What the checks assert
Both checks SHALL assert that every declared command-line tool answers its version command, that every declared link resolves into the repository working tree, that the second switch changes nothing and leaves no backup files, that tools resolve in a non-interactive shell, and that every skipped setup step says it was skipped.

#### Scenario: Copy instead of link
- **WHEN** a managed configuration is a copy with the right contents instead of a link into the repository
- **THEN** the check fails for that path

#### Scenario: Wrapper on PATH but broken
- **WHEN** a tool exists on PATH but its version command fails
- **THEN** the check fails for that tool

### Requirement: Host changes gated by the owner and the configuration check
Installing Nix and the first macOS switch on a real Mac SHALL happen in one step, `macos.sh`, and only after the configuration check passes for the same working tree and the owner approves that step.

#### Scenario: Configuration check red
- **WHEN** the configuration check fails
- **THEN** `macos.sh` does not run on the host, and the failure is reported with what each attempt ruled out
