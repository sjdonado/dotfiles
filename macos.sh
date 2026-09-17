#!/bin/sh
set -euo pipefail

# The tool list is mise.toml, the macOS-only half of it is the Brewfile, and
# every link this repository owns is lib/links.sh, shared with linux.sh. What
# stays in this file is what is genuinely macOS: Homebrew, the login shell,
# LaunchServices, launchd, and the defaults.
# shellcheck source=lib/links.sh
. "$PWD/lib/links.sh"

usage() { echo "Usage: $0 [--install] [--links-only]"; }

# --links-only does the half of this script that only writes inside $HOME:
# directories, symlinks, generated config. It skips everything that changes the
# machine itself (the login shell, /etc/shells, macOS defaults, launchd agents,
# default-app bindings, the browser router, moshi-hook pairing) and installs
# nothing. That is what makes this script testable: verify/macos/run.sh points
# HOME at a throwaway directory and runs it, which would otherwise mean chsh'ing
# a real user and loading real launch agents.
INSTALL=0
LINKS_ONLY=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --install) INSTALL=1 ;;
    --links-only) LINKS_ONLY=1 ;;
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

# base dirs the macOS-only steps below write into; the shared linking functions
# create their own.
log "Creating base directories..."
mkdir -p "$HOME/.config" "$HOME/.ssh" "$HOME/.docker" \
  "$HOME/Library/Keyboard Layouts" "$HOME/.config/ghostty/themes"
# mise's shims directory carries every tool in mise.toml.
PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$HOME/.opencode/bin:$PATH"
export PATH

link_local_bin

# Install dependencies from Brewfile only when requested.
if [ "$INSTALL" = 1 ]; then
  if [ -f "$PWD/Brewfile" ]; then
    log "Installing dependencies from Brewfile..."
    brew bundle --file="$PWD/Brewfile" || true
  else
    log "No Brewfile found, skipping."
  fi
fi

# mise owns every tool that is not macOS-specific, from the same mise.toml the
# Linux box reads: the editor, the agent CLIs, the search tools, the runtimes.
# Homebrew keeps the GUI applications and the system libraries. Adding a tool is
# a line of TOML in one file rather than an entry here and another in linux.sh.
link_mise_config
if [ "$INSTALL" = 1 ] && have mise; then
  log "Installing tools from mise.toml..."
  mise install --yes || log "  some mise tools failed; re-run: mise install"
fi

log "Setting up Ghostty config..."
ln -snf "$PWD/ghostty/config" "$HOME/.config/ghostty/config"
ln -snf "$PWD/ghostty/themes/"* "$HOME/.config/ghostty/themes/" 2>/dev/null || true

if [ "$LINKS_ONLY" = 1 ]; then
  log "Skipping BrowserRouter (--links-only)."
else
  # BrowserRouter is the default browser, and lives in its own repository:
  # https://github.com/sjdonado/browser-router
  #
  # The config is linked from here rather than seeded, so the routing rules are
  # tracked with the rest of the dotfiles. Link before installing: the installer
  # only writes a starting config when there is none, and the link counts as one.
  log "Setting up BrowserRouter (the default browser)..."
  mkdir -p "$HOME/.config/browser-router"
  ln -snf "$PWD/macos/browser-router.json" "$HOME/.config/browser-router/config.json"

  # Built from source by the tap formula rather than poured, so bumping the tag is
  # a rebuild instead of a wait on a bottle. The formula stops at the signed bundle
  # inside the Homebrew prefix; telling macOS about it is deliberately not its job,
  # and the last step, making it the default browser, is a system prompt no script
  # can answer.
  brew install --build-from-source sjdonado/tap/browser-router \
    || log "  BrowserRouter install failed; links will open in whatever macOS considers the default browser"

  app="$(brew --prefix)/opt/browser-router/BrowserRouter.app"
  if [ -d "$app" ]; then
    mkdir -p "$HOME/Applications"
    rm -rf "$HOME/Applications/BrowserRouter.app"
    cp -R "$app" "$HOME/Applications/"
    # LaunchServices is what lets a bundle outside /Applications open links at all.
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
      -f "$HOME/Applications/BrowserRouter.app" \
      || log "  lsregister failed; links may not reach BrowserRouter yet"
    log "  registered ~/Applications/BrowserRouter.app; open it once to answer the default-browser prompt"
  else
    log "  BrowserRouter.app is not under the Homebrew prefix; skipping registration"
  fi
fi

if [ "$LINKS_ONLY" = 1 ]; then
  log "Skipping the login shell (--links-only)."
else
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
fi

link_fish_config

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

# Claude Code is the one agent binary with its own installer: its npm package
# fetches the real binary from a postinstall script that mise does not run, and
# it manages its own updates and shell integration. Everything else that used to
# be curl-piped here comes from mise.toml now, rustup aside, which Homebrew has.
# mise's `rust` plugin is not the alternative it looks like. It installs and is
# rustup, but its shim shadows rustup's proxy, and that proxy is what implements
# rust-toolchain.toml. Measured: in a directory pinning 1.90.0, the mise shim
# reports 1.98.1 while ~/.cargo/bin/rustc syncs 1.90.0. Shims come first on PATH
# here, so mise owning rust means a pinned repository builds with the wrong
# compiler and says nothing. rustup keeps rust; see mise.toml.
if [ "$INSTALL" = 1 ] && ! have claude; then
  log "Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash \
    || log "  install failed; re-run this script or install it by hand"
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

link_git_config
link_bat_themes
link_nvim_config
link_worktrunk_config
prune_stale_links "$HOME/Library/Application Support/lazygit/config.yml"
link_herdr_config
if [ "$LINKS_ONLY" = 1 ]; then
  log "Skipping herdr plugin linking (--links-only)."
else
  link_herdr_plugins
fi
link_agent_configs

if [ "$LINKS_ONLY" = 1 ]; then
  log "Skipping macOS defaults, shortcuts and default apps (--links-only)."
else
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
fi

if [ "$LINKS_ONLY" = 1 ]; then
  log "Skipping launchd agents (--links-only)."
else
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
fi

touch "$PWD/.env"

if [ "$LINKS_ONLY" = 1 ]; then
  log "Skipping moshi-hook pairing (--links-only)."
else
  # Homebrew has a launchd service for the daemon, which is the one part of
  # pairing that differs from Linux.
  pair_moshi_hook 'brew services start moshi-hook'
fi

touch "$HOME/.hushlogin"

log "Done. Open a new terminal session so PATH and shells are consistent."
