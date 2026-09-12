#!/bin/sh
set -euo pipefail

# helpers
have() { command -v "$1" >/dev/null 2>&1; }
log()  { printf '\n==> %s\n' "$*"; }
usage() { echo "Usage: $0 [--install]"; }
link_managed() {
  src=$1 dst=$2
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then return; fi
    mv "$dst" "$dst.backup.$(date +%s)"
  fi
  ln -snf "$src" "$dst"
}

INSTALL=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --install) INSTALL=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
  shift
done

if [ "$INSTALL" = 1 ]; then
  # Xcode CLT (needed for Homebrew)
  if ! pkgutil --pkg-info=com.apple.pkg.CLTools_Executables >/dev/null 2>&1 \
     && ! xcode-select -p >/dev/null 2>&1; then
    log "Installing Xcode Command Line Tools..."
    xcode-select --install || true
    log "If a GUI prompt appeared, finish it, then re-run this script if needed."
  fi

  if ! have brew; then
    log "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
else
  log "Skipping dependency installation (use --install to enable)."
fi

# Make brew available in THIS shell (Apple Silicon uses /opt/homebrew)
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Sanity check when dependency installation was requested.
if [ "$INSTALL" = 1 ] && ! have brew; then
  echo "brew not found on PATH after install. Aborting." >&2
  exit 1
fi

# base dirs
log "Creating base directories..."
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.ssh"
mkdir -p "$HOME/.docker"
mkdir -p "$HOME/Library/Keyboard Layouts"
mkdir -p "$HOME/.config/ghostty/themes"
mkdir -p "$HOME/.config/fish/functions"
mkdir -p "$HOME/.config/bat"
PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"
export PATH

