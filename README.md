# Dotfiles

Shell provisioning for macOS and Ubuntu. macOS uses Homebrew for conventional packages. Linux uses apt plus explicit guarded installers. Nix, home-manager, nix-darwin, mise, and Linuxbrew are not required.

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

`hosts/macos.sh` maps a hostname to its accounts. The first account is the primary account and the only account allowed to install packages, change shared machine state, upgrade, clean up, or migrate. Other accounts can run `sync.sh --check` only.

Each account has its own clone at `~/.config/dotfiles`. A primary-account sync invokes the other account's `sync.sh` from that clone so every link resolves into the owning account's checkout. All account checkouts must be on the same commit before Nix removal.

To add an account, add it to `hosts/macos.sh`, clone this repository into that account's `~/.config/dotfiles`, and sync from the primary account. To remove an account, remove it from the host declaration and sync before deleting the macOS account.

## Migrating an existing Nix Mac

The migration is staged and recoverable until Nix itself is removed:

```sh
./verify/macos.sh
./sync.sh --migrate-from-nix
./sync.sh --uninstall-nix
```

`--migrate-from-nix` applies shell provisioning, checks every account, replaces the Nix-owned Homebrew launcher and immutable tap links with an official Homebrew checkout, preserves Cellar, Caskroom, applications, and user data, checks every account again, and records evidence for the exact working tree. It stops with Nix still installed.

`--uninstall-nix` requires that evidence and repeats every-account checks before invoking `/nix/nix-installer uninstall`. The uninstaller asks for administrator authentication. After removal it enables non-zapping Homebrew cleanup and checks every account without Nix, mise, or Linuxbrew paths.

Before Nix removal, rollback uses the existing Nix generation or the retained `.pre-shell` and Homebrew-link backups. After removal, rollback requires reinstalling Nix and checking out the pre-removal commit.

## Verification

```sh
./verify/macos.sh
./verify/linux.sh --platform linux/arm64
./verify/linux.sh --platform linux/amd64
```

The macOS check is non-mutating and uses temporary fixtures. Linux provisions a bare Ubuntu container twice. See `verify/README.md`.

## Managed configuration

Tracked configuration is linked into each account's home. An unmanaged destination is preserved once as `<path>.pre-shell`; a correct link is a no-op. `sync.sh --check` requires links to resolve into this checkout rather than merely comparing file contents.

Handy's preferences are tracked in `macos/handy/settings_store.json`. Models, recordings, history, and macOS permissions remain local to each account. Keep API keys empty in the tracked file.

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
