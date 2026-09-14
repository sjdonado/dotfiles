#!/usr/bin/env bash
# Remote Ubuntu setup for herdr + Claude Code + Codex + OpenCode + ttt, wired to these dotfiles.
# Idempotent. Safe to re-run. macOS-only steps from macos.sh are omitted.
#
# End goal: connect from your local terminal with `herdr --remote <user>@<host>`.
#
# NOT handled here (sensitive — do manually, see notes printed at the end):
#   - Claude Code, Codex, OpenCode provider, and MCP authentication
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

# Kept for the guard alone: every installer that used the normalized names went with
# Neovim, lazygit, tree-sitter and difftastic, but refusing an unsupported arch up
# front still beats failing halfway through a provisioning run.
case "$(uname -m)" in
  x86_64|amd64|aarch64|arm64) ;;
  *) echo "unsupported arch: $(uname -m)" >&2; exit 1 ;;
esac

COREPACK_HOME="$HOME/.cache/corepack"
PNPM_HOME="$HOME/.local/share/pnpm"
export COREPACK_HOME PNPM_HOME
mkdir -p "$BIN" "$HOME/.config" "$COREPACK_HOME" "$PNPM_HOME"
# Ensure dirs where installers drop binaries are on PATH, so re-runs detect
# already-installed tools (idempotency) and post-install `have` checks pass.
for d in "$BIN" "$PNPM_HOME" "$HOME/.cargo/bin" "$HOME/.opencode/bin" "$HOME/.bun/bin" "$HOME/.local/share/mise/shims"; do
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
if ! have codex; then
  log "Installing Codex..."
  curl -fsSL https://github.com/openai/codex/releases/latest/download/install.sh \
    | env CODEX_NON_INTERACTIVE=1 sh
  rescan
fi
if ! have opencode; then
  log "Installing OpenCode..."
  curl -fsSL https://opencode.ai/install | bash
  rescan
fi

# --- mise: ttt, worktrunk, uv, bun and openspec ------------------------------
# One declaration in mise.toml covers this box and the Mac, with mise.lock
# recording the versions each resolved. Replaces five separate installers, each
# of which took whatever was newest on the day the box was built.
if ! have mise; then
  log "Installing mise..."
  curl -fsSL https://mise.run | sh \
    || echo "mise install failed; ttt, wt, uv, bun and openspec will be absent"
  rescan
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

# Needs mise.toml, so it follows the clone rather than sitting with the other
# dependency installs.
if [ "$INSTALL" = 1 ] && have mise; then
  log "Installing tools from mise.toml..."
  mise trust --quiet "$PWD/mise.toml" >/dev/null 2>&1 || true
  mise install --quiet \
    || echo "mise install failed; ttt, wt, uv, bun and openspec may be missing"
  rescan
fi

