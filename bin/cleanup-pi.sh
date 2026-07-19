#!/bin/sh
set -eu

[ -n "${HOME:-}" ] && [ "$HOME" != / ] || { echo "Refusing unsafe HOME" >&2; exit 1; }

purge_data=0
case "${1:-}" in
  "") ;;
  --purge-data) purge_data=1 ;;
  *) echo "Usage: $(basename "$0") [--purge-data]" >&2; exit 2 ;;
esac

case "$(uname -s)" in
  Darwin|Linux) ;;
  *) echo "Unsupported operating system: $(uname -s)" >&2; exit 1 ;;
esac

log() { printf '==> %s\n' "$*"; }

pi_path=$(command -v pi 2>/dev/null || true)

# macos.sh installed this private runtime; old Linux installs may use npm.
rm -rf "$HOME/.local/share/pi-node"
if [ -n "$pi_path" ] && [ -x "$pi_path" ]; then
  case "$pi_path" in
    "$HOME"/*) rm -f "$pi_path" ;;
  esac
fi
rm -f "$HOME/.local/bin/pi" "$HOME/.pi/bin/pi" "$HOME/.local/share/pi/bin/pi"

if command -v npm >/dev/null 2>&1 && npm list -g --depth=0 @earendil-works/pi-coding-agent >/dev/null 2>&1; then
  log "Uninstalling global Pi npm package"
  npm uninstall -g @earendil-works/pi-coding-agent
fi
if command -v pnpm >/dev/null 2>&1 && pnpm list -g --depth=0 2>/dev/null | grep -q '@earendil-works/pi-coding-agent'; then
  log "Uninstalling global Pi pnpm package"
  pnpm remove -g @earendil-works/pi-coding-agent
fi
if command -v bun >/dev/null 2>&1 && bun pm ls -g 2>/dev/null | grep -q '@earendil-works/pi-coding-agent'; then
  log "Uninstalling global Pi Bun package"
  bun uninstall -g @earendil-works/pi-coding-agent
fi

# ddgs was installed only for pi-search-hub.
if command -v python3 >/dev/null 2>&1 && python3 -c 'import ddgs' >/dev/null 2>&1; then
  log "Uninstalling ddgs"
  python3 -m pip uninstall -y --break-system-packages ddgs >/dev/null 2>&1 \
    || python3 -m pip uninstall -y ddgs >/dev/null 2>&1 \
    || echo "warning: could not uninstall ddgs" >&2
fi

# Remove Pi runtime packages/config while retaining credentials and sessions.
rm -rf \
  "$HOME/.pi/agent/npm" \
  "$HOME/.pi/agent/extensions" \
  "$HOME/.pi/agent/agents" \
  "$HOME/.pi/agent/prompts" \
  "$HOME/.pi/agent/skills" \
  "$HOME/.pi/agent/themes"
rm -f \
  "$HOME/.pi/agent/settings.json" \
  "$HOME/.pi/agent/models.json" \
  "$HOME/.pi/agent/keybindings.json" \
  "$HOME/.pi/agent/AGENTS.md"

if [ -L "$HOME/.agents/skills" ]; then
  old_skills=$(readlink "$HOME/.agents/skills")
  case "$old_skills" in
    */dotfiles/pi/skills|*/pi/skills) rm -f "$HOME/.agents/skills" ;;
  esac
fi

if [ "$purge_data" = 1 ]; then
  log "Removing all Pi credentials, sessions, and state"
  rm -rf "$HOME/.pi"
else
  log "Keeping Pi credentials and sessions under $HOME/.pi"
fi

if command -v pi >/dev/null 2>&1; then
  echo "warning: Pi still resolves to $(command -v pi); remove it with its package manager" >&2
else
  log "Pi cleanup complete"
fi
