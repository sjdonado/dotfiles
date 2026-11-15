# Migrating from Nix

The migration is staged and recoverable until Nix itself is removed:

```sh
./setup/verify/macos.sh
./sync.sh --migrate-from-nix
./sync.sh --uninstall-nix
```

Before running the migration, update every declared account's checkout to the same candidate commit. The migration reports mismatches without pulling or switching a checkout.

`--migrate-from-nix` checks account checkout revisions before mutation, replaces the Nix-owned Homebrew launcher and immutable tap links with an official Homebrew checkout, applies shell provisioning, checks every account, and records evidence for the exact working tree. Homebrew detachment precedes package installation because the Nix-managed taps are read-only. Cellar, Caskroom, applications, and user data are preserved. Failed prerequisites stop dependent steps. This stage never removes Nix.

`--uninstall-nix` requires that evidence and repeats every-account checks. It first runs the installed nix-darwin uninstaller when present, checks every account again, then invokes `/nix/nix-installer uninstall`. The uninstallers ask for administrator authentication. After removal it enables non-zapping Homebrew cleanup and checks every account without Nix, mise, or Linuxbrew paths.

An empty, unmounted `/nix` directory may remain until reboot and does not mean Nix is still installed. Remaining files or a mounted Nix volume block completion. If Nix removal succeeded but finalization failed, update every account to the same corrected candidate, rerun `--migrate-from-nix` to apply and verify its links, then rerun `--uninstall-nix`. With no installer present, the latter verifies removal and resumes cleanup and account checks.

Before Nix removal, rollback uses the existing Nix generation or the retained `.pre-shell` and Homebrew-link backups. After removal, rollback requires reinstalling Nix and checking out the pre-removal commit.

On existing Ubuntu installations, `setup.sh --linux` installs standalone replacements with a clean PATH, preserves Nix-linked user tools and shell files as backups, and upgrades OpenCode v1 to v2. Setup and sync use their own checkout, including Coder checkouts outside `~/.config/dotfiles`. Setup does not uninstall Nix or remove system startup hooks. Keep Nix installed until standalone tool paths and shell startup pass verification; the migration and uninstall flags above remain macOS-only.


## Cleanup and local settings

Normal macOS sync disables Homebrew auto-update. Upgrade is explicit. Cleanup uses `brew bundle cleanup --force`, never `--zap`, and is enabled only during the completed migration or when `DOTFILES_BREW_CLEANUP=1` is set deliberately.

Hex is installed through Homebrew, but its settings remain local to each account under `~/Library/Application Support/hex/`. Dotfiles does not link or synchronize its preferences, vocabulary, credentials, models, or history. If an account still has the former settings symlink, quit Hex and replace that symlink with a copy of its target before pulling the removal; if already pulled, recover the local `settings.json.pre-shell` backup when available.
