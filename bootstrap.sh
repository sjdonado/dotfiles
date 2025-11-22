#!/bin/sh
set -euo pipefail

# helpers
have() { command -v "$1" >/dev/null 2>&1; }
log()  { printf '\n==> %s\n' "$*"; }
DOTFILES="${DOTFILES:-$PWD}"

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

# Make brew available in THIS shell (Apple Silicon uses /opt/homebrew)
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Sanity check
if ! have brew; then
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
mkdir -p "$HOME/.config/ghostty/themes"
mkdir -p "$HOME/.config/fish/functions"
mkdir -p "$HOME/.config/bat"
mkdir -p "$HOME/.config/pgcli"
mkdir -p "$HOME/.config/zed"
mkdir -p "$HOME/.config/finicky"

log "Linking local bin..."
ln -snf "$DOTFILES/bin/"* "$HOME/.local/bin" 2>/dev/null || true

# Install dependencies from Brewfile
if [ -f "$DOTFILES/Brewfile" ]; then
  log "Installing dependencies from Brewfile..."
  # 'brew bundle' auto-detects Brewfile in CWD; use explicit path:
  brew bundle --file="$DOTFILES/Brewfile" || true
else
  log "No Brewfile found, skipping."
fi

log "Setting up Ghostty config..."
ln -snf "$DOTFILES/ghostty/config" "$HOME/.config/ghostty/config"
ln -snf "$DOTFILES/ghostty/themes/"* "$HOME/.config/ghostty/themes/" 2>/dev/null || true

log "Setting up tmux..."
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone --depth=1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi
ln -snf "$DOTFILES/tmux/.tmux.conf" "$HOME/.tmux.conf"

log "Installing/setting fish shell..."
if ! have fish; then
  brew install fish
fi

# ensure fish is listed in /etc/shells
FISH_PATH="$(brew --prefix)/bin/fish"
if ! grep -qx "$FISH_PATH" /etc/shells; then
  echo "Adding $FISH_PATH to /etc/shells (requires sudo)..."
  echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
fi

# change default shell if not already fish
if [ "$SHELL" != "$FISH_PATH" ]; then
  echo "Changing login shell to fish (requires your password)..."
  chsh -s "$FISH_PATH"
fi

# link fish config
ln -snf "$DOTFILES/fish/config.fish" "$HOME/.config/fish/config.fish"
ln -snf "$DOTFILES/fish/functions/"* "$HOME/.config/fish/functions/" 2>/dev/null || true

log "Installing rustup (if missing)..."
if ! have rustup-init && ! have rustup; then
  curl -fsSL https://sh.rustup.rs | sh -s -- -y
  # shell will pick up cargo on next login; try to add for current run:
  [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
fi

log "Installing pnpm (if missing)..."
if ! have pnpm; then
  curl -fsSL https://get.pnpm.io/install.sh | sh -
  # add PNPM_HOME for current shell if installer wrote it
  PNPM_RC="$HOME/.zshrc"
  [ -f "$PNPM_RC" ] && . "$PNPM_RC" || true
fi

log "Linking Docker/Colima configs..."
ln -snf "$DOTFILES/docker/colima.yaml" "$HOME/.colima/default/colima.yaml"
ln -snf "$DOTFILES/docker/config.json" "$HOME/.docker/config.json"
# NOTE: Do not auto-start colima here. User can run: colima start

log "Copying custom keyboard layouts..."
cp -Rp "$DOTFILES/macos/ukelele/"* "$HOME/Library/Keyboard Layouts/" 2>/dev/null || true

log "Linking dotfiles..."
[ -f "$DOTFILES/.ssh/config" ] && ln -snf "$DOTFILES/.ssh/config" "$HOME/.ssh/config"
[ -f "$DOTFILES/.mackup.cfg" ] && ln -snf "$DOTFILES/.mackup.cfg" "$HOME/.mackup.cfg"
ln -snf "$DOTFILES/git/.gitconfig" "$HOME/.gitconfig" 2>/dev/null || true

ln -snf "$DOTFILES/bat/config"   "$HOME/.config/bat/config"     2>/dev/null || true
ln -snf "$DOTFILES/pgcli/config" "$HOME/.config/pgcli/config"   2>/dev/null || true

log "Linking Neovim config..."
ln -snf "$DOTFILES/nvim" "$HOME/.config/nvim"

log "Installing Node.js LTS for Neovim LSP..."
NODE_DIR="$HOME/.local/share/nvim/node"
if [ ! -d "$NODE_DIR/bin" ]; then
  NODE_VERSION=$(curl -fsSL "https://nodejs.org/dist/index.json" | jq -r '[.[] | select(.lts != false)] | first | .version' | sed 's/v//')

  if [ -z "$NODE_VERSION" ]; then
    echo "Warning: Failed to fetch the latest Node.js LTS version. Skipping Neovim Node.js setup."
  else
    NODE_TAR="node-v${NODE_VERSION}-darwin-arm64.tar.gz"
    NODE_URL="https://nodejs.org/dist/v${NODE_VERSION}/${NODE_TAR}"

    mkdir -p "$NODE_DIR"
    echo "Installing Node.js LTS ($NODE_VERSION) for Neovim on Apple Silicon..."
    curl -fsSL "$NODE_URL" | tar -xz -C "$NODE_DIR" --strip-components=1
  fi
else
  echo "Node.js LTS already installed in $NODE_DIR"
fi

log "Linking Zed config..."
ln -snf "$DOTFILES/zed/settings.json" "$HOME/.config/zed/settings.json"
ln -snf "$DOTFILES/zed/keymap.json"   "$HOME/.config/zed/keymap.json"

log "Martillo setup"
mkdir -p $HOME/.hammerspoon/
git clone https://github.com/sjdonado/martillo ~/.martillo
ln -snf "$DOTFILES/martillo" "$HOME/.hammerspoon"

touch "$DOTFILES/.env"

log "Done. Open a new terminal session so PATH and shells are consistent."
