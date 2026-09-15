#!/bin/sh
# The linking half of provisioning, shared by linux.sh and macos.sh.
#
# Every function here was the same block of shell in both scripts, kept in sync
# by hand. They drifted: the Worktrunk link existed only on macOS until someone
# noticed, and the agent-harness block is thirty lines that had to be edited
# twice for every change to it. One copy, sourced by both, is the fix.
#
# Why a sourced file and not mise tasks, which was the other candidate:
#   - `sh -n macos.sh` and `bash -n linux.sh` are the first rung of this repo's
#     check, and shell embedded in TOML is invisible to both. `sh -n lib/*.sh`
#     keeps that rung covering this code.
#   - a mise task's working directory for a *global* config is $HOME, not the
#     directory the config is a symlink into, so every task would have to
#     rediscover the repository root anyway (measured: MISE_CONFIG_ROOT is
#     $HOME when ~/.config/mise/config.toml is a link to this repository).
#   - linking has to work on a box where mise is not installed yet, which is
#     every first run and every `--links-only` run.
#
# Contract for callers: $PWD is the repository root, and `log`, `have` and
# `link_managed` are defined below. Ordering stays with the caller, because the
# two scripts interleave these with platform-specific steps.

have() { command -v "$1" >/dev/null 2>&1; }
log()  { printf '\n==> %s\n' "$*"; }

# Replace whatever is at $dst with a link to $src, keeping one backup of
# anything that was not already the right link. Already-correct links return
# untouched, which is what makes a second run add no .backup.<timestamp> files.
link_managed() {
  src=$1 dst=$2
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then return; fi
    mv "$dst" "$dst.backup.$(date +%s)"
  fi
  ln -snf "$src" "$dst"
}

# The tool list. Linked rather than copied so `mise install` on either platform
# reads the same file this repository tracks.
link_mise_config() {
  log "Linking mise config..."
  mkdir -p "$HOME/.config/mise"
  ln -snf "$PWD/mise.toml" "$HOME/.config/mise/config.toml"
  # The lockfile is linked separately because mise looks for it beside the
  # config it resolved, which is ~/.config/mise, not the repository the config
  # is a link to. Without this link the lock is simply never read, silently.
  ln -snf "$PWD/mise.lock" "$HOME/.config/mise/mise.lock"
}

