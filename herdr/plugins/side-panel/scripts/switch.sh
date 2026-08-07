#!/usr/bin/env bash
# Open one side panel and close the other, so they never share the workspace.
#
# Plugin panes are the only ones herdr labels, and the label is the pane title
# from the owning plugin's manifest ("reviewr", "Git"). That label plus the
# workspace id is enough to find and close the other panel without either plugin
# exposing a close action we can rely on (lazygit only has a focus-dependent
# toggle).
set -euo pipefail

TARGET=${1:?usage: switch.sh <diff|lazygit>}

case "$TARGET" in
  diff)    other_label="Git"     ; plugin="persiyanov.reviewr" ; action="toggle" ;;
  lazygit) other_label="reviewr" ; plugin="herdr-lazygit"      ; action="open"   ;;
  *) echo "unknown target: $TARGET (expected diff or lazygit)" >&2; exit 2 ;;
esac

# HERDR_WORKSPACE_ID is injected for workspace-context actions; fall back to the
# focused pane's workspace so the script also works when invoked by hand.
workspace=${HERDR_WORKSPACE_ID:-}
if [ -z "$workspace" ]; then
  workspace=$(herdr pane current 2>/dev/null \
    | jq -r '.result.pane.workspace_id // empty')
fi

if [ -n "$workspace" ]; then
  herdr pane list 2>/dev/null \
    | jq -r --arg ws "$workspace" --arg label "$other_label" \
        '.result.panes[]? | select(.workspace_id == $ws and .label == $label) | .pane_id' \
    | while read -r pane_id; do
        [ -n "$pane_id" ] && herdr pane close "$pane_id" >/dev/null 2>&1 || true
      done
fi

exec herdr plugin action invoke "$action" --plugin "$plugin"
