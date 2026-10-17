# Verifying a provisioning change

A change to `flake.nix` or `nix/` is checked by applying it somewhere disposable, never by reading it and never first on a real machine. A real machine is already half provisioned, so it hides what a fresh one would hit, and a failed run there leaves residue.

| check | what it does | needs | time |
| --- | --- | --- | --- |
| `verify/linux.sh` | runs `linux.sh` on a bare Ubuntu container (no systemd, like a Coder workspace), twice, and asserts the box after each run | Docker | ~2 min per run |
| `verify/macos.sh` | evaluates the macOS configuration (and builds it, with Nix on this Mac) and asserts what a switch would apply, then checks every package of the macOS and Linux profiles is available, prebuilt and collision-free | Docker, or Nix | ~1 min |
| `verify/macos-host.sh` | asserts this Mac after a switch: declared tools run, links resolve into the repository, settings hold, shells find the tools; read-only | Nix and a switched Mac | ~1 min |

Each script is self-contained. `verify/linux.sh` holds both the host side and the assertions, and runs itself inside the container to assert. `verify/linux.sh --platform linux/amd64` checks the other Linux architecture; `verify/linux.sh --shell` leaves you in the provisioned box.

Run the checks for the platform a change touches, both when it touches both: on macOS, `verify/macos.sh` before a switch and `verify/macos-host.sh` after it.

## What every check asserts

- **A tool runs, not merely exists.** Each declared tool answers its version command (a language server without one, when the full neovim setup is restored, answers an LSP initialize request).
- **Links resolve into the repository.** `readlink -f` on both sides, so a copy that happens to match does not pass.
- **Non-interactive shells find the tools**: login bash, a bash that reads only `~/.bashrc` (`ssh host command`), `zsh -c`, fish. That is what an agent hook or a herdr pane gets.
- **A second run changes nothing**: the same generation, no new backup files, no duplicated shell block, no reinstalled Nix.
- **A skipped step says so.** A setup step that cannot run reports its skip by name.
- **Upstream Nix**, not Determinate Nix.

## What stays on the host

Each check copies only the files the git flake sees (git's index, with their working-tree contents), so a new file has to be staged first, exactly as before a switch. Ignored files, including secrets (`.env*`, `.ssh/private.conf`) and eval transcripts, never reach a container or the Nix store.

## Why macOS has two checks

Linux containerises, so the Linux check provisions a real box from nothing. macOS does not. `verify/macos.sh` asserts the configuration itself before a switch, and `verify/macos-host.sh` asserts this Mac after one. A disposable macOS VM rehearsal existed and was dropped (2026-10-17): it cost a 25 GB image and tens of minutes per run, and the switch is rollback-able with `darwin-rebuild switch --rollback`.
