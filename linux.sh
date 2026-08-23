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
for d in "$BIN" "$PNPM_HOME" "$HOME/.cargo/bin" "$HOME/.opencode/bin" "$HOME/.bun/bin"; do
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
  fish ripgrep fd-find bat mosh python3 python3-pip \
  jq fzf

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

# --- difftastic (lazygit's external diff command) ----------------------------
if ! have difft; then
  log "Installing difftastic..."
  case "$ARCH" in x86_64) DFA=x86_64 ;; arm64) DFA=aarch64 ;; esac
  v="$(curl -fsSL https://api.github.com/repos/Wilfred/difftastic/releases/latest \
       | grep -oE '"tag_name": *"[^"]+"' | head -1 | grep -oE '[0-9.]+')"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/difft.tar.gz" \
    "https://github.com/Wilfred/difftastic/releases/download/${v}/difft-${DFA}-unknown-linux-gnu.tar.gz"
  tar -xzf "$tmp/difft.tar.gz" -C "$tmp"
  install -m755 "$(find "$tmp" -type f -name difft -perm -u+x | head -1)" "$BIN/difft" \
    || log "difftastic install failed; lazygit falls back to git diff"
  rm -rf "$tmp"
fi

# --- moshi-hook (agent events -> the Moshi iOS app) --------------------------
if ! have moshi-hook; then
  log "Installing moshi-hook..."
  curl -fsSL https://getmoshi.app/install.sh | sh
  rescan
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

# --- uv/uvx (MCP servers launched with `uvx`, e.g. grafana's mcp-grafana) -----
if ! have uv; then
  log "Installing uv..."
  curl -fsSL https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="$BIN" sh
  rescan
fi

# --- bun (claude/settings.json statusLine runs `bunx ccstatusline`) -----------
if ! have bun; then
  log "Installing bun..."
  curl -fsSL https://bun.sh/install | bash
  rescan
fi

# --- openspec (the openspec-* agent skills shell out to this CLI) ------------
# Installed with bun because ~/.bun/bin is already on PATH, while `npm -g` lands
# in a version-pinned Node prefix that is not. Must follow the bun block above.
if ! have openspec; then
  log "Installing OpenSpec CLI..."
  bun add -g @fission-ai/openspec@latest \
    || echo "openspec install failed; openspec-* skills will no-op"
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
# so nvim/lazygit/tree-sitter resolve inside herdr too). Configure both bash and
# zsh: Coder workspaces default to zsh, so a bash-only setup leaves herdr/fish
# off PATH. Create the rc file if missing (a zsh box may ship no ~/.bashrc).
SHELL_RCS="$HOME/.bashrc $HOME/.zshrc"
for RC in $SHELL_RCS; do
  [ -e "$RC" ] || touch "$RC"
  grep -q 'HOME/.local/bin.*PATH' "$RC" \
    || printf '\n# dotfiles: local bin on PATH\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$RC"
  grep -q 'HOME/.opencode/bin.*PATH' "$RC" \
    || printf 'export PATH="$HOME/.opencode/bin:$PATH"\n' >> "$RC"
  # bun's own installer appends a `$BUN_INSTALL/bin` block to the rc of the
  # shell it detects; only add ours when neither form is present.
  grep -qE 'BUN_INSTALL|HOME/\.bun/bin' "$RC" \
    || printf 'export PATH="$HOME/.bun/bin:$PATH"\n' >> "$RC"
  grep -q 'COREPACK_HOME.*\.cache/corepack' "$RC" || cat >> "$RC" <<'EOF'

# dotfiles: user-writable package-manager caches
export COREPACK_HOME="$HOME/.cache/corepack"
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
EOF
  # Coder injects a git identity into every process it spawns, and env beats
  # ~/.gitconfig, so commits made here ignored the tracked user.name/user.email.
  # Unset after the rc sources ~/.config/coder/env.sh, which sets them again.
  # GIT_ASKPASS and GIT_SSH_COMMAND stay: those are how Coder brokers git auth.
  grep -q 'dotfiles: git identity from gitconfig' "$RC" || cat >> "$RC" <<'EOF'

# dotfiles: git identity from gitconfig, not Coder's injected env
unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL

# dotfiles: no core dumps. core_pattern is the bare name `core`, so a crash
# writes the dump into the process's cwd, i.e. straight into a repo.
ulimit -c 0
EOF
done

log "Linking git config..."
ln -snf "$PWD/git/.gitconfig" "$HOME/.gitconfig"

# ~/.zshrc alone is not enough: non-interactive zsh never reads it, so hooks and
# agent shells kept the injected identity. ~/.zshenv is read by every zsh. The
# ~/.zshrc block stays too, since it sources ~/.config/coder/env.sh, which sets
# the vars again after this file has run. Appended rather than symlinked from
# zsh/.zshenv: that file is the macOS one, full of homebrew paths.
[ -e "$HOME/.zshenv" ] || touch "$HOME/.zshenv"
grep -q 'dotfiles: git identity from gitconfig' "$HOME/.zshenv" || cat >> "$HOME/.zshenv" <<'EOF'

# dotfiles: git identity from gitconfig, not Coder's injected env
unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL

# dotfiles: no core dumps. core_pattern is the bare name `core`, so a crash
# writes the dump into the process's cwd, i.e. straight into a repo.
ulimit -c 0
EOF

log "Linking bat themes (GitHub Dark/Light, chosen by BAT_THEME_*)..."
mkdir -p "$HOME/.config/bat/themes"
for f in "$HOME/.config/bat/themes/VSCode-Dark.tmTheme" "$HOME/.config/bat/themes/VSCode-Light.tmTheme"; do
  [ -L "$f" ] && rm -f "$f"
done
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

# Point the herdr-lazygit pane at the lazygit installed above instead of the
# 0.63.0 the plugin bundles. git.diffRenderers, the key lazygit/config.yml uses
# to route diffs through difftastic, only exists in 0.64+, so under the bundled
# binary that key is silently ignored and the pane falls back to `git diff`.
# Upstream HEAD is the ref pinned below and still pins 0.63.0.
#
# Upstream calls the override unsupported and warns on stderr about version skew:
# its generated keybinding layer is only tested against 0.63.0. Drop this file
# once the plugin bumps its own pin.
if have lazygit; then
  lg_panel_dir="$HOME/.config/herdr/plugins/config/herdr-lazygit"
  mkdir -p "$lg_panel_dir"
  cat > "$lg_panel_dir/panel.conf" <<EOF
# Managed by dotfiles (linux.sh). Edits here are overwritten.
RUNTIME_LAZYGIT_BIN=$(command -v lazygit)
EOF
  log "herdr-lazygit pane pinned to $(command -v lazygit)"
fi

log "Linking herdr config..."
mkdir -p "$HOME/.config/herdr"
ln -snf "$PWD/herdr/config.toml" "$HOME/.config/herdr/config.toml"

# Parity with macos.sh. Without this link the tracked worktrunk config never
# applies on Linux, so copy-ignored, the post-merge prune, and the herdr
# open/focus hook all silently no-op.
log "Linking Worktrunk config..."
mkdir -p "$HOME/.config/worktrunk"
ln -snf "$PWD/worktrunk/config.toml" "$HOME/.config/worktrunk/config.toml"

log "Linking Claude Code and OpenCode config..."
mkdir -p "$HOME/.claude" "$HOME/.config/opencode" "$HOME/.config/ccstatusline"
# claude/settings.json declares a SessionStart hook running herdr's agent-state
# script, and herdr owns that script. Install it BEFORE the symlink: the
# installer also rewrites settings.json, so running it afterwards would write
# a duplicate hook straight into the tracked dotfiles copy. Skip once present.
if have herdr && [ ! -f "$HOME/.claude/hooks/herdr-agent-state.sh" ]; then
  herdr integration install claude >/dev/null 2>&1 \
    || log "herdr integration install claude failed; SessionStart hook will no-op"
fi
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

# --- Herdr plugins (need running Herdr server) -------------------------------
# Remote ones are pinned like skills-lock.json so a rebuild is reproducible;
# bump a ref deliberately after reviewing upstream.
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
  # Bundles its own pinned lazygit + fzf runtime; panel.conf above overrides the
  # lazygit half with the system one, since the bundled 0.63.0 cannot read
  # git.diffRenderers. The local lazygit-panel plugin is what prefix+s calls, and
  # it delegates the actual toggle to this plugin.
  herdr plugin install Crokily/herdr-lazygit \
    --ref a13e12c99e5e469edd73165cabba413c2a2fd698 -y >/dev/null 2>&1 \
    && log "installed Herdr plugin: herdr-lazygit" \
    || log "Herdr server not running; later: herdr plugin install Crokily/herdr-lazygit"
fi

# --- interactive shell to fish (login shell stays POSIX) ---------------------
# Do NOT chsh the login shell to fish. Coder runs its agent/metadata scripts
# through the login shell, and fish rejects POSIX/bash syntax (e.g. the Home
# Disk metric fails with "Variables cannot be bracketed"). Keep the login shell
# POSIX and exec into fish only for interactive human terminals via an rc guard.
# The `[ -t 1 ]` TTY test keeps non-interactive agent scripts out of fish.
FISH="$(command -v fish || true)"
if [ -n "$FISH" ]; then
  for RC in $SHELL_RCS; do
    [ -e "$RC" ] || touch "$RC"
    grep -q 'dotfiles: exec fish' "$RC" || cat >> "$RC" <<'EOF'

# dotfiles: exec fish for interactive terminals only (Coder-safe: never for
# non-interactive agent/metadata scripts, which must stay POSIX).
if command -v fish >/dev/null 2>&1 && [ -z "$EXECED_FISH" ] && [ -t 1 ]; then
  case $- in
    *i*) export EXECED_FISH=1; exec fish ;;
  esac
