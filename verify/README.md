# Verifying provisioning

`verify/macos.sh` is a non-mutating preflight. It checks shell syntax, declarations, account guards, link idempotency, installer selection, launch agent rendering, Homebrew command order, Homebrew detachment, and Nix uninstall gates. It writes only to a temporary home directory.

`verify/linux.sh` provisions a bare Ubuntu 24.04 container twice, runs `sync.sh --check` after each application, and rejects duplicate backups or shell references to Nix, mise, and Linuxbrew. Run both architectures when the change affects Linux:

```sh
verify/linux.sh --platform linux/arm64
verify/linux.sh --platform linux/amd64
```

After applying on a real Mac, `sync.sh --check` verifies packages, links, settings, ownership, agents, commands, and shell independence. `sync.sh --migrate-from-nix` detaches Homebrew and records passing evidence. `sync.sh --uninstall-nix` accepts only evidence from the same working tree and checks every declared account before and after removal.
