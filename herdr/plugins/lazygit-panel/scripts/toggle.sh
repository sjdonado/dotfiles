#!/usr/bin/env bash
# Toggle the herdr-lazygit sidebar, owning the pane once a restart has orphaned it.
#
# A restored pane keeps its label but is no longer a plugin pane: `plugin pane
# focus` on it answers plugin_pane_not_found, which is what upstream's launcher
# calls for both its FOCUS and CLOSE branches. So after a restart upstream cannot
# focus that panel, cannot close it, and its process check refuses to reuse it,
# leaving a second sidebar next to a dead prompt. All three states are therefore
# handled here, and only a tab with no panel at all is handed back to upstream,
# where its width handling and fresh-open path still apply.
set -euo pipefail

# herdr runs plugin commands with the server's PATH, which on a remote box often
# lacks ~/.local/bin. HERDR_BIN_PATH exists for that; the other plugins here
# resolve it the same way.
herdr_bin="${HERDR_BIN_PATH:-herdr}"

UPSTREAM=herdr-lazygit
LABEL=Git

delegate() {
  exec "$herdr_bin" plugin action invoke open --plugin "$UPSTREAM"
}

# The CLI's `pane focus` only moves between neighbours, so focusing a pane by id
# goes straight to the socket method the CLI does not expose. HERDR_SOCKET_PATH is
# in every plugin command's environment.
focus_pane() {
  python3 - "$1" <<'PY'
import json, os, socket, sys
path = os.environ.get('HERDR_SOCKET_PATH')
if not path:
    sys.exit(0)
try:
    conn = socket.socket(socket.AF_UNIX)
    conn.connect(path)
    conn.sendall((json.dumps({'id': 'lazygit-panel', 'method': 'pane.focus',
                              'params': {'pane_id': sys.argv[1]}}) + '\n').encode())
    conn.settimeout(3)
    conn.recv(65536)
except Exception:
    pass
PY
}

context=${HERDR_PLUGIN_CONTEXT_JSON:-}
tab=${HERDR_TAB_ID:-$(printf '%s' "$context" | jq -r '.tab_id // empty')}
[ -n "$tab" ] || delegate

# Scoped to this tab, as upstream scopes it: the sidebar belongs beside the work it
# was opened from, and a panel in another tab is a different panel.
found=$("$herdr_bin" pane list 2>/dev/null | jq -r --arg t "$tab" --arg l "$LABEL" \
  'first(.result.panes[]? | select(.tab_id == $t and .label == $l)
         | "\(.pane_id) \(.focused)") // empty')
[ -n "$found" ] || delegate
pane_id=${found%% *}
focused=${found##* }

foreground=$("$herdr_bin" pane process-info --pane "$pane_id" 2>/dev/null \
  | jq -r '[.result.process_info.foreground_processes[]?.name] | join(" ")')

case " $foreground " in
  *" lazygit "*)
    # A live panel: the ordinary toggle.
    if [ "$focused" = true ]; then
      exec "$herdr_bin" pane close "$pane_id"
    fi
    focus_pane "$pane_id"
    exit 0
    ;;
esac

# A restored shell. Focusing it is enough: the panel-revive plugin restarts lazygit
# on the pane.focused event, which is also what repairs the panel when it is reached
# with the mouse instead of this key.
focus_pane "$pane_id"
