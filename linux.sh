#!/usr/bin/env bash
# Remote Ubuntu setup for herdr + Claude Code + Codex + OpenCode + ttt, wired to these dotfiles.
# Idempotent. Safe to re-run. macOS-only steps from macos.sh are omitted.
#
# End goal: connect from your local terminal with `herdr --remote <user>@<host>`.
#
# What is here and what is not: the tool list is mise.toml, and every link this
# repository owns is lib/links.sh, shared with macos.sh. What stays in this file
# is what is genuinely Linux: apt, the shell rc files, and the Coder workarounds.
#
# NOT handled here (sensitive — do manually, see notes printed at the end):
#   - Claude Code, Codex, OpenCode provider, and MCP authentication
#   - any secrets in .env / ~/.ssh
set -euo pipefail

DOTFILES_REPO="https://github.com/sjdonado/dotfiles"
DOTFILES="${DOTFILES:-$HOME/.config/dotfiles}"
BIN="$HOME/.local/bin"

# lib/links.sh defines these too, and is sourced once the clone exists. They are
# repeated here because the clone step itself needs them, and it is what creates
# the file that defines them.
have() { command -v "$1" >/dev/null 2>&1; }
log()  { printf '\n==> %s\n' "$*"; }
usage() { echo "Usage: $0 [--install]"; }

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
# First, because the tool list and the linking code both live in this repo:
# mise.toml is linked below and then installed from, and lib/links.sh is sourced
# right after, so the clone has to exist before anything else happens.
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
# shellcheck source=lib/links.sh
. "$PWD/lib/links.sh"

# The list is mise.toml in this repo, linked to the global config, so adding a
# tool is a line of TOML rather than another curl-and-guard block here. Linked
# before the install branch because it costs nothing and `--install` is opt-in.
link_mise_config

# --- dependencies (opt-in) ---------------------------------------------------
if [ "$INSTALL" = 1 ]; then
# Only what mise cannot or should not provide. Deliberately short: mise unpacks
# .zip, .tar.gz and .tar.xz itself and downloads prebuilt binaries, so the
# compiler toolchain and the archive packages that used to be here (
# build-essential, unzip, tar, xz-utils) turned out to be needed by nothing —
# verified by installing all of mise.toml in a container without them.
log "apt base packages..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -y
sudo apt-get install -y \
  git curl wget ca-certificates fish mosh python3 python3-pip

if ! have mise; then
  log "Installing mise..."
  curl -fsSL https://mise.run | env MISE_INSTALL_PATH="$BIN/mise" sh
  rescan
fi
log "Installing tools from mise.toml..."
mise install --yes || log "  some mise tools failed; re-run: mise install"
rescan

# --- installers mise cannot replace ------------------------------------------
# Claude Code publishes an npm wrapper that fetches its real binary in a
# postinstall script, which mise does not run: installed that way it fails at
# startup with "native binary not installed". It also manages its own updates
# and shell integration. herdr and moshi-hook ship from their own CDNs with no
# GitHub release for any mise backend to read. All three keep their installers,
# and none of them aborts the run: losing one tool should cost that tool, not
# the rest of the provisioning.
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
fi

# --- link configs (Linux paths) ---------------------------------------------
link_local_bin

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
#
# mise's own `[env]` section is not an option for any of this, measured rather
# than assumed: it only applies inside `mise exec`, an activated shell, or a
# shim, so a bare `env -i bash -c` sees none of it. That is precisely the shell
# these lines exist for.
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

link_git_config
link_bat_themes
link_fish_config
link_ttt_config
prune_stale_links "$HOME/.config/lazygit/config.yml"
link_herdr_config
link_worktrunk_config
link_agent_configs
link_herdr_plugins

# --- interactive shell to fish (login shell stays POSIX) ---------------------
# Do NOT chsh the login shell to fish. Coder runs its agent/metadata scripts
# through the login shell, and fish rejects POSIX/bash syntax (e.g. the Home
# Disk metric fails with "Variables cannot be bracketed"). Keep the login shell
# POSIX and exec into fish only for interactive human terminals via an rc guard.
# The `[ -t 1 ]` TTY test keeps non-interactive agent scripts out of fish.
if have fish; then
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

# No systemd user bus in a Coder workspace, so `moshi-hook service` cannot run
# the daemon: start it here as a bare background process, and fish/config.fish
# restarts it on the first shell after a workspace rebuild.
pair_moshi_hook 'pgrep -x moshi-hook >/dev/null 2>&1 || (nohup moshi-hook serve >/dev/null 2>&1 &)'

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
