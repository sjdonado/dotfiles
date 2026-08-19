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
mkdir -p "$HOME/.colima/default"
mkdir -p "$HOME/Library/Keyboard Layouts"
mkdir -p "$HOME/.config/ghostty"
mkdir -p "$HOME/.config/fish/functions"
mkdir -p "$HOME/.config/bat"
mkdir -p "$HOME/.config/pgcli"
mkdir -p "$HOME/.config/finicky"
PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"
export PATH

log "Linking local bin..."
ln -snf "$PWD/bin/"* "$HOME/.local/bin" 2>/dev/null || true

# Install dependencies from Brewfile only when requested.
if [ "$INSTALL" = 1 ]; then
  if [ -f "$PWD/Brewfile" ]; then
    log "Installing dependencies from Brewfile..."
    brew bundle --file="$PWD/Brewfile" || true
  else
    log "No Brewfile found, skipping."
  fi

  # The openspec-* agent skills shell out to this CLI; it is not in Homebrew.
  # Installed with bun because ~/.bun/bin is already on PATH, while `npm -g`
  # lands in a version-pinned Node prefix that is not.
  if ! have openspec; then
    log "Installing OpenSpec CLI..."
    bun add -g @fission-ai/openspec@latest \
      || echo "openspec install failed; openspec-* skills will no-op"
  fi
fi

log "Setting up Ghostty config..."
ln -snf "$PWD/ghostty/config" "$HOME/.config/ghostty/config"

# Finicky routes every link the system opens. It only takes effect once macOS
# names it the default browser, which is a prompt on first launch, not something
# a script can set.
log "Setting up Finicky config..."
mkdir -p "$HOME/.config/finicky"
ln -snf "$PWD/finicky/finicky.js" "$HOME/.config/finicky/finicky.js"

# SafariTab is what Finicky opens instead of Safari, so links land in a tab. It
# has to be an app bundle declaring http/https: only that receives the Apple Event
# carrying the URL. It is compiled rather than an AppleScript applet because the
# applet stub shows AppleScript's startup screen when another app launches it,
# which made every link wait on a dialog. Editing Info.plist invalidates a
# signature, so the bundle is signed after it is assembled, not before.
log "Building the SafariTab URL handler..."
SAFARI_TAB_APP="$HOME/Applications/SafariTab.app"
rm -rf "$SAFARI_TAB_APP"
mkdir -p "$SAFARI_TAB_APP/Contents/MacOS"
if xcrun swiftc -O -framework AppKit \
  -o "$SAFARI_TAB_APP/Contents/MacOS/SafariTab" "$PWD/macos/safari-tab/main.swift" 2>/dev/null; then
  cp "$PWD/macos/safari-tab/Info.plist" "$SAFARI_TAB_APP/Contents/Info.plist"
  codesign --force --sign - "$SAFARI_TAB_APP" >/dev/null 2>&1 || true
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -f "$SAFARI_TAB_APP" >/dev/null 2>&1 || true
  log "  built $SAFARI_TAB_APP (allow it to control Safari when macOS asks)"
else
  log "  swiftc failed; links will open in a new Safari window instead of a tab"
fi


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

  log "Installing tree-sitter CLI (needed by nvim-treesitter main branch)..."
  if ! have tree-sitter && have cargo; then
    cargo install tree-sitter-cli
  fi

  log "Installing pnpm (if missing)..."
  if ! have pnpm; then
    curl -fsSL https://get.pnpm.io/install.sh | sh -
    PNPM_RC="$HOME/.zshrc"
    [ -f "$PNPM_RC" ] && . "$PNPM_RC" || true
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

log "Linking Docker/Colima configs..."
ln -snf "$PWD/docker/colima.yaml" "$HOME/.colima/default/colima.yaml"
ln -snf "$PWD/docker/config.json" "$HOME/.docker/config.json"
# NOTE: Do not auto-start colima here. User can run: colima start

log "Copying custom keyboard layouts..."
cp -Rp "$PWD/macos/ukelele/"* "$HOME/Library/Keyboard Layouts/" 2>/dev/null || true