fi
EOF
  done
fi

# --- moshi-hook pairing ------------------------------------------------------
# The device token is a secret, so it lives in the gitignored .env as
# MOSHI_DEVICE_TOKEN, not here. Pairing is skipped silently when it is unset, so
# a fresh box still finishes setup; re-run this script after adding it.
# NOTE: `moshi-hook install` REPLACES ~/.claude/settings.json with a real file,
# breaking the symlink into this repo, so re-link right after. The hooks it
# writes are tracked in claude/settings.json, which is why re-linking keeps them
# instead of dropping them. Same for ~/.config/opencode/plugins.
#
# No systemd user bus in a Coder workspace, so `moshi-hook service` cannot run
# the daemon: start it here, and fish/config.fish restarts it on the first shell
# after a workspace rebuild.
if have moshi-hook; then
  # shellcheck disable=SC1091
  [ -f "$PWD/.env" ] && . "$PWD/.env"
  if [ -n "${MOSHI_DEVICE_TOKEN:-}" ]; then
    log "Pairing moshi-hook..."
    moshi-hook pair --token "$MOSHI_DEVICE_TOKEN" >/dev/null 2>&1 \
      && moshi-hook install >/dev/null 2>&1 \
      && link_managed "$PWD/claude/settings.json" "$HOME/.claude/settings.json" \
      && { pgrep -x moshi-hook >/dev/null 2>&1 || (nohup moshi-hook serve >/dev/null 2>&1 &); } \
      && log "  moshi-hook paired and running" \
      || log '  moshi-hook setup failed; run: moshi-hook pair --token <token>'
  else
    log "MOSHI_DEVICE_TOKEN unset in .env; skipping moshi-hook pairing."
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
       - Moshi push: add `export MOSHI_DEVICE_TOKEN=<token>` to .env (token from
         Settings -> Hooks in the iOS app), re-run this script, then start the
         daemon with `moshi-hook serve`.
       - SSH keys / ~/.ssh/config: create or copy manually if you push over SSH
         (dotfiles cloned over public HTTPS, so clone itself needs nothing).

  3. Open a new shell (or `exec fish`) so PATH + shell changes apply.

NEXT — connect from your LOCAL terminal (not here):
  herdr --remote <user>@<this-host>

NOTE
