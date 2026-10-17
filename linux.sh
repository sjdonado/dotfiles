#!/usr/bin/env bash
# Linux setup on any distribution: install Nix, then apply this repository's declaration with home-manager. Everything the box gets (packages, links, shell files, setup steps) is in flake.nix and nix/; this script only bootstraps. Idempotent: a second run installs nothing and switches to the same generation.
#
#   curl -fsSL https://raw.githubusercontent.com/sjdonado/dotfiles/main/linux.sh | bash
#
# Upgrades are `nix run ~/.config/dotfiles#upgrade`, not this script.
#
# NOT handled here (sensitive, do manually):
#   - Claude Code, Codex, OpenCode provider and MCP authentication
#   - any secrets in .env or ~/.ssh
set -euo pipefail

DOTFILES_REPO="https://github.com/sjdonado/dotfiles"
# Fixed: the configuration links into this path (nix/home/common.nix).
DOTFILES="$HOME/.config/dotfiles"
# The Determinate Systems installer, pinned. --prefer-upstream-nix makes it install upstream Nix, as macos.sh does; without it, this version installs Determinate Nix. It uninstalls with /nix/nix-installer uninstall.
NIX_INSTALLER="https://install.determinate.systems/nix/tag/v3.23.2"
NIX_PROFILE_SCRIPT=/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

log() { printf '\n==> %s\n' "$*"; }

if [ ! -e "$NIX_PROFILE_SCRIPT" ]; then
  log "Installing Nix..."
  # Without systemd (a container, most Coder workspaces) the installer can only set Nix up root-only, and the daemon is started below instead.
  flags=(--no-confirm --prefer-upstream-nix)
  [ -d /run/systemd/system ] || flags+=(--init none)
  # The installer re-runs itself through sudo, which drops the environment, so extra nix.conf lines are passed as a flag.
  [ -z "${NIX_INSTALLER_EXTRA_CONF:-}" ] || flags+=(--extra-conf "$NIX_INSTALLER_EXTRA_CONF")
  curl -fsSL "$NIX_INSTALLER" | sh -s -- install linux "${flags[@]}"
fi

# Without systemd nothing starts the daemon, including after a restart, which is when this script runs again.
if [ ! -d /run/systemd/system ] && ! /nix/var/nix/profiles/default/bin/nix store info --store daemon >/dev/null 2>&1; then
  log "Starting the Nix daemon (no systemd here)..."
  sudo sh -c 'nohup /nix/var/nix/profiles/default/bin/nix-daemon >/var/log/nix-daemon.log 2>&1 &'
  for _ in $(seq 1 50); do /nix/var/nix/profiles/default/bin/nix store info --store daemon >/dev/null 2>&1 && break; sleep 0.2; done
  /nix/var/nix/profiles/default/bin/nix store info --store daemon >/dev/null 2>&1 \
    || { echo "nix-daemon did not start; see /var/log/nix-daemon.log" >&2; exit 1; }
fi

# shellcheck source=/dev/null
. "$NIX_PROFILE_SCRIPT"

if [ -d "$DOTFILES/.git" ]; then
  log "Updating dotfiles..."
  nix run nixpkgs#git -- -C "$DOTFILES" pull --ff-only || log "  pull failed; switching the checkout as it is"
elif [ ! -e "$DOTFILES/flake.nix" ]; then
  log "Cloning dotfiles..."
  mkdir -p "$(dirname "$DOTFILES")"
  nix run nixpkgs#git -- clone "$DOTFILES_REPO" "$DOTFILES"
fi

log "Applying the declaration (home-manager switch)..."
nix run "$DOTFILES#sync"

cat <<'NOTE'

==> Done. Open a new shell (or `exec fish`) so PATH and shell changes apply.

Manual steps (sensitive, not scripted):
  1. Authenticate OpenCode and its MCP servers: opencode auth login; opencode mcp auth <server>
     Claude Code and Codex log in on first start.
  2. Copy any private .env values and SSH keys by hand.

Connect from your local terminal: herdr --remote <user>@<this-host>
NOTE
