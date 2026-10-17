#!/bin/sh
# macOS setup: install Nix, then apply this repository's declaration with nix-darwin. Everything the Mac gets (packages, Homebrew casks and App Store apps, links, defaults, launch agents, the login shell, setup steps) is in flake.nix and nix/; this script only bootstraps. Idempotent.
# Each step checks whether it is already done and skips if so, so the same command sets up a new Mac and re-applies the declaration on this one:
#
#   ~/.config/dotfiles/macos.sh
#
# Upgrades are `nix run ~/.config/dotfiles#upgrade`. The configuration is chosen by hostname (darwinConfigurations in flake.nix). After a switch, verify/macos-host.sh checks the result.
#
# Manual steps that remain are listed in README.md ("Manual steps").
set -eu
[ "$#" -eq 0 ] || { echo "macos.sh takes no arguments: every step checks whether it is needed" >&2; exit 2; }

# Fixed: the configuration links into this path (nix/home/common.nix).
DOTFILES="$HOME/.config/dotfiles"
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

# Homebrew builds BrowserRouter from source with swiftc, which needs the command line tools.
if ! xcode-select -p >/dev/null 2>&1; then
  log "Installing Xcode Command Line Tools (finish the dialog; this waits for it)..."
  xcode-select --install || true
  until xcode-select -p >/dev/null 2>&1; do sleep 10; done
fi

# nix-darwin writes /etc/shells itself and refuses to activate over one it does not recognise, which an earlier setup leaves behind by appending a shell to it. Such a file is kept as /etc/shells.before-nix-darwin, the name nix-darwin asks for, and put back if the switch fails.
moved_shells=0
if grep -qv -e '^#' -e '^$' -e '^/bin/' /etc/shells && [ ! -L /etc/shells ]; then
  log "Handing /etc/shells to nix-darwin (kept as /etc/shells.before-nix-darwin)..."
  sudo mv /etc/shells /etc/shells.before-nix-darwin
  moved_shells=1
fi

# nix-homebrew links its pinned taps as /opt/homebrew/Library/Taps and refuses to activate over a real directory there, which any Homebrew that ran `brew tap` leaves behind. That directory is kept as Taps.pre-nix and put back if the switch fails. Formulas installed from a tap the declaration drops stay installed; brew can no longer upgrade them.
TAPS=/opt/homebrew/Library/Taps
moved_taps=0
if [ -d "$TAPS" ] && [ ! -L "$TAPS" ]; then
  [ ! -e "$TAPS.pre-nix" ] || { echo "$TAPS.pre-nix already exists; move one of them aside and re-run" >&2; exit 1; }
  log "Handing $TAPS to nix-homebrew (kept as $TAPS.pre-nix)..."
  sudo mv "$TAPS" "$TAPS.pre-nix"
  moved_taps=1
fi

# darwin-rebuild comes from the pinned nix-darwin input, as in `nix run .#sync`.
config="$(scutil --get LocalHostName)"
log "Applying the declaration (darwin-rebuild switch, $config)..."
if ! sudo -H /nix/var/nix/profiles/default/bin/nix --extra-experimental-features 'nix-command flakes' run --inputs-from "$DOTFILES" nix-darwin#darwin-rebuild -- switch --flake "$DOTFILES#$config"; then
  if [ "$moved_shells" = 1 ] && [ ! -e /etc/shells ]; then sudo mv /etc/shells.before-nix-darwin /etc/shells; fi
  if [ "$moved_taps" = 1 ] && [ ! -e "$TAPS" ]; then sudo mv "$TAPS.pre-nix" "$TAPS"; fi
  echo "The switch failed; nothing after the failing step was applied. See the output above." >&2
  exit 1
fi

log "Done. Open a new terminal so PATH and the login shell apply. Remaining manual steps: README.md, \"Manual steps\"."
