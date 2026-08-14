#!/usr/bin/env bash
# Toggle a dedicated nvim tab in the current workspace.
#
# Three states, keyed off the tab label: absent means create it and start nvim,
# present but unfocused means focus it, already focused means go back to wherever
# the last jump came from. herdr has no "previous tab", so that origin is recorded
# here per workspace; without it, a second press would leave you parked on the
# editor with no way back except the tab bar.
set -euo pipefail

# herdr runs plugin commands with the server's PATH, which is whatever started the
# server. On a remote box that is often a system PATH without ~/.local/bin, so a
# bare `herdr` dies with 127. HERDR_BIN_PATH exists for this; herdr-lazygit
# resolves it the same way.
herdr_bin="${HERDR_BIN_PATH:-herdr}"

LABEL=nvim

current=$("$herdr_bin" pane current 2>/dev/null || true)
workspace=${HERDR_WORKSPACE_ID:-$(printf '%s' "$current" | jq -r '.result.pane.workspace_id // empty')}
[ -n "$workspace" ] || { echo "no workspace to toggle the $LABEL tab in" >&2; exit 1; }

tabs=$("$herdr_bin" tab list --workspace "$workspace" 2>/dev/null)
tab_id=$(printf '%s' "$tabs" | jq -r --arg l "$LABEL" \
  'first(.result.tabs[]? | select(.label == $l) | .tab_id) // empty')
focused=$(printf '%s' "$tabs" | jq -r 'first(.result.tabs[]? | select(.focused) | .tab_id) // empty')

# Per workspace, so two workspaces toggling at once do not overwrite each other.
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/herdr-edit-tab"
state_file="$state_dir/$workspace"

# Second press: back to the origin tab. A stale id (that tab was closed while nvim
# had focus) falls back to any other tab, so the toggle never strands the user.
if [ -n "$tab_id" ] && [ "$tab_id" = "$focused" ]; then
  previous=$(cat "$state_file" 2>/dev/null || true)
  if [ -z "$previous" ] \
    || ! printf '%s' "$tabs" | jq -e --arg t "$previous" 'any(.result.tabs[]?; .tab_id == $t)' >/dev/null; then
    previous=$(printf '%s' "$tabs" | jq -r --arg l "$LABEL" \
      'first(.result.tabs[]? | select(.label != $l) | .tab_id) // empty')
  fi
  [ -n "$previous" ] || exit 0
  exec "$herdr_bin" tab focus "$previous"
fi

if [ -n "$focused" ]; then
  mkdir -p "$state_dir"
  printf '%s' "$focused" >"$state_file"
fi

if [ -n "$tab_id" ]; then
  exec "$herdr_bin" tab focus "$tab_id"
fi

# First press in this workspace. The repo root, not the pane's cwd: a pane sitting
# in a subdirectory should still open the whole project.
pane_cwd=$(printf '%s' "$current" | jq -r '.result.pane.cwd // .result.pane.foreground_cwd // empty')
[ -n "$pane_cwd" ] || pane_cwd=$PWD
root=$(git -C "$pane_cwd" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$pane_cwd")

created=$("$herdr_bin" tab create --workspace "$workspace" --cwd "$root" --label "$LABEL" --focus 2>/dev/null)
pane_id=$(printf '%s' "$created" | jq -r '.result.root_pane.pane_id // empty')
[ -n "$pane_id" ] || { echo "failed to create the $LABEL tab" >&2; exit 1; }

# `exec` replaces the tab's shell, so quitting nvim closes the tab instead of
# leaving an empty prompt behind, and the next press builds a fresh one.
exec "$herdr_bin" pane run "$pane_id" "exec nvim"