# --- link configs (Linux paths) ---------------------------------------------
log "Linking local bin..."
ln -snf "$PWD/bin/"* "$BIN/" 2>/dev/null || true
# Prune links left behind by a script this repo no longer ships, so a machine
# provisioned before a removal does not keep a dangling command on PATH.
for f in "$BIN"/*; do
  [ -L "$f" ] || continue
  case "$(readlink "$f")" in "$PWD/bin/"*) [ -e "$f" ] || rm -f "$f" ;; esac
done

# Persist ~/.local/bin on PATH for non-login shells (herdr panes spawn these,
# so ttt and the agent binaries resolve inside herdr too). Configure both bash and
# zsh: Coder workspaces default to zsh, so a bash-only setup leaves herdr/fish
# off PATH. Create the rc file if missing (a zsh box may ship no ~/.bashrc).
SHELL_RCS="$HOME/.bashrc $HOME/.zshrc"
for RC in $SHELL_RCS; do
  [ -e "$RC" ] || touch "$RC"
  grep -q 'HOME/.local/bin.*PATH' "$RC" \
    || printf '\n# dotfiles: local bin on PATH\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$RC"
  grep -q 'HOME/.opencode/bin.*PATH' "$RC" \
    || printf 'export PATH="$HOME/.opencode/bin:$PATH"\n' >> "$RC"
  # mise shims rather than `mise activate`: shims work in any shell without a
  # hook, which is what herdr's non-login panes get. Homebrew does the
  # equivalent on macOS through its fish vendor_conf.d.
  grep -q 'mise/shims' "$RC" \
    || printf 'export PATH="$HOME/.local/share/mise/shims:$PATH"\n' >> "$RC"
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
# the vars again after this file has run. Appended rather than symlinked: zsh is
# not a shell this repo configures, it is only what a Coder workspace happens to
# log in with, so these blocks are the minimum to keep that box consistent.
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

# Remove what this repo used to provision, so a machine set up before the editor
# switch does not keep a dangling ~/.config/nvim or herdr plugins whose directories
# are gone. Stopping the install is not the same as undoing it. Only links this repo
# created are touched: a hand-made config that happens to sit at one of these paths
# is left alone, and the `if` form keeps a false test from tripping `set -e`.
for stale in "$HOME/.config/nvim" "$HOME/.config/lazygit/config.yml" \
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

log "Linking herdr config..."
mkdir -p "$HOME/.config/herdr"
ln -snf "$PWD/herdr/config.toml" "$HOME/.config/herdr/config.toml"

# Parity with macos.sh. Without this link the tracked worktrunk config never
# applies on Linux, so copy-ignored, the post-merge prune, and the herdr
# open/focus hook all silently no-op.
log "Linking Worktrunk config..."
mkdir -p "$HOME/.config/worktrunk"
ln -snf "$PWD/worktrunk/config.toml" "$HOME/.config/worktrunk/config.toml"

log "Linking Claude Code, Codex, and OpenCode config..."
mkdir -p "$HOME/.claude" "$HOME/.codex" "$HOME/.agents" "$HOME/.config/opencode"
# claude/settings.json declares a SessionStart hook running herdr's agent-state
# script, and herdr owns that script. Install it BEFORE the symlink: the
# installer also rewrites settings.json, so running it afterwards would write
# a duplicate hook straight into the tracked dotfiles copy. Skip once present.
if have herdr && [ ! -f "$HOME/.claude/hooks/herdr-agent-state.sh" ]; then
  herdr integration install claude >/dev/null 2>&1 \
    || log "herdr integration install claude failed; SessionStart hook will no-op"
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
link_managed "$PWD/opencode/pty.md" "$HOME/.config/opencode/pty.md"
# Separate file by design: opencode deprecated theme/keybinds/tui keys inside
# opencode.json, and this file has its own schema.
link_managed "$PWD/opencode/tui.json" "$HOME/.config/opencode/tui.json"
link_managed "$PWD/opencode/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"
[ "$(readlink "$HOME/.claude/commands" 2>/dev/null || true)" = "$PWD/agents/commands" ] && unlink "$HOME/.claude/commands" || true
[ "$(readlink "$HOME/.config/opencode/commands" 2>/dev/null || true)" = "$PWD/opencode/commands" ] && unlink "$HOME/.config/opencode/commands" || true
[ "$(readlink "$HOME/.config/opencode/skills" 2>/dev/null || true)" = "$PWD/opencode/skills" ] && unlink "$HOME/.config/opencode/skills" || true
mkdir -p "$HOME/.local/state/opencode"
link_managed "$PWD/opencode/kv.json" "$HOME/.local/state/opencode/kv.json"

# On-demand agent usage (senna-lang/herdr-agent-usage, pinned). Keymap only:
# no sidebar rows, no toasts. prefix+u opens the limits pane for every
# agent, ctrl+shift+m refreshes the data (keybindings live in herdr/config.toml).
log "Setting up agent usage..."
if have herdr; then
  herdr plugin install senna-lang/herdr-agent-usage --ref v0.5.11 --yes >/dev/null 2>&1 \
    && herdr plugin action invoke usagebar.setup >/dev/null 2>&1 || true
  usagebar_cfg="$(herdr plugin config-dir usagebar 2>/dev/null || true)/config.toml"
  if [ -f "$usagebar_cfg" ]; then
    python3 - "$usagebar_cfg" <<'PY' || log "  agent-usage notify-off failed; toasts may appear."
import re, sys
path = sys.argv[1]
text = open(path).read()
text = re.sub(r"^enabled\s*=\s*true", "enabled = false", text, flags=re.M)
open(path, "w").write(text)
PY
  else
    log "  agent-usage setup failed; usage pane will be absent."
  fi
else
  log "  herdr missing; skipping agent-usage."
fi

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
       codex login
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
