# Dotfiles

Shell provisioning for macOS and Ubuntu. macOS uses Homebrew for conventional packages. Linux uses apt plus explicit guarded installers. Mise is available globally through Homebrew on macOS and a pinned upstream installer on Linux. Provisioning does not depend on mise-managed runtimes or shims. Nix, home-manager, nix-darwin, and Linuxbrew are not required.

## Setup and sync

Clone this repository to `~/.config/dotfiles`, then run:

```sh
./setup.sh
```

The platform comes from `uname`. `--macos` and `--linux` assert the expected platform. Linux can also bootstrap without an existing clone:

```sh
curl -fsSL https://raw.githubusercontent.com/sjdonado/dotfiles/main/setup.sh | bash
```

Day-to-day commands:

```sh
./sync.sh             # apply, then check
./sync.sh --upgrade   # update package sources and packages, apply, then check
./sync.sh --check     # read-only host checks
```

macOS packages and applications are declared in `Brewfile`. Ubuntu packages are in `packages/linux-apt.txt`; pinned or vendor-managed Linux tools are documented in `packages/linux-installers.tsv`. Links, platform behavior, and installers live under `lib/`. Add or remove packages in those declarations, then run `sync.sh`.

Normal macOS sync disables Homebrew auto-update. Upgrade is explicit. Cleanup uses `brew bundle cleanup --force`, never `--zap`, and is enabled only during the completed migration or when `DOTFILES_BREW_CLEANUP=1` is set deliberately.

Claude Code and Codex are vendor-managed exceptions so their self-update support and T3 Code integration continue to work. Sync installs either CLI only when its expected vendor target is missing.

## Multiple macOS accounts

`hosts/macos.sh` maps a hostname to its accounts. The first account is the primary account and the only account allowed to install shared packages, change shared machine state, upgrade, clean up, or migrate. Other declared accounts can run `setup.sh` or `sync.sh` to install their per-user tools and configuration, and `sync.sh --check` to verify their state. Shared packages must already be installed by the primary account.

Each account has its own clone at `~/.config/dotfiles`. A primary-account sync invokes the other account's `sync.sh` from that clone so every link resolves into the owning account's checkout. All account checkouts must be on the same commit before Nix removal.

To add an account, add it to `hosts/macos.sh`, clone this repository into that account's `~/.config/dotfiles`, and sync from the primary account. To remove an account, remove it from the host declaration and sync before deleting the macOS account.

## Migrating an existing Nix Mac

The migration is staged and recoverable until Nix itself is removed:

```sh
./verify/macos.sh
./sync.sh --migrate-from-nix
./sync.sh --uninstall-nix
```

Before running the migration, update every declared account's checkout to the same candidate commit. The migration reports mismatches without pulling or switching a checkout.

`--migrate-from-nix` checks account checkout revisions before mutation, replaces the Nix-owned Homebrew launcher and immutable tap links with an official Homebrew checkout, applies shell provisioning, checks every account, and records evidence for the exact working tree. Homebrew detachment precedes package installation because the Nix-managed taps are read-only. Cellar, Caskroom, applications, and user data are preserved. Failed prerequisites stop dependent steps. This stage never removes Nix.

`--uninstall-nix` requires that evidence and repeats every-account checks. It first runs the installed nix-darwin uninstaller when present, checks every account again, then invokes `/nix/nix-installer uninstall`. The uninstallers ask for administrator authentication. After removal it enables non-zapping Homebrew cleanup and checks every account without Nix, mise, or Linuxbrew paths.

An empty, unmounted `/nix` directory may remain until reboot and does not mean Nix is still installed. Remaining files or a mounted Nix volume block completion. If Nix removal succeeded but finalization failed, update every account to the same corrected candidate, rerun `--migrate-from-nix` to apply and verify its links, then rerun `--uninstall-nix`. With no installer present, the latter verifies removal and resumes cleanup and account checks.

Before Nix removal, rollback uses the existing Nix generation or the retained `.pre-shell` and Homebrew-link backups. After removal, rollback requires reinstalling Nix and checking out the pre-removal commit.

On existing Ubuntu installations, `setup.sh --linux` installs standalone replacements with a clean PATH, preserves Nix-linked user tools and shell files as backups, and upgrades OpenCode v1 to v2. Setup and sync use their own checkout, including Coder checkouts outside `~/.config/dotfiles`. Setup does not uninstall Nix or remove system startup hooks. Keep Nix installed until standalone tool paths and shell startup pass verification; the migration and uninstall flags above remain macOS-only.

## Verification

```sh
./verify/macos.sh
./verify/linux.sh --platform linux/arm64
./verify/linux.sh --platform linux/amd64
```

The macOS check is non-mutating and uses temporary fixtures. Linux provisions a bare Ubuntu container twice. See `verify/README.md`.

## Managed configuration

Tracked configuration is linked into each account's home. An unmanaged destination is preserved once as `<path>.pre-shell`; a correct link is a no-op. `sync.sh --check` requires links to resolve into this checkout rather than merely comparing file contents.

Hex's preferences are tracked in `macos/hex/settings.json` and linked to `~/Library/Application Support/hex/settings.json`. Quit Hex before committing and pushing settings, and quit it before pulling changes in another account, then reopen it. Each account uses its own clone. Models, recordings, history, local API credentials, and macOS permissions remain local to each account. Keep credential fields empty in the tracked settings file.

After pulling the Hex configuration into an account's clone for the first time, run `./sync.sh` in that account to create the preferences link. For later settings updates, quit Hex, run `git pull --ff-only` in that clone, and reopen Hex; the existing link picks up the changes without another sync. Commit and push settings changes from the account where they were made before pulling them elsewhere.

The editor is Zed with T3 Code. Neovim remains installed as the terminal editor. BrowserRouter is installed from `sjdonado/tap`, copied to `~/Applications`, registered with Launch Services, and configured from `macos/browser-router.json`.

## Manual steps

- Authenticate Claude Code, Codex, OpenCode, `gh`, and MCP servers in each account.
- Keep `.env` values, SSH keys, and other secrets outside provisioning.
- Install App Store applications manually.
- Choose default file applications manually when macOS ignores `duti`.
- Open `~/Applications/BrowserRouter.app` once and accept the default-browser prompt.
- After fully removing Tailscale, remove any remaining VPN configuration and Keychain entries manually.

## Agent harness

OpenCode is the primary daily harness. Claude Code, Codex, and Pi remain available. Shared instructions and skills live under `agents/`; harness experiments and benchmarks are documented in `agents/README.md`, `pi/README.md`, and `evals/README.md`.
