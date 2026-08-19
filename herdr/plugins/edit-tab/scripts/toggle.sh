#!/usr/bin/env bash
# Toggle a dedicated nvim tab in the current workspace.
#
# Three states: absent means open the nvim entrypoint in a new tab, present but
# unfocused means focus that tab, pressed from inside it means go back to wherever
# the jump came from. herdr has no "previous tab", so that origin is recorded here
# per workspace; without it, a second press would leave you parked on the editor
# with no way back except the tab bar.
set -euo pipefail

# herdr runs plugin commands with the server's PATH, which is whatever started the
# server. On a remote box that is often a system PATH without ~/.local/bin, so a
# bare `herdr` dies with 127. HERDR_BIN_PATH exists for this; herdr-lazygit
# resolves it the same way.
herdr_bin="${HERDR_BIN_PATH:-herdr}"

# The pane title from the manifest. herdr labels plugin-owned panes with it, which
# is what makes the tab findable on later presses.
LABEL=nvim

# herdr describes the invocation in the environment: the workspace, and the tab the
# key was pressed in. HERDR_TAB_ID is what makes the toggle exact. The `focused`
# flag in `tab list` is not usable for this: it only reads true in the workspace the
# client is currently displaying, so a press in any other workspace would see no
# focused tab at all and never take the way-back branch.
context=${HERDR_PLUGIN_CONTEXT_JSON:-}
workspace=${HERDR_WORKSPACE_ID:-$(printf '%s' "$context" | jq -r '.workspace_id // empty')}
origin_tab=${HERDR_TAB_ID:-$(printf '%s' "$context" | jq -r '.tab_id // empty')}
[ -n "$workspace" ] || { echo "no workspace to toggle the $LABEL tab in" >&2; exit 1; }

# Locate the tab by its pane, not by tab label: the tab's own label is whatever
# herdr numbered it, while the pane carries the manifest title.
found=$("$herdr_bin" pane list 2>/dev/null | jq -r --arg ws "$workspace" --arg l "$LABEL" \
  'first(.result.panes[]? | select(.workspace_id == $ws and .label == $l)
         | "\(.tab_id) \(.pane_id)") // empty')
tab_id=${found%% *}
pane_id=${found##* }

# A restored pane keeps the label but loses the entrypoint. herdr brings plugin panes
# back as plain shells rather than re-running `command`, so after a server restart the
# tab is still there with fish sitting in it, and focusing it lands on a prompt
# instead of the editor. Measured after a restart: the pane reports shell_pid set and
# `-fish` in the foreground, where a live one reports `nvim`.
#
# Start the editor in the shell that is already there rather than rebuilding the tab.
# Closing the pane was the first attempt and it is wrong: the tab does not always go
# with it, so a surviving tab kept the stale label and the open branch below then
# added a second tab also called nvim. `pane run` is safe at this point in a way it
# is not at pane creation, because the shell has been at a prompt for as long as the
# session has been up, so there is no startup to race.
if [ -n "$pane_id" ]; then
  foreground=$("$herdr_bin" pane process-info --pane "$pane_id" 2>/dev/null \
    | jq -r '[.result.process_info.foreground_processes[]?.name] | join(" ")')
  case " $foreground " in
    *" $LABEL "*) ;;
    *) "$herdr_bin" pane run "$pane_id" "$LABEL" >/dev/null 2>&1 || true ;;
  esac
fi

state_dir=${HERDR_PLUGIN_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/herdr/plugins/edit-tab}
state_file="$state_dir/origin-$workspace"

# Pressed from inside the editor: go back. A stale id (that tab was closed while
# nvim had focus) falls back to any other tab, so the toggle never strands the user.
if [ -n "$tab_id" ] && [ "$origin_tab" = "$tab_id" ]; then
  tabs=$("$herdr_bin" tab list --workspace "$workspace" 2>/dev/null)
  previous=$(cat "$state_file" 2>/dev/null || true)
  if [ -z "$previous" ] || [ "$previous" = "$tab_id" ] \
    || ! printf '%s' "$tabs" | jq -e --arg t "$previous" 'any(.result.tabs[]?; .tab_id == $t)' >/dev/null; then
    previous=$(printf '%s' "$tabs" | jq -r --arg t "$tab_id" \
      'first(.result.tabs[]? | select(.tab_id != $t) | .tab_id) // empty')
  fi
  [ -n "$previous" ] || exit 0
  exec "$herdr_bin" tab focus "$previous"
fi

if [ -n "$origin_tab" ] && [ "$origin_tab" != "$tab_id" ]; then
  mkdir -p "$state_dir"
  printf '%s' "$origin_tab" >"$state_file"
fi

if [ -n "$tab_id" ]; then
  exec "$herdr_bin" tab focus "$tab_id"
fi

# First press in this workspace. The repo root, not the pane's cwd: a pane sitting
# in a subdirectory should still open the whole project.
pane_cwd=$(printf '%s' "$context" | jq -r '.focused_pane_cwd // .workspace_cwd // empty')
[ -n "$pane_cwd" ] || pane_cwd=$PWD
root=$(git -C "$pane_cwd" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$pane_cwd")

# herdr spawns the entrypoint as the pane's process, so nvim owns the pty from the
# first frame and quitting it closes the tab. `pane run` cannot be used here: it
# writes into the pty and races the shell's startup, which left `exec nvim` echoed
# above a bare fish prompt.
opened=$("$herdr_bin" plugin pane open \
  --plugin edit-tab \
  --entrypoint "$LABEL" \
  --placement tab \
  --workspace "$workspace" \
  --cwd "$root" \
  --focus 2>/dev/null)

# `plugin pane open` labels the pane from the manifest title but leaves the tab on
# herdr's running number, so the tab bar read "5" instead of "nvim". Only the tab
# carries a visible title here, the pane being alone in it, so name it after the
# fact. The pane label is what the lookup above keys on, so a failure here costs
# the title and nothing else.
new_tab=$(printf '%s' "$opened" | jq -r '.result.plugin_pane.pane.tab_id // empty')
[ -n "$new_tab" ] || exit 0
exec "$herdr_bin" tab rename "$new_tab" "$LABEL"
