#!/usr/bin/env bash
# Open one side panel and close every other one, so they never share a workspace.
#
# Panels are identified by pane label. herdr labels plugin-owned panes with the
# manifest pane title, and `herdr pane rename` writes the same field, so the
# lookup works for both the panes opened here and herdr-lazygit's.
#
# Panes are opened with `herdr pane split`, not `herdr plugin pane open`: the
# latter starts the process in the plugin root, which put nvim on this repo
# instead of the worktree being worked on. `split --cwd` takes the
# directory explicitly, and the repo root is what we want (a pane sitting in a
# subdirectory should still open the whole project).
set -euo pipefail

TARGET=${1:?usage: switch.sh <edit|lazygit>}

# Every panel this plugin arbitrates, as target:label. lazygit belongs to
# herdr-lazygit and is delegated to its own action; the rest are opened here.
PANELS="edit:nvim lazygit:Git"

own_label=""
for entry in $PANELS; do
  [ "${entry%%:*}" = "$TARGET" ] && own_label="${entry#*:}"
done
if [ -z "$own_label" ]; then
  echo "unknown target: $TARGET (expected edit or lazygit)" >&2
  exit 2
fi

case "$TARGET" in
  edit) panel_cmd="nvim" ;;
  *)    panel_cmd="" ;;
esac

# The focused pane is the work pane the keybinding fired from: its workspace
# scopes the exclusivity, and its cwd anchors the repo-root lookup.
current=$(herdr pane current 2>/dev/null || true)
workspace=${HERDR_WORKSPACE_ID:-$(printf '%s' "$current" | jq -r '.result.pane.workspace_id // empty')}
focused_id=$(printf '%s' "$current" | jq -r '.result.pane.pane_id // empty')
focused_label=$(printf '%s' "$current" | jq -r '.result.pane.label // empty')

# Split from a work pane, resolved before anything is closed. `--current` is not
# usable here: the focused pane is often the panel being replaced, and closing it
# leaves no current pane, so the split silently fails and the panel never opens.
work_pane=$focused_id
if [ -z "$work_pane" ] || [ -n "$focused_label" ]; then
  work_pane=$(herdr pane list 2>/dev/null \
    | jq -r --arg ws "$workspace" \
        'first(.result.panes[]? | select(.workspace_id == $ws and .label == null) | .pane_id) // empty')
fi
[ -n "$work_pane" ] || { echo "no work pane to split in workspace ${workspace:-?}" >&2; exit 1; }

pane_cwd=$(herdr pane list 2>/dev/null \
  | jq -r --arg p "$work_pane" 'first(.result.panes[]? | select(.pane_id == $p) | .cwd) // empty')
[ -n "$pane_cwd" ] || pane_cwd=$PWD
root=$(git -C "$pane_cwd" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$pane_cwd")

# Pane ids for a label in this workspace, newline separated, empty when absent.
panes_for() {
  [ -n "$workspace" ] || return 0
  herdr pane list 2>/dev/null \
    | jq -r --arg ws "$workspace" --arg label "$1" \
        '.result.panes[]? | select(.workspace_id == $ws and .label == $label) | .pane_id'
}

close_label() {
  panes_for "$1" | while read -r pane_id; do
    [ -n "$pane_id" ] && herdr pane close "$pane_id" >/dev/null 2>&1 || true
  done
}

for entry in $PANELS; do
  label="${entry#*:}"
  [ "$label" = "$own_label" ] || close_label "$label"
done

# Toggle: a panel already open in this workspace closes instead of stacking.
if [ -n "$(panes_for "$own_label")" ]; then
  close_label "$own_label"
  exit 0
fi

# herdr-lazygit already resolves the repo itself; let it own its pane.
if [ "$TARGET" = "lazygit" ]; then
  exec herdr plugin action invoke open --plugin herdr-lazygit
fi

# `pane split` opens a shell and takes no command of its own, so the panel
# process is started in it afterwards. `exec` replaces that shell, which keeps
# quitting the tool (`:q`, `q`) closing the pane instead of dropping to a prompt.
pane_id=$(herdr pane split --pane "$work_pane" --direction right --cwd "$root" --focus 2>/dev/null \
          | jq -r '.result.pane_id // .result.pane.pane_id // empty')
[ -n "$pane_id" ] || { echo "failed to open $own_label pane" >&2; exit 1; }

# The label is what makes this panel findable by the next invocation.
herdr pane rename "$pane_id" "$own_label" >/dev/null 2>&1 || true
exec herdr pane run "$pane_id" "exec $panel_cmd"
