#!/bin/sh
# Remote-environment bootstrap for Ubuntu (Coder workspaces, devcontainers).
# Scope: tmux + nvim only. No GUI tools, no shell switch, no macOS bits.
#
# Idempotent — safe to re-run.
set -eu

have() { command -v "$1" >/dev/null 2>&1; }
log()  { printf '\n==> %s\n' "$*"; }

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
NVIM_VERSION="${NVIM_VERSION:-stable}"

SUDO=""
[ "$(id -u)" -ne 0 ] && have sudo && SUDO="sudo"

# ------------------------------------------------------------------
# System dependencies
# nvim runtime needs: git (vim.pack), make + cc (treesitter parsers),
# unzip + curl (fetching), ripgrep + fd (telescope).
# ------------------------------------------------------------------
log "Installing base packages via apt..."
$SUDO apt-get update -y
$SUDO apt-get install -y \
  git curl ca-certificates build-essential unzip tar xz-utils \
  ripgrep fd-find tmux

# Ubuntu names fd as `fdfind`; expose as `fd` for nvim.
if have fdfind && ! have fd; then
  mkdir -p "$HOME/.local/bin"
  ln -snf "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi

# ------------------------------------------------------------------
# Neovim — Ubuntu repos lag behind; pull official release tarball
# ------------------------------------------------------------------
ensure_nvim() {
  if have nvim; then
    installed="$(nvim --version | head -n1 | awk '{print $2}')"
    case "$installed" in
      v0.1[2-9]*|v[1-9]*) log "Neovim $installed already installed."; return 0 ;;
    esac
  fi

  log "Installing Neovim ($NVIM_VERSION)..."
  arch="$(uname -m)"
  case "$arch" in
    x86_64|amd64) nvim_arch="linux-x86_64" ;;
    aarch64|arm64) nvim_arch="linux-arm64" ;;
    *) echo "Unsupported arch for Neovim release: $arch" >&2; return 1 ;;
  esac

  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT
  url="https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-${nvim_arch}.tar.gz"
  curl -fsSL "$url" -o "$tmpdir/nvim.tar.gz"

  mkdir -p "$HOME/.local"
  tar -xzf "$tmpdir/nvim.tar.gz" -C "$tmpdir"
  extracted="$(find "$tmpdir" -maxdepth 1 -type d -name 'nvim-*' | head -n1)"
  rm -rf "$HOME/.local/nvim"
  mv "$extracted" "$HOME/.local/nvim"

  mkdir -p "$HOME/.local/bin"
  ln -snf "$HOME/.local/nvim/bin/nvim" "$HOME/.local/bin/nvim"
  trap - EXIT
  rm -rf "$tmpdir"
}
ensure_nvim

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# ------------------------------------------------------------------
# tree-sitter CLI — nvim-treesitter main branch needs it to compile
# parsers. Prefer cargo (matches bootstrap.sh); fall back to npm.
# ------------------------------------------------------------------
if ! have tree-sitter; then
  if have cargo; then
    log "Installing tree-sitter CLI via cargo..."
    cargo install tree-sitter-cli
  elif have npm; then
    log "Installing tree-sitter CLI via npm (global)..."
    $SUDO npm install -g tree-sitter-cli
  else
    log "Skipping tree-sitter CLI: install rustup+cargo (or npm) on the host and re-run remote.sh if treesitter parsers fail to compile."
  fi
fi

# ------------------------------------------------------------------
# workmux — install via cargo (avoids dragging Homebrew onto the host)
# ------------------------------------------------------------------
if ! have workmux; then
  if have cargo; then
    log "Installing workmux via cargo..."
    cargo install workmux
  else
    log "Installing workmux via official installer..."
    curl -fsSL https://raw.githubusercontent.com/raine/workmux/main/scripts/install.sh | bash
  fi
fi

# ------------------------------------------------------------------
# Symlinks
# ------------------------------------------------------------------
log "Linking Neovim config..."
mkdir -p "$HOME/.config"
if [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
  mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%s)"
fi
ln -snf "$DOTFILES/nvim" "$HOME/.config/nvim"

log "Linking tmux config..."
ln -snf "$DOTFILES/tmux/.tmux.conf" "$HOME/.tmux.conf"

log "Linking workmux config..."
mkdir -p "$HOME/.config/workmux"
ln -snf "$DOTFILES/workmux/config.yaml" "$HOME/.config/workmux/config.yaml"

# Tmux plugin manager
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  log "Installing tmux plugin manager (TPM)..."
  git clone --depth=1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# ------------------------------------------------------------------
# Headless plugin sync so the first interactive nvim start is fast
# ------------------------------------------------------------------
log "Pre-installing Neovim plugins (headless)..."
nvim --headless "+lua vim.defer_fn(function() vim.cmd('qa') end, 30000)" >/dev/null 2>&1 || true

log "Done."
log "Next steps:"
log "  - Start tmux and press prefix + I to install tmux plugins via TPM."
log "  - Open nvim; mason will install LSPs in the background if the toolchains"
log "    (node, go, python, etc.) are present. Install them as needed."
log "  - In a git repo: \`workmux add <branch>\` to spawn a session with"
log "    claude + nvim panes and .env/.pem files copied in."