log "Linking local bin..."
ln -snf "$PWD/bin/"* "$HOME/.local/bin" 2>/dev/null || true
# Prune links left behind by a script this repo no longer ships, so a machine
# provisioned before a removal does not keep a dangling command on PATH.
for f in "$HOME/.local/bin"/*; do
  [ -L "$f" ] || continue
  case "$(readlink "$f")" in "$PWD/bin/"*) [ -e "$f" ] || rm -f "$f" ;; esac
done

# Install dependencies from Brewfile only when requested.
if [ "$INSTALL" = 1 ]; then
  if [ -f "$PWD/Brewfile" ]; then
    log "Installing dependencies from Brewfile..."
    brew bundle --file="$PWD/Brewfile" || true
  else
    log "No Brewfile found, skipping."
  fi

  # ttt, worktrunk, uv, bun and openspec come from mise.toml instead of the
  # Brewfile, so one declaration covers this machine and a Linux box. Homebrew
  # installs mise itself and its fish vendor_conf.d activates it, so nothing
  # here has to touch PATH.
  log "Installing tools from mise.toml..."
  if have mise; then
    mise trust --quiet "$PWD/mise.toml" >/dev/null 2>&1 || true
    mise install --quiet || log "  mise install failed; ttt, wt, uv, bun and openspec may be missing."
  else
    log "  mise missing; ttt, wt, uv, bun and openspec will be absent."
  fi
fi

log "Setting up Ghostty config..."
ln -snf "$PWD/ghostty/config" "$HOME/.config/ghostty/config"
ln -snf "$PWD/ghostty/themes/"* "$HOME/.config/ghostty/themes/" 2>/dev/null || true

# BrowserRouter is the default browser, and lives in its own repository:
# https://github.com/sjdonado/browser-router
#
# The config is linked from here rather than seeded, so the routing rules are
# tracked with the rest of the dotfiles. Link before installing: the installer
# only writes a starting config when there is none, and the link counts as one.
log "Setting up BrowserRouter (the default browser)..."
mkdir -p "$HOME/.config/browser-router"
ln -snf "$PWD/macos/browser-router.json" "$HOME/.config/browser-router/config.json"

# Rebuilds and re-registers on every run, which is how it picks up an upstream
# change. --no-default-prompt keeps provisioning non-interactive; making it the
# default browser is a one-time system prompt, answered by running the installer
# by hand or by opening ~/Applications/BrowserRouter.app.
curl -fsSL https://raw.githubusercontent.com/sjdonado/browser-router/main/install.sh \
  | sh -s -- --no-default-prompt \
  || log "  BrowserRouter install failed; links will open in whatever macOS considers the default browser"


log "Setting fish shell..."
if [ "$INSTALL" = 1 ] && ! have fish; then
  brew install fish
fi

FISH_PATH="$(command -v fish || true)"
if [ -n "$FISH_PATH" ]; then
  # ensure fish is listed in /etc/shells
  if ! grep -qx "$FISH_PATH" /etc/shells; then
    echo "Adding $FISH_PATH to /etc/shells (requires sudo)..."
    echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
  fi

  # change default shell if not already fish (check dscl, not $SHELL subshell var)
  CURRENT_LOGIN_SHELL=$(dscl . -read "$HOME" UserShell 2>/dev/null | awk '{print $2}')
  if [ "$CURRENT_LOGIN_SHELL" != "$FISH_PATH" ]; then
    echo "Changing login shell to fish (requires your password)..."
    chsh -s "$FISH_PATH"
  fi
fi

# link fish config
ln -snf "$PWD/fish/config.fish" "$HOME/.config/fish/config.fish"
ln -snf "$PWD/fish/functions/"* "$HOME/.config/fish/functions/" 2>/dev/null || true

# Relocate fish history to ~/.fish_history via symlink
mkdir -p "$HOME/.local/share/fish"
# migrate legacy non-dotfile location if present
if [ -f "$HOME/fish_history" ] && [ ! -e "$HOME/.fish_history" ]; then
  mv "$HOME/fish_history" "$HOME/.fish_history"
fi
if [ -f "$HOME/.local/share/fish/fish_history" ] && [ ! -L "$HOME/.local/share/fish/fish_history" ]; then
  mv "$HOME/.local/share/fish/fish_history" "$HOME/.fish_history"
fi
if [ ! -e "$HOME/.fish_history" ]; then
  touch "$HOME/.fish_history"
  chmod 600 "$HOME/.fish_history"
fi
ln -snf "$HOME/.fish_history" "$HOME/.local/share/fish/fish_history"

# Agent binaries install only with --install and manage their own updates.
if [ "$INSTALL" = 1 ]; then
  log "Installing rustup (if missing)..."
  if ! have rustup-init && ! have rustup; then
    curl -fsSL https://sh.rustup.rs | sh -s -- -y
    [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
  fi

  log "Installing pnpm (if missing)..."
  if ! have pnpm; then
    # The installer appends its PATH block to the rc of whichever shell it
    # detects, which is not fish. fish/config.fish exports PNPM_HOME itself, so
    # nothing has to be sourced back into this one.
    curl -fsSL https://get.pnpm.io/install.sh | sh -
  fi

  if ! have claude; then
    log "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
  fi
  if ! have opencode; then
    log "Installing OpenCode..."
    curl -fsSL https://opencode.ai/install | bash
  fi
fi

log "Linking Docker config..."
ln -snf "$PWD/docker/config.json" "$HOME/.docker/config.json"

log "Copying custom keyboard layouts..."
cp -Rp "$PWD/macos/ukelele/"* "$HOME/Library/Keyboard Layouts/" 2>/dev/null || true

log "Linking dotfiles..."
if [ -f "$PWD/.ssh/config" ]; then
  ln -snf "$PWD/.ssh/config" "$HOME/.ssh/config"
  chmod 600 "$PWD/.ssh/config"
  [ -f "$PWD/.ssh/private.conf" ] && chmod 600 "$PWD/.ssh/private.conf"
fi
ln -snf "$PWD/git/.gitconfig" "$HOME/.gitconfig" 2>/dev/null || true

# Custom bat themes (GitHub Dark/Light, match agent TUI render); build the cache so
# bat can resolve them by name for BAT_THEME_DARK / BAT_THEME_LIGHT.
mkdir -p "$HOME/.config/bat/themes"
for f in "$HOME/.config/bat/themes/VSCode-Dark.tmTheme" "$HOME/.config/bat/themes/VSCode-Light.tmTheme"; do
  [ -L "$f" ] && rm -f "$f"
done
for f in "$PWD/bat/themes/"*.tmTheme; do
  ln -snf "$f" "$HOME/.config/bat/themes/$(basename "$f")"
done
if have bat; then
  bat cache --build >/dev/null 2>&1 || true
fi

log "Linking TTT config..."
# Only the tracked JSON files are linked, not the directory: TTT keeps plugin
# state here (plugins.ttt.json and plugins/) and rewrites it as plugins are
# installed or toggled, which would land in this repository. Partial settings
# and keybindings files are merged over TTT's own defaults, so these hold
# overrides only.
for f in "$PWD/ttt/"*.json; do
  [ -f "$f" ] || continue
  link_managed "$f" "$HOME/.config/ttt/$(basename "$f")"
done

log "Linking Worktrunk config..."
mkdir -p "$HOME/.config/worktrunk"
ln -snf "$PWD/worktrunk/config.toml" "$HOME/.config/worktrunk/config.toml"

# Remove what this repo used to provision, so a machine set up before the editor
# switch does not keep a dangling ~/.config/nvim or herdr plugins whose directories
# are gone. Stopping the install is not the same as undoing it. Only links this repo
# created are touched: a hand-made config that happens to sit at one of these paths
# is left alone, and the `if` form keeps a false test from tripping `set -e`.
for stale in "$HOME/.config/nvim" "$HOME/Library/Application Support/lazygit/config.yml" \
  "$HOME/.config/herdr/plugins/config/herdr-lazygit/panel.conf"; do
  if [ -L "$stale" ]; then
    case "$(readlink "$stale")" in "$PWD"/*) rm -f "$stale" ;; esac
  elif [ -e "$stale" ]; then
    log "  left in place, not created by this repo: $stale"
  fi
done
if have herdr; then
  for gone in edit-tab lazygit-panel; do
    herdr plugin unlink "$gone" >/dev/null 2>&1 || true
  done
  herdr plugin uninstall Crokily/herdr-lazygit >/dev/null 2>&1 || true
fi

log "Linking Herdr config..."
# NOTE: only symlink config.toml; herdr keeps sockets/logs/session.json in this dir.
mkdir -p "$HOME/.config/herdr"
ln -snf "$PWD/herdr/config.toml" "$HOME/.config/herdr/config.toml"
# Link local Herdr workflow plugins. Requires a running Herdr server.
if have herdr; then
  for plugin_dir in "$PWD/herdr/plugins/"*; do
    [ -f "$plugin_dir/herdr-plugin.toml" ] || continue
    plugin_id="$(basename "$plugin_dir")"
    herdr plugin unlink "$plugin_id" >/dev/null 2>&1 || true
    if herdr plugin link "$plugin_dir" >/dev/null 2>&1; then
      log "  linked Herdr plugin: $plugin_id"
    else
      log "  Herdr not running; later run: herdr plugin link $plugin_dir"
    fi
  done
fi

log "Linking Claude Code, Codex, and OpenCode config..."
mkdir -p "$HOME/.claude" "$HOME/.codex" "$HOME/.agents" "$HOME/.config/opencode"
# Parity with linux.sh. claude/settings.json declares a SessionStart hook running
# herdr's agent-state script, and herdr owns that script. Install it BEFORE the
# symlink: the installer also rewrites settings.json, so running it afterwards
# writes a duplicate hook straight into the tracked dotfiles copy, with an
# absolute path baked in. Skip once present.
if have herdr && [ ! -f "$HOME/.claude/hooks/herdr-agent-state.sh" ]; then
  herdr integration install claude >/dev/null 2>&1 \
    || log "  herdr integration install claude failed; SessionStart hook will no-op"
fi
link_managed "$PWD/claude/settings.json" "$HOME/.claude/settings.json"
link_managed "$PWD/agents/skills" "$HOME/.claude/skills"
link_managed "$PWD/agents/AGENTS.md" "$HOME/.claude/CLAUDE.md"
link_managed "$PWD/agents/skills" "$HOME/.agents/skills"
link_managed "$PWD/agents/AGENTS.md" "$HOME/.codex/AGENTS.md"
# Codex owns ~/.codex/config.toml and rewrites it as you work, adding a
# [projects] entry per trusted directory and a [hooks.state] hash per approved
# hook. Linking it would publish this machine's directory layout and churn on
# every session, so only the shareable keys are tracked and merged in.
DOTFILES="$PWD" "$PWD/bin/codex-config" apply >/dev/null \
  || log "  codex-config apply failed; ~/.codex/config.toml left as it was"
link_managed "$PWD/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"
# Separate file by design: opencode deprecated theme/keybinds/tui keys inside
# opencode.json, and this file has its own schema.
link_managed "$PWD/opencode/tui.json" "$HOME/.config/opencode/tui.json"
link_managed "$PWD/opencode/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"
[ "$(readlink "$HOME/.claude/commands" 2>/dev/null || true)" = "$PWD/agents/commands" ] && unlink "$HOME/.claude/commands" || true
[ "$(readlink "$HOME/.config/opencode/commands" 2>/dev/null || true)" = "$PWD/opencode/commands" ] && unlink "$HOME/.config/opencode/commands" || true
[ "$(readlink "$HOME/.config/opencode/skills" 2>/dev/null || true)" = "$PWD/opencode/skills" ] && unlink "$HOME/.config/opencode/skills" || true
mkdir -p "$HOME/.local/state/opencode"
link_managed "$PWD/opencode/kv.json" "$HOME/.local/state/opencode/kv.json"

# Model, context, cache and subscription quota in herdr's agent sidebar. Runs
# after the agent configs are linked and before moshi-hook, because both this
# and moshi-hook replace ~/.claude/settings.json and each re-links it.
log "Setting up agent quota..."
DOTFILES="$PWD" "$PWD/bin/agent-quota" || log "  agent-quota setup failed; sidebar quota will be absent."

log "Setting default apps for code files and plain text..."
if have duti && [ -f "$PWD/macos/default-apps.duti" ]; then
  duti "$PWD/macos/default-apps.duti" || true
else
  echo "duti missing or macos/default-apps.duti absent; skipping."
fi

log "Applying macOS defaults..."
if [ -x "$PWD/macos/defaults.sh" ]; then
  "$PWD/macos/defaults.sh" || true
fi

log "Applying macOS app shortcuts..."
if [ -x "$PWD/macos/app-shortcuts.sh" ]; then
  "$PWD/macos/app-shortcuts.sh" || true
fi

log "Mapping Caps Lock to Control for all keyboards..."
mkdir -p "$HOME/Library/LaunchAgents"
AGENT_SRC="$PWD/macos/com.local.KeyRemapping.plist"
AGENT_DST="$HOME/Library/LaunchAgents/com.local.KeyRemapping.plist"
# Generated rather than symlinked, as with the Time Machine agent below: the
# plist names caps-to-control.sh directly so Login Items shows that rather than a
# bare "hidutil", and launchd does not expand $HOME.
rm -f "$AGENT_DST"
sed "s|__CAPS_TO_CONTROL_SCRIPT__|$PWD/macos/caps-to-control.sh|" "$AGENT_SRC" > "$AGENT_DST"
launchctl unload "$AGENT_DST" 2>/dev/null || true
launchctl load "$AGENT_DST" 2>/dev/null || true
# apply now for this session
"$PWD/macos/caps-to-control.sh" || true

log "Installing Time Machine dev-junk exclusion agent..."
TM_AGENT_SRC="$PWD/macos/com.local.TMExcludeDev.plist"
TM_AGENT_DST="$HOME/Library/LaunchAgents/com.local.TMExcludeDev.plist"
# Generated rather than symlinked: the plist names the script directly so Login
# Items shows tm-exclude-dev.sh instead of a bare "sh", and launchd does not
# expand $HOME, so the path has to be baked in here.
rm -f "$TM_AGENT_DST"
sed "s|__TM_EXCLUDE_SCRIPT__|$PWD/macos/tm-exclude-dev.sh|" "$TM_AGENT_SRC" > "$TM_AGENT_DST"
launchctl unload "$TM_AGENT_DST" 2>/dev/null || true
launchctl load "$TM_AGENT_DST" 2>/dev/null || true
# run once now to backfill existing dirs
"$PWD/macos/tm-exclude-dev.sh" || true

touch "$PWD/.env"

# --- moshi-hook (agent events -> the Moshi iOS app) --------------------------
# The device token is a secret, so it lives in the gitignored .env as
# MOSHI_DEVICE_TOKEN, not here. Pairing is skipped silently when it is unset, so
# a fresh machine still finishes setup; re-run this script after adding it.
# NOTE: `moshi-hook install` REPLACES ~/.claude/settings.json with a real file,
# breaking the symlink into this repo, so re-link right after. The hooks it
# writes are tracked in claude/settings.json, which is why re-linking keeps them
# instead of dropping them. Same for ~/.config/opencode/plugins.
if have moshi-hook; then
  # shellcheck disable=SC1091
  [ -f "$PWD/.env" ] && . "$PWD/.env"
  if [ -n "${MOSHI_DEVICE_TOKEN:-}" ]; then
    log "Pairing moshi-hook..."
    moshi-hook pair --token "$MOSHI_DEVICE_TOKEN" >/dev/null 2>&1 \
      && moshi-hook install >/dev/null 2>&1 \
      && link_managed "$PWD/claude/settings.json" "$HOME/.claude/settings.json" \
      && brew services start moshi-hook >/dev/null 2>&1 \
      && log "  moshi-hook paired and running" \
      || log '  moshi-hook setup failed; run: moshi-hook pair --token <token>'
  else
    log "MOSHI_DEVICE_TOKEN unset in .env; skipping moshi-hook pairing."
  fi
fi

touch "$HOME/.hushlogin"

log "Done. Open a new terminal session so PATH and shells are consistent."
