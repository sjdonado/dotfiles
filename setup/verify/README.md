# Verifying provisioning

`setup/verify/macos.sh` is a non-mutating preflight. It checks shell syntax, declarations, account guards, link idempotency, installer selection, launch agent rendering, Homebrew command order, Homebrew detachment, and Nix uninstall gates. It writes only to a temporary home directory.

`setup/verify/linux.sh` provisions a bare Ubuntu 24.04 container twice, runs `sync.sh --check` after each application, and rejects duplicate backups or shell references to Nix, mise, and Linuxbrew. Run both architectures when the change affects Linux:

```sh
setup/verify/linux.sh --platform linux/arm64
setup/verify/linux.sh --platform linux/amd64
```

After applying on a real Mac, `sync.sh --check` verifies packages, links, settings, ownership, agents, commands, and shell independence. `sync.sh --migrate-from-nix` detaches Homebrew and records passing evidence. `sync.sh --uninstall-nix` accepts only evidence from the same working tree and checks every declared account before and after removal.

The Linux verifier mounts its script as a file so child installers cannot consume later assertions through stdin. A complete run reaches both `Linux provisioning passed twice` and `Existing Nix profile and OpenCode v1 replacement passed`; an early zero exit is incomplete evidence.

The Linux container uses Coder's nested checkout path, applies setup twice, then repeats setup with a Nix-linked login profile and user tool plus an obsolete OpenCode v1 executable. It checks that standalone tools and clean login and non-interactive shells still work.
