#!/usr/bin/env bash
# Remote Ubuntu setup for herdr + pi + nvim + lazygit, wired to these dotfiles.
# Idempotent. Safe to re-run. macOS-only steps from bootstrap.sh are omitted.
#
# End goal: connect from your local terminal with `herdr --remote <user>@<host>`.
#
# NOT handled here (sensitive — do manually, see notes printed at the end):
#   - pi Claude auth (claude-bridge login)
#   - any secrets in .env / ~/.ssh
set -euo pipefail

DOTFILES_REPO="https://github.com/sjdonado/dotfiles"
DOTFILES="${DOTFILES:-$HOME/.config/dotfiles}"
BIN="$HOME/.local/bin"

have() { command -v "$1" >/dev/null 2>&1; }
log()  { printf '\n==> %s\n' "$*"; }

case "$(uname -m)" in
  x86_64|amd64) ARCH=x86_64; DARCH=amd64; GARCH=x86_64 ;;
  aarch64|arm64) ARCH=arm64; DARCH=arm64; GARCH=arm64 ;;
  *) echo "unsupported arch: $(uname -m)" >&2; exit 1 ;;
esac

mkdir -p "$BIN" "$HOME/.config"
# Ensure dirs where installers drop binaries are on PATH, so re-runs detect
# already-installed tools (idempotency) and post-install `have` checks pass.
for d in "$BIN" "$HOME/.cargo/bin" "$HOME/.pi/bin" "$HOME/.local/share/pi/bin"; do
  case ":$PATH:" in *":$d:"*) ;; *) PATH="$d:$PATH" ;; esac
done
export PATH
rescan() { hash -r 2>/dev/null || true; }

# --- base packages -----------------------------------------------------------
log "apt base packages..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -y
sudo apt-get install -y \
  git curl wget ca-certificates build-essential unzip tar \
  fish ripgrep fd-find

# fd binary is named fd-find on Debian/Ubuntu; expose as `fd`
have fd || ln -snf "$(command -v fdfind)" "$BIN/fd" 2>/dev/null || true

# --- node (for pi npm packages) ---------------------------------------------
if ! have node; then
  log "Installing Node.js 22 (NodeSource)..."
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

# --- neovim (nightly: config uses vim.pack / vim.loader, needs >=0.12) -------
NEED_NVIM=1
if have nvim && nvim --version | head -1 | grep -qE 'v0\.(1[2-9]|[2-9][0-9])'; then NEED_NVIM=0; fi
if [ "$NEED_NVIM" = 1 ]; then
  log "Installing Neovim nightly..."
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/nvim.tar.gz" \
    "https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-${ARCH}.tar.gz"
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

# --- herdr -------------------------------------------------------------------
if ! have herdr; then
  log "Installing herdr..."
  curl -fsSL https://herdr.dev/install.sh | sh
  rescan
fi

# --- pi ----------------------------------------------------------------------
if ! have pi; then
  log "Installing pi..."
  curl -fsSL https://pi.dev/install.sh | sh
  rescan
fi

# --- worktrunk (wt) — optional; herdr copy-ignored plugin uses it ------------
if ! have wt; then
  if have cargo; then
    log "Installing worktrunk via cargo..."
    cargo install worktrunk && rescan || echo "worktrunk install failed; herdr copy-ignored plugin will no-op"
  else
    echo "NOTE: cargo not found — skipping worktrunk (wt). herdr worktree copy-ignored plugin will no-op."
  fi
fi

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

log "Linking git config..."
ln -snf "$PWD/git/.gitconfig" "$HOME/.gitconfig"

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

log "Linking pi config..."
mkdir -p "$HOME/.pi/agent/extensions/subagent" \
         "$HOME/.pi/agent/extensions/session-name" \
         "$HOME/.pi/agent/agents" "$HOME/.pi/agent/prompts"
ln -snf "$PWD/pi/settings.json"    "$HOME/.pi/agent/settings.json"
ln -snf "$PWD/pi/keybindings.json" "$HOME/.pi/agent/keybindings.json"
ln -snf "$PWD/pi/extensions/subagent/index.ts"  "$HOME/.pi/agent/extensions/subagent/index.ts"
ln -snf "$PWD/pi/extensions/subagent/agents.ts"  "$HOME/.pi/agent/extensions/subagent/agents.ts"
ln -snf "$PWD/pi/extensions/session-name/index.ts" "$HOME/.pi/agent/extensions/session-name/index.ts"
for f in "$PWD/pi/agents/"*.md;  do [ -e "$f" ] && ln -snf "$f" "$HOME/.pi/agent/agents/$(basename "$f")";  done
for f in "$PWD/pi/prompts/"*.md; do [ -e "$f" ] && ln -snf "$f" "$HOME/.pi/agent/prompts/$(basename "$f")"; done

# --- herdr copy-ignored plugin (needs running herdr server) ------------------
if have herdr; then
  herdr plugin unlink copy-ignored >/dev/null 2>&1 || true
  if herdr plugin link "$PWD/herdr/plugins/copy-ignored" >/dev/null 2>&1; then
    log "linked herdr copy-ignored plugin"
  else
    log "herdr server not running; later: herdr plugin link $PWD/herdr/plugins/copy-ignored"
  fi
fi

# --- default shell to fish (optional) ----------------------------------------
FISH="$(command -v fish || true)"
if [ -n "$FISH" ]; then
  grep -qx "$FISH" /etc/shells || echo "$FISH" | sudo tee -a /etc/shells >/dev/null
  if [ "$(getent passwd "$USER" | cut -d: -f7)" != "$FISH" ]; then
    chsh -s "$FISH" || echo "chsh failed; set fish manually if wanted"
  fi
fi

cat <<'NOTE'

==> Base setup done.

MANUAL STEPS (sensitive — not scripted):

  1. pi Claude auth (required before pi works):
       pi            # then follow claude-bridge login prompt
     pi packages (pi-claude-bridge, etc.) auto-install on first launch.

  2. Secrets / env (only if your workflow needs them):
       - Copy any private .env values by hand.
       - SSH keys / ~/.ssh/config: create or copy manually if you push over SSH
         (dotfiles cloned over public HTTPS, so clone itself needs nothing).

  3. Open a new shell (or `exec fish`) so PATH + shell changes apply.

NEXT — connect from your LOCAL terminal (not here):
  herdr --remote <user>@<this-host>

NOTE
