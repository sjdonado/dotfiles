# Tasks

## 1. Freeze Current Coverage

- [x] 1.1 Generate a shell-migration coverage table from `nix/home/*.nix`, `nix/darwin/*.nix`, `flake.nix`, and `provision-with-nix/coverage.tsv`; assign every current package, command, cask, link, setting, agent, and activation step to Homebrew, apt, a guarded installer, a manual item, or an explicit removal, and verify no current declared item is unclassified.
- [x] 1.2 Resolve and document the macOS source for every current CLI, including OpenCode v2 and keg-only tool variants, using `brew info` or the upstream source; verify every selected formula and cask resolves without changing the installed set.
- [x] 1.3 Resolve and document the Linux source and architecture support for every required command, using apt metadata or upstream release metadata; verify each non-apt installer has an `aarch64` and `x86_64` source or is recorded as unsupported before implementation continues.

## 2. Shared Shell Foundation

- [x] 2.1 Add shared logging, failure collection, platform detection, architecture normalization, and safe command helpers under `lib/`; verify every new shell file passes its declared shell's syntax check and ShellCheck where available.
- [x] 2.2 Implement `hosts/macos.sh` as the single hostname and account declaration, with the first account primary; verify parsing returns the expected primary and account list and fails for an unknown host without mutation.
- [x] 2.3 Implement the primary-account guard before all macOS mutation entry points; verify a simulated secondary account cannot reach package, ownership, defaults, launch-agent, cleanup, upgrade, or migration commands.
- [x] 2.4 Rebuild `lib/links.sh` from the current home-manager destinations with one recoverable backup, already-correct-link no-op behavior, and a destination registry; verify two throwaway-HOME applications produce correct links and no second backup.
- [x] 2.5 Implement guarded vendor installation and link checks for Claude Code and Codex plus the shared `codex-config` and other generated-user-state steps; verify installed vendor targets are retained and missing targets select only the expected installer in a non-network test mode.

## 3. macOS Package and Machine State

- [x] 3.1 Create the authoritative `Brewfile` from the approved coverage map, including taps, formulas, casks, and required cask dependencies; verify its declared sets match the approved map and every item resolves with Homebrew.
- [x] 3.2 Implement normal Homebrew convergence and explicit `--upgrade` behavior with automatic updates disabled during normal sync and non-zapping cleanup behind a migration-safe flag; verify dry-run or test doubles show the expected command order and never select `--zap`.
- [ ] 3.3 Port current macOS system defaults, ownership checks, login-shell handling, and shared machine state from the Nix modules into idempotent shell steps; verify each step has an outcome assertion and a second fixture run changes nothing.
- [ ] 3.4 Port per-user defaults, keyboard layouts, application bindings, BrowserRouter registration, and generated configuration into the user application path; verify a throwaway-HOME run produces every declared artifact and reports non-testable host activation separately.
- [ ] 3.5 Port current launch agents and background-item handling with validated atomic plist replacement and obsolete-agent cleanup; verify generated plists pass `plutil`, labels are unique, and a second fixture run produces no duplicate agent.
- [ ] 3.6 Implement primary-account orchestration across every declared account using each account's own checkout; verify test doubles invoke machine work once, user work once per account, and checks once per account without pulling or switching a checkout.

## 4. Linux Provisioning

- [ ] 4.1 Add `packages/linux-apt.txt` with the approved Ubuntu package set and an idempotent apt installer; verify the list has no duplicate or unresolved package in the disposable base image.
- [ ] 4.2 Implement the approved guarded Linux installers for every required non-apt command without Nix, mise, or Linuxbrew; verify each installer detects an existing working command and selects the correct archive or vendor path for both supported architectures.
- [ ] 4.3 Port Linux shell startup, PATH, agent CLI exposure, git-identity handling, and common links from the current modules; verify clean login, interactive, and non-interactive shells find required commands without `/nix`, mise, or Linuxbrew paths.
- [ ] 4.4 Rebuild `setup.sh` around platform detection, Linux clone/bootstrap, macOS primary-account setup, and initial sync; verify matching flags dispatch correctly and mismatched or unsupported platforms stop before any mutating test double.

## 5. Sync and Outcome Verification

