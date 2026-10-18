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

# The configuration for this Mac lists its accounts; the first is the primary account, which owns Nix's setup, Homebrew and the system settings. This runs from that account only, checked before anything changes, so removing any other account later leaves everything working. Read from flake.nix directly: no Nix is needed yet.
config="$(scutil --get LocalHostName)"
accounts="$(sed -n "s/.*\"$config\" = darwin \[\(.*\)\] \[.*/\1/p" "$DOTFILES/flake.nix" | tr -d '"')"
primary="$(echo $accounts | cut -d' ' -f1)"
[ -n "$primary" ] || { echo "flake.nix has no darwinConfigurations entry for this Mac ($config)" >&2; exit 1; }
if [ "$(id -un)" != "$primary" ]; then
  echo "Run this from the primary account, $primary (flake.nix, darwinConfigurations.$config): it owns Nix's setup, Homebrew and the system settings." >&2
  exit 1
fi

# A login shell that no longer exists (one that lived in a Nix store that was removed) makes every new terminal fail, so it is reset to /bin/zsh now; the switch then keeps zsh.
for u in $accounts; do
  shell="$(dscl . -read "/Users/$u" UserShell 2>/dev/null | awk '{print $2}')"
  [ -n "$shell" ] && [ ! -x "$shell" ] || continue
  log "Resetting the login shell of $u to /bin/zsh ($shell is gone)..."
  sudo dscl . -create "/Users/$u" UserShell /bin/zsh
done

if [ ! -e "$NIX_PROFILE_SCRIPT" ]; then
  log "Installing Nix..."
  curl -fsSL "$NIX_INSTALLER" | sh -s -- install --no-confirm --prefer-upstream-nix
fi
# shellcheck source=/dev/null
. "$NIX_PROFILE_SCRIPT"
nix() { command nix --extra-experimental-features 'nix-command flakes' "$@"; }
if nix --version | grep -qi determinate; then
  echo "This Mac has Determinate Nix, which manages nix.conf itself; nix/darwin/system.nix expects upstream Nix. Uninstall it (/nix/nix-installer uninstall) and re-run this script." >&2
  exit 1
fi

# After Nix is reinstalled, launchd can keep the previous daemon job loaded, and that job names a nix-daemon in a store that no longer exists, so it restarts forever and every nix command fails. Reloading the job from the installed plist fixes it; launchd may need a moment to drop the old job first.
PLIST=/Library/LaunchDaemons/org.nixos.nix-daemon.plist
if ! nix store info --store daemon >/dev/null 2>&1; then
  log "Restarting the Nix daemon..."
  sudo launchctl bootout system/org.nixos.nix-daemon 2>/dev/null || true
  for _ in $(seq 1 25); do sudo launchctl bootstrap system "$PLIST" 2>/dev/null && break; sleep 0.4; done
  for _ in $(seq 1 50); do nix store info --store daemon >/dev/null 2>&1 && break; sleep 0.2; done
  nix store info --store daemon >/dev/null 2>&1 || { echo "nix-daemon did not start; see /var/log/nix-daemon.log and $PLIST" >&2; exit 1; }
fi

# Homebrew refuses to manage files another account owns, and nix-homebrew does not change the owner of an existing /opt/homebrew. So everything under the prefix, and the app bundles in /Applications that another account installed (or one that was deleted, which shows as a bare UID), are handed to the primary account.
if [ -d /opt/homebrew ] && [ -n "$(sudo find /opt/homebrew ! -user "$primary" -print -quit)" ]; then
  log "Handing /opt/homebrew to $primary..."
  sudo chown -R "$primary" /opt/homebrew
fi
primary_uid="$(id -u "$primary")"
for app in /Applications/*.app; do
  [ -e "$app" ] || continue
  uid="$(/usr/bin/stat -f %u "$app")"
  [ "$uid" -ge 501 ] && [ "$uid" != "$primary_uid" ] || continue
  log "Handing $app to $primary..."
  sudo chown -R "$primary" "$app"
done

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
log "Applying the declaration (darwin-rebuild switch, $config)..."
if ! sudo -H /nix/var/nix/profiles/default/bin/nix --extra-experimental-features 'nix-command flakes' run --inputs-from "$DOTFILES" nix-darwin#darwin-rebuild -- switch --flake "$DOTFILES#$config"; then
  if [ "$moved_shells" = 1 ] && [ ! -e /etc/shells ]; then sudo mv /etc/shells.before-nix-darwin /etc/shells; fi
  if [ "$moved_taps" = 1 ] && [ ! -e "$TAPS" ]; then sudo mv "$TAPS.pre-nix" "$TAPS"; fi
  echo "The switch failed; nothing after the failing step was applied. See the output above." >&2
  exit 1
fi

log "Done. Open a new terminal so PATH and the login shell (zsh) apply. Remaining manual steps: README.md, \"Manual steps\"."
