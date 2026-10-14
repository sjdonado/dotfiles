#!/usr/bin/env bash
set -euo pipefail

fail() { printf 'edit-tab: %s\n' "$*" >&2; exit 1; }
context=${HERDR_PLUGIN_CONTEXT_JSON:-'{}'}
cwd=$(printf '%s' "$context" | jq -er '.focused_pane_cwd // .workspace_cwd // empty | if type != "string" or test("[[:cntrl:]]") then error("Invalid project path") else . end') || fail "No valid project directory in the invocation context"
[ -n "$cwd" ] && [ -d "$cwd" ] || fail "No project directory in the invocation context"
root=$({ git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || (cd "$cwd" && pwd -P); } |
  jq -Rrs 'rtrimstr("\n") | if test("[[:cntrl:]]") then error("Invalid project root") else . end') || fail "Project root contains unsupported control characters"

target=${HERDR_ZED_SSH_TARGET:-}
if [ -z "$target" ] && [ -n "${HERDR_PLUGIN_CONFIG_DIR:-}" ] && [ -f "$HERDR_PLUGIN_CONFIG_DIR/ssh-target" ]; then
  target=$(cat "$HERDR_PLUGIN_CONFIG_DIR/ssh-target")
fi
if [ -z "$target" ] && [ -n "${SSH_CONNECTION:-}" ]; then
  [[ ! "$SSH_CONNECTION" =~ [[:cntrl:]] ]] || fail "Invalid SSH connection metadata"
  read -r -a connection <<<"$SSH_CONNECTION"
  [ "${#connection[@]}" -eq 4 ] || fail "Invalid SSH connection metadata"
  host=${connection[2]}
  port=${connection[3]}
  [[ "$host" =~ ^[a-zA-Z0-9.:_-]+$ ]] || fail "Invalid SSH server address"
  case "$host" in *:*) host="[$host]" ;; esac
  target="$(id -un)@$host:$port"
fi

if [ -n "$target" ]; then
  [[ "$target" =~ ^([a-zA-Z0-9._-]+@)?([a-zA-Z0-9._-]+|\[[a-fA-F0-9.:]+\])(:[0-9]{1,5})?$ ]] || fail "Invalid SSH target; use [user@]host[:port], without credentials"
  if [[ "$target" =~ :([0-9]+)$ ]]; then
    port=${BASH_REMATCH[1]}
    (( 10#$port >= 1 && 10#$port <= 65535 )) || fail "Invalid SSH port"
  fi
  encoded=$(jq -nr --arg path "$root" '$path | split("/") | map(@uri) | join("/")')
  quoted=$(jq -nr --arg uri "ssh://$target$encoded" '$uri | @sh')
  exec "${HERDR_BIN_PATH:-herdr}" plugin pane open --plugin edit-tab --entrypoint copy-zed --env "HERDR_ZED_COMMAND=zed $quoted"
fi

if [ -n "${SSH_CLIENT:-}${SSH_TTY:-}" ] || { [ "$(uname -s)" = Linux ] && [ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; }; then
  fail "Remote address unavailable; set HERDR_ZED_SSH_TARGET or the plugin's ssh-target file"
fi
if command -v zed >/dev/null 2>&1; then
  exec zed "$root"
elif [ "$(uname -s)" = Darwin ] && [ -x /Applications/Zed.app/Contents/MacOS/cli ]; then
  exec /Applications/Zed.app/Contents/MacOS/cli "$root"
fi
fail "Zed CLI is not installed on this desktop"
