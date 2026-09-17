#!/usr/bin/env bash
# Toggle the nvim overlay pane.
#
# Two states, because that is all herdr offers for a pane: absent means open nvim
# as a zoomed overlay over the active pane, present means close it. Closing is what
# restores the focus and zoom the overlay covered, which is the "go back" half of
# the toggle. nvim exits with the pane, so the buffers come back through
# auto-session rather than by staying resident.
#
# Overlay takes no target. Passing --workspace or --target-pane makes herdr reject
# the call with "overlay and popup plugin panes target the active pane", and that
# silent rejection is what made an earlier version of this script do nothing.
# herdr resolves the active pane from the invocation context.
#
# The open pane is remembered by id, one file per workspace, rather than found by
# the manifest label. The label is not proof of ownership: a pane opened before
# this plugin was re-linked keeps the label but loses its plugin ownership, so
# herdr answers `plugin pane close` with "plugin pane not found", and any pane
# somebody renamed by hand carries the label too. Matching on the label is what
# made an earlier version stack a second overlay instead of closing the first.
set -euo pipefail

# herdr runs plugin commands with the server's PATH, which is whatever started the
# server. On a remote box that is often a system PATH without ~/.local/bin, so a
# bare `herdr` dies with 127. HERDR_BIN_PATH exists for this.
herdr_bin="${HERDR_BIN_PATH:-herdr}"

# The pane id from the manifest. It names the pane and the entrypoint to open.
LABEL=nvim

context=${HERDR_PLUGIN_CONTEXT_JSON:-}
workspace=${HERDR_WORKSPACE_ID:-$(printf '%s' "$context" | jq -r '.workspace_id // empty')}
[ -n "$workspace" ] || workspace=$("$herdr_bin" pane current 2>/dev/null | jq -r '.result.pane.workspace_id // empty')
[ -n "$workspace" ] || { echo "no workspace to toggle the $LABEL overlay in" >&2; exit 1; }

state_dir=${HERDR_PLUGIN_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/herdr/plugins/edit-tab}
state_file="$state_dir/overlay-$workspace"

pane_id=$(cat "$state_file" 2>/dev/null || true)
if [ -n "$pane_id" ]; then
  # Close the overlay this plugin opened here, if it is still open and still ours.
  if "$herdr_bin" plugin pane close "$pane_id" >/dev/null 2>&1; then
    rm -f "$state_file"
    exit 0
  fi
  # Stale id: the pane is gone, or a re-link dropped its ownership. Drop the note
  # and fall through to opening a fresh one.
  rm -f "$state_file"
fi

# The repo root, not the pane's cwd: a pane sitting in a subdirectory should still
# open the whole project.
pane_cwd=$(printf '%s' "$context" | jq -r '.focused_pane_cwd // .workspace_cwd // empty')
[ -n "$pane_cwd" ] || pane_cwd=$PWD
root=$(git -C "$pane_cwd" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$pane_cwd")

# herdr spawns the entrypoint as the pane's process, so nvim owns the pty from the
# first frame. `pane run` cannot be used here: it writes into the pty and races the
# shell's startup, which left `exec nvim` echoed above a bare fish prompt.
opened=$("$herdr_bin" plugin pane open \
  --plugin edit-tab \
  --entrypoint "$LABEL" \
  --placement overlay \
  --cwd "$root" \
  --focus)

new_pane=$(printf '%s' "$opened" | jq -r '.result.plugin_pane.pane.pane_id // empty')
[ -n "$new_pane" ] || exit 0

# Right-click routing is per-pane state, the default for a new pane is herdr's own
# menu, and `plugin pane open` carries no field for it. So it is set here, once the
# pane exists, or every right-click into the editor is swallowed by herdr first.
# panel-revive re-asserts the same thing after a restore, where it does not survive.
"$herdr_bin" pane input --pane "$new_pane" --right-click pane >/dev/null 2>&1 \
  || echo "edit-tab: could not route right-clicks into $new_pane" >&2

mkdir -p "$state_dir"
printf '%s' "$new_pane" >"$state_file"
