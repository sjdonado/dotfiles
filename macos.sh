#!/bin/sh
# macOS setup: install Nix, then apply this repository's declaration with nix-darwin. Everything the Mac gets (packages, Homebrew casks and App Store apps, links, defaults, launch agents, the login shell, setup steps) is in flake.nix and nix/; this script only bootstraps. Idempotent.
#
#   ~/.config/dotfiles/macos.sh             # install Nix if missing, then switch
#   ~/.config/dotfiles/macos.sh --nix-only  # install Nix and stop: no package, link or setting changes
#
# Upgrades are `nix run ~/.config/dotfiles#upgrade`, not this script. The configuration is chosen by hostname (darwinConfigurations in flake.nix); DARWIN_CONFIG overrides it.
#
# Manual steps that remain are listed in README.md ("Manual steps").
set -eu

# Fixed: the configuration links into this path (nix/home/common.nix).
DOTFILES="$HOME/.config/dotfiles"
NIX_ONLY=0
case "${1:-}" in
  --nix-only) NIX_ONLY=1 ;;
  "") ;;
  *) echo "usage: $0 [--nix-only]" >&2; exit 2 ;;
esac
# The Determinate Systems installer, pinned. --prefer-upstream-nix makes it install upstream Nix; without it, this version installs Determinate Nix, whose own daemon manages nix.conf, which nix-darwin does here. It survives macOS updates and uninstalls with /nix/nix-installer uninstall.
NIX_INSTALLER="https://install.determinate.systems/nix/tag/v3.23.2"
NIX_PROFILE_SCRIPT=/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

log() { printf '\n==> %s\n' "$*"; }

[ -e "$DOTFILES/flake.nix" ] || { echo "clone https://github.com/sjdonado/dotfiles to $DOTFILES first" >&2; exit 1; }

if [ ! -e "$NIX_PROFILE_SCRIPT" ]; then
  log "Installing Nix..."
  curl -fsSL "$NIX_INSTALLER" | sh -s -- install --no-confirm --prefer-upstream-nix
fi
# shellcheck source=/dev/null
. "$NIX_PROFILE_SCRIPT"
if nix --version | grep -qi determinate; then
  echo "This Mac has Determinate Nix, which manages nix.conf itself; nix/darwin/system.nix expects upstream Nix. Uninstall it (/nix/nix-installer uninstall) and re-run this script." >&2
  exit 1
fi

if [ "$NIX_ONLY" = 1 ]; then
  log "Nix is installed ($(nix --version)). Nothing else changed; run $0 without --nix-only to switch."
  exit 0
fi

# Homebrew builds BrowserRouter from source with swiftc, which needs the command line tools.
if ! xcode-select -p >/dev/null 2>&1; then
  log "Installing Xcode Command Line Tools (finish the dialog, then re-run this script)..."
  xcode-select --install || true
  exit 1
fi

# nix-darwin writes /etc/shells itself and refuses to activate over one it does not recognise, which an earlier setup leaves behind by appending a shell to it. Such a file is kept as /etc/shells.before-nix-darwin, the name nix-darwin asks for, and put back if the switch fails.
moved_shells=0
if grep -qv -e '^#' -e '^$' -e '^/bin/' /etc/shells && [ ! -L /etc/shells ]; then
  log "Handing /etc/shells to nix-darwin (kept as /etc/shells.before-nix-darwin)..."
  sudo mv /etc/shells /etc/shells.before-nix-darwin
  moved_shells=1
fi

# darwin-rebuild comes from the pinned nix-darwin input, as in `nix run .#switch`.
config="${DARWIN_CONFIG:-$(scutil --get LocalHostName)}"
log "Applying the declaration (darwin-rebuild switch, $config)..."
if ! sudo -H /nix/var/nix/profiles/default/bin/nix --extra-experimental-features 'nix-command flakes' run --inputs-from "$DOTFILES" nix-darwin#darwin-rebuild -- switch --flake "$DOTFILES#$config"; then
  if [ "$moved_shells" = 1 ] && [ ! -e /etc/shells ]; then sudo mv /etc/shells.before-nix-darwin /etc/shells; fi
  echo "The switch failed; nothing after the failing step was applied. See the output above." >&2
  exit 1
fi

log "Done. Open a new terminal so PATH and the login shell apply. Remaining manual steps: README.md, \"Manual steps\"."
