# Verifying a provisioning change

A change to `flake.nix` or `nix/` is checked by applying it somewhere disposable, never by reading it and never first on a real machine. A real machine is already half provisioned, so it hides what a fresh one would hit, and a failed run there leaves residue.

| check | what it does | needs | time |
| --- | --- | --- | --- |
| `verify/linux.sh` | runs `setup.sh` on a bare Ubuntu container (no systemd, like a Coder workspace), twice, and checks the box with `sync.sh` after each run | Docker | ~2 min per run |
| `verify/macos.sh` | evaluates the macOS configuration (and builds it, with Nix on this Mac) and asserts what a switch would apply, then checks every package of the macOS and Linux profiles is available, prebuilt and collision-free | Docker, or Nix | ~1 min |

Each script is self-contained. The assertions after a switch are not under verify/: they are `sync.sh`'s own checks (`sync.sh --check`, read-only), which every sync runs on a real machine and `verify/linux.sh` runs inside the container. `verify/linux.sh --platform linux/amd64` checks the other Linux architecture; `verify/linux.sh --shell` leaves you in the provisioned box.

Run the checks for the platform a change touches, both when it touches both: on macOS, `verify/macos.sh` before a switch, and the switch itself through `sync.sh`, which checks the Mac after it.

## What every check asserts

- **A tool runs, not merely exists.** Each declared tool answers its version command (a language server without one, when the full neovim setup is restored, answers an LSP initialize request).
- **Links resolve into the repository.** `readlink -f` on both sides, so a copy that happens to match does not pass.
- **Non-interactive shells find the tools**: login bash, a bash that reads only `~/.bashrc` (`ssh host command`), `zsh -c`, and on macOS a login interactive zsh with the Nix profiles ahead of Homebrew. That is what an agent hook or an editor's terminal gets.
- **A second run changes nothing**: the same generation, no new backup files, no duplicated shell block, no reinstalled Nix.
- **A skipped step says so.** A setup step that cannot run reports its skip by name.
- **Upstream Nix**, not Determinate Nix.

## What stays on the host

Each check copies only the files the git flake sees (git's index, with their working-tree contents), so a new file has to be staged first, exactly as before a switch. Ignored files, including secrets (`.env*`, `.ssh/private.conf`) and eval transcripts, never reach a container or the Nix store.

## Why macOS has two checks

Linux containerises, so the Linux check provisions a real box from nothing. macOS does not. `verify/macos.sh` asserts the configuration itself before a switch, and `sync.sh` asserts this Mac after one. A disposable macOS VM rehearsal existed and was dropped (2026-10-17): it cost a 25 GB image and tens of minutes per run, and the switch is rollback-able with `darwin-rebuild switch --rollback`.