log "Linking dotfiles..."
if [ -f "$PWD/.ssh/config" ]; then
  ln -snf "$PWD/.ssh/config" "$HOME/.ssh/config"
  chmod 600 "$PWD/.ssh/config"
  [ -f "$PWD/.ssh/private.conf" ] && chmod 600 "$PWD/.ssh/private.conf"
fi
[ -f "$PWD/.mackup.cfg" ] && ln -snf "$PWD/.mackup.cfg" "$HOME/.mackup.cfg"
ln -snf "$PWD/git/.gitconfig" "$HOME/.gitconfig" 2>/dev/null || true

ln -snf "$PWD/bat/config"   "$HOME/.config/bat/config"     2>/dev/null || true
ln -snf "$PWD/pgcli/config" "$HOME/.config/pgcli/config"   2>/dev/null || true

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

log "Linking Neovim config..."
if [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
  mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%s)"
fi
ln -snf "$PWD/nvim" "$HOME/.config/nvim"

log "Linking Worktrunk config..."
mkdir -p "$HOME/.config/worktrunk"
ln -snf "$PWD/worktrunk/config.toml" "$HOME/.config/worktrunk/config.toml"

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
  # Remote Herdr plugins, pinned like skills-lock.json so a rebuild is
  # reproducible. Bump the ref deliberately after reviewing upstream. Bundles its
  # own pinned lazygit + fzf runtime, so no system lazygit needed; the local
  # side-panel plugin binds it as one of its exclusive panels.
  herdr plugin install Crokily/herdr-lazygit \
    --ref a13e12c99e5e469edd73165cabba413c2a2fd698 -y >/dev/null 2>&1 \
    && log "  installed Herdr plugin: herdr-lazygit" \
    || log "  Herdr not running; later run: herdr plugin install Crokily/herdr-lazygit"
  # Worktree keys are bound to this in herdr/config.toml. Left in its default
  # open_mode ("workspace"): it runs `wt switch --no-cd`, so worktrunk's
  # post-switch hook registers the workspace and the plugin only focuses it.
  # open_mode = "tab" would stack a tab on top of that same workspace.
  # Needs fzf and jq on PATH; both come from the Brewfile.
  herdr plugin install devashish2203/herdr-worktrunk \
    --ref a3107ca566bafcd463bc138007a0c01051970784 -y >/dev/null 2>&1 \
    && log "  installed Herdr plugin: worktrunk" \
    || log "  Herdr not running; later run: herdr plugin install devashish2203/herdr-worktrunk"
fi

log "Linking Lazygit config..."
mkdir -p "$HOME/Library/Application Support/lazygit"
ln -snf "$PWD/lazygit/config.yml" "$HOME/Library/Application Support/lazygit/config.yml"

log "Linking Claude Code and OpenCode config..."
mkdir -p "$HOME/.claude" "$HOME/.config/opencode" "$HOME/.config/ccstatusline"
link_managed "$PWD/claude/settings.json" "$HOME/.claude/settings.json"
link_managed "$PWD/claude/ccstatusline/settings.json" "$HOME/.config/ccstatusline/settings.json"
link_managed "$PWD/agents/commands" "$HOME/.claude/commands"
link_managed "$PWD/agents/skills" "$HOME/.claude/skills"
link_managed "$PWD/agents/AGENTS.md" "$HOME/.claude/CLAUDE.md"
link_managed "$PWD/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"
# Separate file by design: opencode deprecated theme/keybinds/tui keys inside
# opencode.json. `theme: system` is what follows the terminal's light/dark switch.
link_managed "$PWD/opencode/tui.json" "$HOME/.config/opencode/tui.json"
link_managed "$PWD/opencode/commands" "$HOME/.config/opencode/commands"
link_managed "$PWD/opencode/skills" "$HOME/.config/opencode/skills"
link_managed "$PWD/opencode/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"
mkdir -p "$HOME/.local/state/opencode"
link_managed "$PWD/opencode/kv.json" "$HOME/.local/state/opencode/kv.json"

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