link_local_bin() {
  log "Linking local bin..."
  mkdir -p "$HOME/.local/bin"
  ln -snf "$PWD/bin/"* "$HOME/.local/bin/" 2>/dev/null || true
  # Prune links left behind by a script this repo no longer ships, so a machine
  # provisioned before a removal does not keep a dangling command on PATH.
  for f in "$HOME/.local/bin"/*; do
    [ -L "$f" ] || continue
    case "$(readlink "$f")" in "$PWD/bin/"*) [ -e "$f" ] || rm -f "$f" ;; esac
  done
}

link_git_config() {
  log "Linking git config..."
  ln -snf "$PWD/git/.gitconfig" "$HOME/.gitconfig" 2>/dev/null || true
}

# GitHub Dark/Light, chosen at runtime by BAT_THEME_DARK / BAT_THEME_LIGHT.
# The cache has to be rebuilt for bat to resolve a theme by name.
link_bat_themes() {
  log "Linking bat themes (GitHub Dark/Light, chosen by BAT_THEME_*)..."
  mkdir -p "$HOME/.config/bat/themes"
  for f in "$HOME/.config/bat/themes/VSCode-Dark.tmTheme" "$HOME/.config/bat/themes/VSCode-Light.tmTheme"; do
    [ -L "$f" ] && rm -f "$f"
  done
  for f in "$PWD/bat/themes/"*.tmTheme; do
    [ -e "$f" ] && ln -snf "$f" "$HOME/.config/bat/themes/$(basename "$f")"
  done
  # Debian packages bat as batcat, so a box provisioned before mise took the
  # tool over still has the cache rebuilt under the name it actually has.
  if have bat; then
    bat cache --build >/dev/null 2>&1 || true
  elif have batcat; then
    batcat cache --build >/dev/null 2>&1 || true
  fi
}

link_fish_config() {
  log "Linking fish config..."
  mkdir -p "$HOME/.config/fish/functions"
  ln -snf "$PWD/fish/config.fish" "$HOME/.config/fish/config.fish"
  ln -snf "$PWD/fish/functions/"* "$HOME/.config/fish/functions/" 2>/dev/null || true
}

link_ttt_config() {
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
}

link_worktrunk_config() {
  log "Linking Worktrunk config..."
  mkdir -p "$HOME/.config/worktrunk"
  ln -snf "$PWD/worktrunk/config.toml" "$HOME/.config/worktrunk/config.toml"
}

link_herdr_config() {
  log "Linking Herdr config..."
  # NOTE: only symlink config.toml; herdr keeps sockets/logs/session.json here.
  mkdir -p "$HOME/.config/herdr"
  ln -snf "$PWD/herdr/config.toml" "$HOME/.config/herdr/config.toml"
}

# Remove what this repo used to provision, so a machine set up before the editor
# switch does not keep a dangling ~/.config/nvim or herdr plugins whose
# directories are gone. Stopping the install is not the same as undoing it. Only
# links this repo created are touched: a hand-made config that happens to sit at
# one of these paths is left alone, and the `if` form keeps a false test from
# tripping `set -e`. The caller passes any platform-specific paths, because
# lazygit's config lives somewhere different on each.
prune_stale_links() {
  for stale in "$HOME/.config/nvim" \
    "$HOME/.config/herdr/plugins/config/herdr-lazygit/panel.conf" "$@"; do
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
}

# Local Herdr workflow plugins. Needs a running Herdr server, so a failure here
# is reported and skipped rather than fatal. Remote ones are pinned like
# skills-lock.json so a rebuild is reproducible; bump a ref deliberately after
# reviewing upstream.
link_herdr_plugins() {
  have herdr || return 0
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
  # On-demand agent usage (senna-lang/herdr-agent-usage, pinned). Remote, so
  # installed rather than linked: no source lives in this repository. Keymap
  # only, no sidebar rows, no toasts: prefix+u opens the limits pane for
  # every agent, ctrl+shift+m refreshes the data (keybindings live in
  # herdr/config.toml). Shared here rather than per script so both platforms
  # run the same install; on macOS the caller skips this whole function under
  # --links-only.
  log "Setting up agent usage..."
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
}

link_agent_configs() {
  log "Linking Claude Code, Codex, and OpenCode config..."
  mkdir -p "$HOME/.claude" "$HOME/.codex" "$HOME/.agents" "$HOME/.config/opencode"
  # claude/settings.json declares a SessionStart hook running herdr's
  # agent-state script, and herdr owns that script. Install it BEFORE the
  # symlink: the installer also rewrites settings.json, so running it afterwards
  # writes a duplicate hook straight into the tracked dotfiles copy, with an
  # absolute path baked in. Skip once present.
  if have herdr && [ ! -f "$HOME/.claude/hooks/herdr-agent-state.sh" ]; then
    herdr integration install claude >/dev/null 2>&1 \
      || log "  herdr integration install claude failed; SessionStart hook will no-op"
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
  # pty.md holds opencode's PTY-session instructions for long-running commands.
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
}

# --- moshi-hook pairing ------------------------------------------------------
# The device token is a secret, so it lives in the gitignored .env as
# MOSHI_DEVICE_TOKEN, not here. Pairing is skipped silently when it is unset, so
# a fresh box still finishes setup; re-run the script after adding it.
# NOTE: `moshi-hook install` REPLACES ~/.claude/settings.json with a real file,
# breaking the symlink into this repo, so re-link right after. The hooks it
# writes are tracked in claude/settings.json, which is why re-linking keeps them
# instead of dropping them.
#
# The caller passes the command that starts the daemon, because that is the one
# real difference: macOS has `brew services`, and a Coder workspace has no
# systemd user bus at all, so there it is a bare background process.
pair_moshi_hook() {
  have moshi-hook || return 0
  # shellcheck disable=SC1091
  [ -f "$PWD/.env" ] && . "$PWD/.env"
  if [ -z "${MOSHI_DEVICE_TOKEN:-}" ]; then
    log "MOSHI_DEVICE_TOKEN unset in .env; skipping moshi-hook pairing."
    return 0
  fi
  log "Pairing moshi-hook..."
  moshi-hook pair --token "$MOSHI_DEVICE_TOKEN" >/dev/null 2>&1 \
    && moshi-hook install >/dev/null 2>&1 \
    && link_managed "$PWD/claude/settings.json" "$HOME/.claude/settings.json" \
    && sh -c "$1" >/dev/null 2>&1 \
    && log "  moshi-hook paired and running" \
    || log '  moshi-hook setup failed; run: moshi-hook pair --token <token>'
}
