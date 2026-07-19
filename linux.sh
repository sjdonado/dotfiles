#!/usr/bin/env bash
# Remote Ubuntu setup for herdr + Claude Code + OpenCode + nvim + lazygit, wired to these dotfiles.
# Idempotent. Safe to re-run. macOS-only steps from macos.sh are omitted.
#
# End goal: connect from your local terminal with `herdr --remote <user>@<host>`.
#
# NOT handled here (sensitive — do manually, see notes printed at the end):
#   - Claude Code, OpenCode provider, and MCP authentication
#   - any secrets in .env / ~/.ssh
set -euo pipefail

DOTFILES_REPO="https://github.com/sjdonado/dotfiles"
DOTFILES="${DOTFILES:-$HOME/.config/dotfiles}"
BIN="$HOME/.local/bin"

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

case "$(uname -m)" in
  x86_64|amd64) ARCH=x86_64; DARCH=amd64; GARCH=x86_64 ;;
  aarch64|arm64) ARCH=arm64; DARCH=arm64; GARCH=arm64 ;;
  *) echo "unsupported arch: $(uname -m)" >&2; exit 1 ;;
esac

COREPACK_HOME="$HOME/.cache/corepack"
PNPM_HOME="$HOME/.local/share/pnpm"
export COREPACK_HOME PNPM_HOME
mkdir -p "$BIN" "$HOME/.config" "$COREPACK_HOME" "$PNPM_HOME"
# Ensure dirs where installers drop binaries are on PATH, so re-runs detect
# already-installed tools (idempotency) and post-install `have` checks pass.
for d in "$BIN" "$PNPM_HOME" "$HOME/.cargo/bin" "$HOME/.opencode/bin"; do
  case ":$PATH:" in *":$d:"*) ;; *) PATH="$d:$PATH" ;; esac
done
export PATH
rescan() { hash -r 2>/dev/null || true; }

# --- dependencies (opt-in) ---------------------------------------------------
if [ "$INSTALL" = 1 ]; then
log "apt base packages..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -y
sudo apt-get install -y \
  git curl wget ca-certificates build-essential unzip tar \
  fish ripgrep fd-find bat python3 python3-pip

# --- neovim (stable: config uses vim.pack / vim.loader, needs >=0.12) ---------
NEED_NVIM=1
if have nvim && nvim --version | head -1 | grep -qE 'v0\.(1[2-9]|[2-9][0-9])'; then NEED_NVIM=0; fi
if [ "$NEED_NVIM" = 1 ]; then
  log "Installing Neovim stable..."
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/nvim.tar.gz" \
    "https://github.com/neovim/neovim/releases/download/stable/nvim-linux-${ARCH}.tar.gz"
  sudo rm -rf /opt/nvim
  sudo mkdir -p /opt/nvim
  sudo tar -xzf "$tmp/nvim.tar.gz" -C /opt/nvim --strip-components=1
  ln -snf /opt/nvim/bin/nvim "$BIN/nvim"
  rm -rf "$tmp"
fi

# --- lazygit -----------------------------------------------------------------
if ! have lazygit; then
  log "Installing lazygit..."
  v="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
       | grep -oE '"tag_name": *"v[^"]+"' | head -1 | grep -oE '[0-9.]+')"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/lg.tar.gz" \
    "https://github.com/jesseduffield/lazygit/releases/download/v${v}/lazygit_${v}_Linux_${GARCH}.tar.gz"
  tar -xzf "$tmp/lg.tar.gz" -C "$tmp" lazygit
  install -m755 "$tmp/lazygit" "$BIN/lazygit"
  rm -rf "$tmp"
fi

