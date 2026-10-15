# Verifying a provisioning change

A change to `flake.nix` or `nix/` is checked by applying it somewhere disposable, never by reading it and never first on a real machine. A real machine is already half provisioned, so it hides what a fresh one would hit, and a failed run there leaves residue.

| check | what it proves | needs | time |
| --- | --- | --- | --- |
| `verify/packages/run.sh` | every declared package evaluates, is prebuilt on cache.nixos.org, and no two packages provide the same file, for aarch64-darwin, aarch64-linux and x86_64-linux | Docker | ~2 min |
| `verify/linux/run.sh` | `linux.sh` on a bare Ubuntu container installs Nix and switches, twice, and the result passes `verify/linux/verify.sh` | Docker | ~2 min per run |
| `verify/macos/run.sh` | the macOS configuration evaluates (and builds, when this Mac has Nix) and declares every link, step, agent, setting and Homebrew item | Docker, or Nix | ~1 min |
| `verify/macos-vm/run.sh` | `macos.sh` on a disposable macOS VM installs Nix and switches for real, twice, and the result passes `verify/macos-vm/verify.sh` | Nix on this Mac, for tart | tens of minutes |

Run the checks for the platform a change touches, both when it touches both. The VM rehearsal has to pass before a switch runs on a real Mac.

## Why macOS has two checks

Linux containerises, so the Linux check is the real thing: bare Ubuntu, `linux.sh`, the same Nix installer and the same switch a box gets.

macOS does not containerise. A real macOS guest means a VM ([tart](https://tart.run) on Virtualization.framework) from a ~25 GB image, which is right for the rehearsal before a host switch and too slow for every edit. So the fast loop asserts the configuration itself: it evaluates the darwin configuration and checks what a switch would apply, and with Nix on the Mac it also builds the system closure without activating it, which is where a package that does not build or a profile collision shows up.

## What every check shares

- **Run twice.** A second switch must change nothing: the same generation, no new backup files, no duplicated shell block, no reinstalled Nix.
- **Assert the link target, not the contents.** `readlink -f` both sides, so a copy that happens to match does not pass.
- **A tool runs, not merely exists.** Each declared tool has to answer its version command; a language server without one has to answer an LSP initialize request.
- **A skipped step says so.** No herdr server runs in a container or a fresh VM, so each check asserts that the herdr plugin step reported itself skipped.
- **Secrets stay on the host.** Each check copies the working tree without `.git`, `.env*` and `.ssh/private.conf`, so the flake sees uncommitted files and never a secret.
