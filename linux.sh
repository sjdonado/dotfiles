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

SHIMS="$HOME/.local/share/mise/shims"
mkdir -p "$BIN" "$HOME/.config"
# Ensure dirs where installers drop binaries are on PATH, so re-runs detect
# already-installed tools (idempotency) and post-install `have` checks pass.
# Everything mise manages resolves through its shims directory, which is why
# there is no per-tool entry here any more.
for d in "$BIN" "$SHIMS" "$HOME/.opencode/bin"; do
  case ":$PATH:" in *":$d:"*) ;; *) PATH="$d:$PATH" ;; esac
done
export PATH
rescan() { hash -r 2>/dev/null || true; }

# --- clone / update dotfiles -------------------------------------------------
# First, because the tool list lives in this repo: mise.toml is linked below and
# then installed from, so the clone has to exist before anything is installed.
if [ "$INSTALL" = 1 ] && ! have git; then
  export DEBIAN_FRONTEND=noninteractive
  sudo apt-get update -y && sudo apt-get install -y git curl ca-certificates
fi
if [ -d "$DOTFILES/.git" ]; then
  log "Updating dotfiles..."
  git -C "$DOTFILES" pull --ff-only || true
elif [ ! -d "$DOTFILES" ]; then
  log "Cloning dotfiles..."
  git clone "$DOTFILES_REPO" "$DOTFILES"
fi
cd "$DOTFILES"

# --- dependencies (opt-in) ---------------------------------------------------
if [ "$INSTALL" = 1 ]; then
# Only what mise cannot or should not provide: the compiler toolchain its
# backends occasionally need, the archive formats they ship in, and the login
# environment (fish, mosh), which is not project tooling.
log "apt base packages..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -y
sudo apt-get install -y \
  git curl wget ca-certificates build-essential unzip tar xz-utils \
  fish mosh python3 python3-pip

# --- mise: every other tool ---------------------------------------------------
# The list is mise.toml in this repo, linked to the global config below, so
# adding a tool is a line of TOML rather than another curl-and-guard block here.
if ! have mise; then
  log "Installing mise..."
  curl -fsSL https://mise.run | env MISE_INSTALL_PATH="$BIN/mise" sh
  rescan
fi
log "Installing tools from mise.toml..."
mkdir -p "$HOME/.config/mise"
ln -snf "$PWD/mise.toml" "$HOME/.config/mise/config.toml"
mise install --yes || log "  some mise tools failed; re-run: mise install"
rescan

# --- installers mise cannot replace ------------------------------------------
# Claude Code and OpenCode publish npm wrappers that fetch their real binary in
# a postinstall script, which mise does not run: installed that way, both fail
# at startup ("native binary not installed", "postinstall script was not run").
# herdr and moshi-hook ship from their own CDNs with no GitHub release for ubi
# to read. All four keep their official installers.
# Claude Code manages its own updates and shell integration, and herdr and
# moshi-hook ship from their own CDNs, so all three keep their installers. None
# of them aborts the run: losing one tool should cost that tool, not the rest of
# the provisioning.
install_tool() {
  if have "$1"; then return 0; fi
  log "Installing $1..."
  shift
  sh -c "$*" || log "  install failed; re-run this script or install it by hand"
  rescan
}
install_tool claude    'curl -fsSL https://claude.ai/install.sh | bash'
install_tool herdr     'curl -fsSL https://herdr.dev/install.sh | sh'
install_tool moshi-hook 'curl -fsSL https://getmoshi.app/install.sh | sh'
else
  log "Skipping dependency installation (use --install to enable)."
  mkdir -p "$HOME/.config/mise"
  ln -snf "$PWD/mise.toml" "$HOME/.config/mise/config.toml"
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

# Where PATH and environment go, and why it is two lists.
#
# ~/.bashrc on Ubuntu opens with `case $- in *i*) ;; *) return;; esac`, so
# anything appended to it is invisible to every non-interactive shell: an agent
# hook, a herdr pane running a command, `ssh host some-command`. The tools then
# exist and cannot be found, which is exactly what the container check caught.
#
# So environment lives in the files a shell reads regardless of how it was
# started (~/.profile for login sh/bash, ~/.zshenv for every zsh), and the rc
# files keep only what is genuinely interactive, plus a PATH line for the
# interactive non-login case, which reads no profile at all.
SHELL_ENVS="$HOME/.profile $HOME/.zshenv"
SHELL_RCS="$HOME/.bashrc $HOME/.zshrc"

for F in $SHELL_ENVS $SHELL_RCS; do
  [ -e "$F" ] || touch "$F"
  grep -q 'dotfiles: tools on PATH' "$F" || cat >> "$F" <<'EOF'

# dotfiles: tools on PATH. Shims rather than `mise activate`: a shim is a plain
# executable, so it resolves in non-interactive shells too.
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$HOME/.opencode/bin:$PATH"
EOF
done

for F in $SHELL_ENVS; do
  # Coder injects a git identity into every process it spawns, and env beats
  # ~/.gitconfig, so commits made here ignored the tracked user.name/user.email.
  # GIT_ASKPASS and GIT_SSH_COMMAND stay: those are how Coder brokers git auth.
  grep -q 'dotfiles: git identity from gitconfig' "$F" || cat >> "$F" <<'EOF'

# dotfiles: git identity from gitconfig, not Coder's injected env
unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL

# dotfiles: no core dumps. core_pattern is the bare name `core`, so a crash
# writes the dump into the process's cwd, i.e. straight into a repo.
ulimit -c 0
EOF
done

# ~/.zshrc keeps its own copy: it sources ~/.config/coder/env.sh, which sets the
# identity vars again after ~/.zshenv has already run.
grep -q 'dotfiles: git identity from gitconfig' "$HOME/.zshrc" || cat >> "$HOME/.zshrc" <<'EOF'

# dotfiles: git identity from gitconfig, not Coder's injected env
unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
EOF

log "Linking git config..."
ln -snf "$PWD/git/.gitconfig" "$HOME/.gitconfig"

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
# Separate file by design: opencode deprecated theme/keybinds/tui keys inside
# opencode.json, and this file has its own schema.
link_managed "$PWD/opencode/tui.json" "$HOME/.config/opencode/tui.json"
link_managed "$PWD/opencode/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"
[ "$(readlink "$HOME/.claude/commands" 2>/dev/null || true)" = "$PWD/agents/commands" ] && unlink "$HOME/.claude/commands" || true
[ "$(readlink "$HOME/.config/opencode/commands" 2>/dev/null || true)" = "$PWD/opencode/commands" ] && unlink "$HOME/.config/opencode/commands" || true
[ "$(readlink "$HOME/.config/opencode/skills" 2>/dev/null || true)" = "$PWD/opencode/skills" ] && unlink "$HOME/.config/opencode/skills" || true
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
