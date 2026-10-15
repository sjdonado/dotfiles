# Verifying a provisioning change

A change to `flake.nix` or `nix/` is checked by applying it somewhere disposable, never by reading it and never first on a real machine. A real machine is already half provisioned, so it hides what a fresh one would hit, and a failed run there leaves residue.

| check | what it does | needs | time |
| --- | --- | --- | --- |
| `verify/linux.sh` | runs `linux.sh` on a bare Ubuntu container (no systemd, like a Coder workspace), twice, and asserts the box after each run | Docker | ~2 min per run |
| `verify/macos.sh` | evaluates the macOS configuration (and builds it, with Nix on this Mac) and asserts what a switch would apply, then checks every package of the macOS and Linux profiles is available, prebuilt and collision-free | Docker, or Nix | ~1 min |
| `verify/macos-vm.sh` | runs `macos.sh` in a disposable macOS VM, twice, and asserts the guest after each run | this Mac (tart is downloaded, pinned, into a cache) | tens of minutes |

Each script is self-contained: it holds both the host side and the assertions, and runs itself inside the container or guest to assert. `verify/linux.sh --platform linux/amd64` checks the other Linux architecture; `verify/linux.sh --shell` leaves you in the provisioned box.

Run the checks for the platform a change touches, both when it touches both. `verify/macos-vm.sh` has to pass before `macos.sh` runs on a real Mac.

## What every check asserts

- **A tool runs, not merely exists.** Each declared tool answers its version command; a language server without one answers an LSP initialize request.
- **Links resolve into the repository.** `readlink -f` on both sides, so a copy that happens to match does not pass.
- **Non-interactive shells find the tools**: login bash, a bash that reads only `~/.bashrc` (`ssh host command`), `zsh -c`, fish. That is what an agent hook or a herdr pane gets.
- **A second run changes nothing**: the same generation, no new backup files, no duplicated shell block, no reinstalled Nix.
- **A skipped step says so.** No herdr server runs in a container or a fresh VM, so the herdr plugin step has to report its skip.
- **Upstream Nix**, not Determinate Nix.

## What stays on the host

Each check copies only the files the git flake sees (git's index, with their working-tree contents), so a new file has to be staged first, exactly as before a switch. Ignored files, including secrets (`.env*`, `.ssh/private.conf`) and eval transcripts, never reach a container, a guest or the Nix store.

## Why macOS has two checks

Linux containerises, so the Linux check is the real thing. macOS does not: a real macOS guest is a VM from a ~25 GB image, right for the rehearsal before a switch and too slow for every edit. So `verify/macos.sh` asserts the configuration itself in about a minute, and `verify/macos-vm.sh` switches a real guest.
