# Spec Delta

## Purpose

Defines the evidence required to prove shell-based provisioning is complete, repeatable, account-safe, and independent from Nix and mise before it changes or replaces a working host.

## ADDED Requirements

### Requirement: Linux is provisioned from nothing
The Linux verification SHALL provision a supported disposable Linux environment using `setup.sh`, SHALL run the host checks, and SHALL repeat setup and checks to prove idempotency.

#### Scenario: First disposable Linux run
- **WHEN** Linux verification starts from its declared base image
- **THEN** setup installs every required package and configuration and all host assertions pass

#### Scenario: Second disposable Linux run
- **WHEN** the same environment is provisioned again without declaration changes
- **THEN** all assertions pass with no duplicate shell block, additional backup, or duplicate managed state

#### Scenario: Supported Linux architecture
- **WHEN** verification targets each supported Linux architecture
- **THEN** every declared installer source resolves for that architecture or the check reports the platform as unverified

### Requirement: macOS candidate is checked without host mutation
Before host migration, macOS verification SHALL validate script syntax, declared Homebrew items, link generation, settings inputs, launch-agent generation, account rules, and migration preconditions without installing, removing, upgrading, or activating host state.

#### Scenario: Candidate passes preflight
- **WHEN** the macOS verification runs against a candidate working tree
- **THEN** every statically or safely testable declaration and generated artifact passes without changing the host

#### Scenario: Candidate cannot be fully exercised
- **WHEN** a required macOS behavior cannot be tested without host mutation
- **THEN** the check reports that behavior as unverified rather than passing it by inspection

### Requirement: Host checks assert outcomes
`sync.sh --check` SHALL be read-only and SHALL assert that required commands run, package declarations match installed state, links resolve into the correct checkout, settings and agents hold, and login and non-interactive shells find the required tools.

#### Scenario: Command exists but fails
- **WHEN** a required command is on `PATH` but its safe version or help probe fails
- **THEN** the host check fails that command

#### Scenario: Configuration was copied instead of linked
- **WHEN** a managed destination has matching contents but does not resolve to the declared repository path
- **THEN** the host check fails that link

#### Scenario: Package drift exists
- **WHEN** the installed Homebrew formula or cask set differs from the authoritative declaration
- **THEN** the host check reports the difference and exits non-zero

### Requirement: Checks prove independence from removed managers
Host and disposable checks SHALL fail when a required command, shell path, managed link, launch agent, or provisioning action depends on a Nix store, Nix profile, mise shim, mise state directory, or Linuxbrew prefix.

#### Scenario: Nix path remains active
- **WHEN** a required command or shell startup resolves through `/nix`
- **THEN** verification fails and identifies the dependency

#### Scenario: mise path remains active
- **WHEN** shell startup or a required command resolves through mise-managed state or shims
- **THEN** verification fails and identifies the dependency

### Requirement: macOS account boundary is verified
The verification SHALL prove that the configured primary account is the only macOS account that can mutate packages or machine state and that each declared account receives and passes its own user-level checks.

#### Scenario: Primary account checks the Mac
- **WHEN** the primary account runs host verification
- **THEN** every declared account is checked in that account's clean login environment

#### Scenario: Secondary account requests mutation
- **WHEN** a non-primary account requests setup, sync mutation, or upgrade
- **THEN** verification proves the request stops before any mutating command runs

### Requirement: Homebrew ownership and cleanup are verified
macOS host checks SHALL assert that Homebrew and primary-account-owned application bundles have no ownership dependency on another human account and that cleanup retains exactly the declared top-level set plus required dependencies.

#### Scenario: Foreign account owns Homebrew content
- **WHEN** content under the Homebrew prefix belongs to another human account
- **THEN** the host check fails and identifies an offending path

#### Scenario: Declared package set holds
- **WHEN** sync and cleanup complete
- **THEN** verification confirms every declared item is installed and no undeclared top-level item remains

### Requirement: Migration removal has a hard gate
No verification command SHALL uninstall Nix. The explicit Nix removal task SHALL be eligible only after the shell-managed candidate passes macOS preflight and every declared account passes host checks with Homebrew and shell startup independent from Nix and mise.

#### Scenario: Any migration assertion fails
- **WHEN** any preflight, package, link, account, shell, settings, agent, ownership, or independence assertion fails
- **THEN** the removal gate remains closed and Nix stays installed

#### Scenario: Removal prerequisites pass
- **WHEN** all migration assertions pass on the applied shell-managed host
- **THEN** verification records the passing evidence needed for the separately invoked Nix removal task

### Requirement: Verification protects secrets and external services
Checks SHALL NOT inspect environment-secret files, private keys, credentials, authentication state, or secret-bearing responses, and SHALL NOT deploy or modify external services.

#### Scenario: Tool requires authentication
- **WHEN** a command probe would require credentials or contact a mutable external service
- **THEN** verification uses a local safe probe or reports the authenticated behavior as a manual check

### Requirement: Results report evidence accurately
Each verification run SHALL report passed, failed, and explicitly unverified assertions, and SHALL exit non-zero when any required assertion fails. An unavailable check SHALL NOT be counted as passing.

#### Scenario: Provider or platform check unavailable
- **WHEN** a required disposable environment or platform capability is unavailable
- **THEN** the result names the missing evidence and does not claim acceptance for that surface