- [ ] 5.1 Rebuild `sync.sh` with apply, `--upgrade`, and read-only `--check` modes while preserving secondary-account check-only behavior; verify argument handling and command traces for every platform and account role.
- [ ] 5.2 Implement declaration-driven command, package, link, generated-file, settings, agent, ownership, and shell checks; verify fixtures fail for a broken command, copied configuration, package drift, foreign owner, missing agent, and incorrect shell state.
- [ ] 5.3 Add explicit independence checks for Nix stores and profiles, mise directories and shims, and Linuxbrew; verify each forbidden-path fixture fails with the offending command or path.
- [ ] 5.4 Rewrite `verify/linux.sh` to provision a disposable Ubuntu environment twice on `aarch64` and `x86_64`; verify both runs report passed, failed, and unverified counts and prove no duplicate block or additional backup.
- [x] 5.5 Rewrite `verify/macos.sh` as a non-mutating preflight covering shell syntax, Brewfile resolution, host parsing, throwaway-HOME application twice, generated plists, account guards, and migration preconditions; verify it changes no package, setting, agent, or host file and reports activation-only behavior as unverified.
- [x] 5.6 Update `verify/README.md` and day-to-day setup documentation for Homebrew, apt, vendor installers, primary-account rules, update semantics, manual authentication, and recovery; verify every documented command matches the implemented help output and no routine instruction invokes Nix or mise.

## 6. Nix Migration Implementation

- [x] 6.1 Implement `sync.sh --migrate-from-nix` as a macOS primary-only mode that applies the candidate, runs preflight and host checks, and stops before destructive removal; verify any failed assertion leaves the Nix uninstall command unreachable.
- [x] 6.2 Implement Homebrew detachment that repairs an official checkout in place, replaces Nix-store tap links with normal taps, preserves Cellar, Caskroom, applications, and user data, and verifies all Homebrew paths are independent from `/nix`; verify the transition against a disposable filesystem fixture before host use.
- [ ] 6.3 Implement replacement and cleanup for Nix-managed shell startup, login shells, links, launch agents, and per-user state, with rollback backups retained until final acceptance; verify fixtures preserve `/bin/zsh` access and remove only recognized Nix-managed state.
- [x] 6.4 Add the explicit final Nix uninstall gate and post-uninstall checks without invoking it by default; verify the gate requires recorded passing preflight and every-account host evidence from the same working tree.
- [x] 6.5 Document the exact pre-removal and post-removal recovery procedures, including the retained commit and Nix reinstall path; verify the instructions name which operations preserve data and which removal cannot be rolled back without reinstalling Nix.

## 7. Host Transition

- [ ] 7.1 Run `verify/linux.sh` for both supported architectures and `verify/macos.sh` against the exact candidate tree; record pass, fail, and unverified counts, and do not proceed while any required assertion fails or a platform run is unavailable.
- [ ] 7.2 Obtain explicit owner authorization to apply the shell-managed candidate on the Mac while Nix remains installed, then apply without Homebrew cleanup or Nix removal and verify every declared account from a clean login shell.
- [ ] 7.3 Compare the candidate Brewfile with the installed formulas, casks, taps, and applications, resolve every difference in the declaration, obtain explicit owner authorization for removing undeclared items, enable non-zapping cleanup, and verify a second sync changes no managed state.
- [ ] 7.4 Run the detachment stages of `sync.sh --migrate-from-nix`, stopping before uninstall; verify Homebrew, every required command, every managed link, every launch agent, and every declared account work without resolving through Nix or mise.
- [ ] 7.5 Obtain explicit owner authorization for the irreversible host transition, invoke the Nix uninstaller, open clean login and non-interactive shells for every declared account, and record complete passing host-check counts; if any post-removal check fails, follow the documented reinstall recovery rather than deleting more state.

## 8. Remove Obsolete Declarations

- [ ] 8.1 After successful host transition, remove `flake.nix`, `flake.lock`, `nix/`, Nix-only verification code, and remaining mise declarations or references while preserving unrelated working-tree changes; verify `rg` finds no live provisioning dependency on Nix or mise outside history and migration documentation.
- [x] 8.2 Update coverage and repository documentation to describe only the final shell-based state and named manual exceptions; verify all package, account, setup, sync, check, upgrade, and recovery commands are current.
- [ ] 8.3 Run the final Linux checks on both architectures, macOS preflight, and macOS host checks for every declared account; report exact pass, fail, and unverified counts and leave the change incomplete if any required surface is unavailable or failing.