# --- git-delta (gitconfig references delta features) -------------------------
if ! have delta; then
  log "Installing git-delta..."
  v="$(curl -fsSL https://api.github.com/repos/dandavison/delta/releases/latest \
       | grep -oE '"tag_name": *"[^"]+"' | head -1 | grep -oE '[0-9.]+')"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/delta.deb" \
    "https://github.com/dandavison/delta/releases/download/${v}/git-delta_${v}_${DARCH}.deb"
  sudo dpkg -i "$tmp/delta.deb" || sudo apt-get install -f -y
  rm -rf "$tmp"
fi

# --- tree-sitter CLI (nvim-treesitter main branch builds parsers with it) ----
if ! have tree-sitter; then
  log "Installing tree-sitter CLI..."
  case "$ARCH" in x86_64) TSA=x64 ;; arm64) TSA=arm64 ;; esac
  v="$(curl -fsSL https://api.github.com/repos/tree-sitter/tree-sitter/releases/latest \
       | grep -oE '"tag_name": *"v[^"]+"' | head -1 | grep -oE '[0-9.]+')"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/ts.gz" \
    "https://github.com/tree-sitter/tree-sitter/releases/download/v${v}/tree-sitter-linux-${TSA}.gz"
  gunzip -c "$tmp/ts.gz" > "$BIN/tree-sitter"
  chmod +x "$BIN/tree-sitter"
  rm -rf "$tmp"
fi

# --- herdr -------------------------------------------------------------------
if ! have herdr; then
  log "Installing herdr..."
  curl -fsSL https://herdr.dev/install.sh | sh
  rescan
fi

# --- AI coding harnesses -----------------------------------------------------
if ! have claude; then
  log "Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash
  rescan
fi
if ! have opencode; then
  log "Installing OpenCode..."
  curl -fsSL https://opencode.ai/install | bash
  rescan
fi

# --- worktrunk (wt) — optional; herdr copy-ignored plugin uses it ------------
if ! have wt; then
  log "Installing worktrunk (wt)..."
  # cargo-dist installer: downloads prebuilt musl binary, no rust needed.
  curl -fsSL https://github.com/max-sixty/worktrunk/releases/latest/download/worktrunk-installer.sh | sh \
    && rescan \
    || echo "worktrunk install failed; herdr copy-ignored plugin will no-op"
fi
else
  log "Skipping dependency installation (use --install to enable)."
fi

# fd and bat use different binary names on Debian/Ubuntu; keep these symlinks
# current even when dependency installation is skipped.
have fd || { have fdfind && ln -snf "$(command -v fdfind)" "$BIN/fd"; } || true
have bat || { have batcat && ln -snf "$(command -v batcat)" "$BIN/bat"; } || true

# --- clone / update dotfiles -------------------------------------------------
if [ -d "$DOTFILES/.git" ]; then
  log "Updating dotfiles..."
  git -C "$DOTFILES" pull --ff-only || true
else
  log "Cloning dotfiles..."
  git clone "$DOTFILES_REPO" "$DOTFILES"
fi
cd "$DOTFILES"

# --- link configs (Linux paths) ---------------------------------------------
log "Linking local bin..."
ln -snf "$PWD/bin/"* "$BIN/" 2>/dev/null || true

# Persist ~/.local/bin on PATH for non-login shells (herdr panes spawn these,
# so nvim/lazygit/tree-sitter resolve inside herdr too).
BASHRC="$HOME/.bashrc"
if [ -f "$BASHRC" ] && ! grep -q 'HOME/.local/bin.*PATH' "$BASHRC"; then
  printf '\n# dotfiles: local bin on PATH\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$BASHRC"
fi
if [ -f "$BASHRC" ] && ! grep -q 'HOME/.opencode/bin.*PATH' "$BASHRC"; then
  printf 'export PATH="$HOME/.opencode/bin:$PATH"\n' >> "$BASHRC"
fi
if [ -f "$BASHRC" ]; then
  sed -i '\|^export OPENCODE_CONFIG="$HOME/.config/dotfiles/agents/opencode.json"$|d' "$BASHRC"
fi
if [ -f "$BASHRC" ] && ! grep -q 'COREPACK_HOME.*\.cache/corepack' "$BASHRC"; then
  cat >> "$BASHRC" <<'EOF'

# dotfiles: user-writable package-manager caches
export COREPACK_HOME="$HOME/.cache/corepack"
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
EOF
fi

log "Linking git config..."
ln -snf "$PWD/git/.gitconfig" "$HOME/.gitconfig"

log "Linking bat config + themes (VSCode Dark/Light for delta)..."
mkdir -p "$HOME/.config/bat/themes"
[ -e "$PWD/bat/config" ] && ln -snf "$PWD/bat/config" "$HOME/.config/bat/config"
for f in "$PWD/bat/themes/"*.tmTheme; do
  [ -e "$f" ] && ln -snf "$f" "$HOME/.config/bat/themes/$(basename "$f")"
done
if have bat; then
  bat cache --build >/dev/null 2>&1 || true
elif have batcat; then
  batcat cache --build >/dev/null 2>&1 || true
fi

log "Linking fish config..."
mkdir -p "$HOME/.config/fish/functions"
ln -snf "$PWD/fish/config.fish" "$HOME/.config/fish/config.fish"
ln -snf "$PWD/fish/functions/"* "$HOME/.config/fish/functions/" 2>/dev/null || true

log "Linking Neovim config..."
if [ -e "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
  mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%s)"
fi
ln -snf "$PWD/nvim" "$HOME/.config/nvim"

log "Linking lazygit config..."
mkdir -p "$HOME/.config/lazygit"
ln -snf "$PWD/lazygit/config.yml" "$HOME/.config/lazygit/config.yml"

log "Linking herdr config..."
mkdir -p "$HOME/.config/herdr"
ln -snf "$PWD/herdr/config.toml" "$HOME/.config/herdr/config.toml"

log "Linking Claude Code and OpenCode config..."
mkdir -p "$HOME/.claude" "$HOME/.config/opencode"
link_managed "$PWD/agents/commands" "$HOME/.claude/commands"
link_managed "$PWD/agents/skills" "$HOME/.claude/skills"
link_managed "$PWD/agents/AGENTS.md" "$HOME/.claude/CLAUDE.md"
link_managed "$PWD/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"
link_managed "$PWD/opencode/commands" "$HOME/.config/opencode/commands"
link_managed "$PWD/opencode/skills" "$HOME/.config/opencode/skills"
link_managed "$PWD/opencode/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"
mkdir -p "$HOME/.local/state/opencode"
link_managed "$PWD/opencode/kv.json" "$HOME/.local/state/opencode/kv.json"

# --- local Herdr plugins (need running Herdr server) -------------------------
if have herdr; then
  for plugin_dir in "$PWD/herdr/plugins/"*; do
    [ -f "$plugin_dir/herdr-plugin.toml" ] || continue
    plugin_id="$(basename "$plugin_dir")"
    herdr plugin unlink "$plugin_id" >/dev/null 2>&1 || true
    if herdr plugin link "$plugin_dir" >/dev/null 2>&1; then
      log "linked Herdr plugin: $plugin_id"
    else
      log "Herdr server not running; later: herdr plugin link $plugin_dir"
    fi
  done
fi

# --- default shell to fish (optional) ----------------------------------------
FISH="$(command -v fish || true)"
if [ -n "$FISH" ]; then
  grep -qx "$FISH" /etc/shells || echo "$FISH" | sudo tee -a /etc/shells >/dev/null
  if [ "$(getent passwd "$USER" | cut -d: -f7)" != "$FISH" ]; then
    # coder/passwordless users have no password -> chsh PAM fails; use sudo.
    sudo chsh -s "$FISH" "$USER" 2>/dev/null \
      || chsh -s "$FISH" 2>/dev/null \
      || echo "chsh failed; herdr uses [terminal] default_shell from config instead"
  fi
fi

cat <<'NOTE'

==> Base setup done.

MANUAL STEPS (sensitive — not scripted):

  1. Authenticate the coding harnesses:
       claude
       opencode auth login
     Add MCP servers separately with Claude Code and `opencode mcp add`.

  2. Secrets / env (only if your workflow needs them):
       - Copy any private .env values by hand.
       - SSH keys / ~/.ssh/config: create or copy manually if you push over SSH
         (dotfiles cloned over public HTTPS, so clone itself needs nothing).

  3. Open a new shell (or `exec fish`) so PATH + shell changes apply.

NEXT — connect from your LOCAL terminal (not here):
  herdr --remote <user>@<this-host>

NOTE
