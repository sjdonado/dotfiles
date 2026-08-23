#!/usr/bin/env bash
# Restart the program a restored plugin pane lost, on the focus that reveals it.
#
# Both panels are keyed by the label herdr kept across the restore, which is also
# what tells a restored panel apart from a shell someone opened themselves: only a
# plugin pane carries one of these.
set -euo pipefail

herdr_bin="${HERDR_BIN_PATH:-herdr}"
context=${HERDR_PLUGIN_CONTEXT_JSON:-}

pane=$(printf '%s' "$context" | jq -r '.focused_pane_id // empty')
[ -n "$pane" ] || exit 0

# An agent pane is restored by herdr itself, so it never needs this and is the
# focus target most of the time. Rejecting it from the event payload keeps the
# common case free of any herdr call.
[ -z "$(printf '%s' "$context" | jq -r '.focused_pane_agent // empty')" ] || exit 0

label=$("$herdr_bin" pane get "$pane" 2>/dev/null | jq -r '.result.pane.label // empty')
case $label in
  # edit-tab's [[panes]] title.
  nvim) want=nvim ;;
  # herdr-lazygit's [[panes]] title.
  Git) want=lazygit ;;
  *) exit 0 ;;
esac

foreground=$("$herdr_bin" pane process-info --pane "$pane" 2>/dev/null \
  | jq -r '[.result.process_info.foreground_processes[]?.name] | join(" ")')
case " $foreground " in
  *" $want "*) exit 0 ;;
esac

# Two focus events can land while the program is still starting, and the second
# would type its name into the first. The lock is held past the write for that
# reason, not for the write itself: mkdir is the atomic part, the sleep is what
# covers the gap until the process shows up in process-info.
lock="${TMPDIR:-/tmp}/panel-revive-${pane//:/_}.lock"
mkdir "$lock" 2>/dev/null || exit 0
trap 'rmdir "$lock" 2>/dev/null || true' EXIT

case $want in
  nvim)
    command=nvim
    ;;
  lazygit)
    # The pane entrypoint by absolute path: it assembles the layered
    # LG_CONFIG_FILE and execs the resolved binary, so a revived sidebar is
    # configured exactly like one the plugin opened. Asking herdr for the root
    # keeps the pinned install's hashed directory name out of this script.
    root=$("$herdr_bin" plugin list --json 2>/dev/null \
      | jq -r 'first(.result.plugins[]? | select(.plugin_id == "herdr-lazygit") | .plugin_root) // empty')
    [ -n "$root" ] || exit 0
    command="exec bash '$root/scripts/run-lazygit.sh'"
    ;;
esac

# `pane run` writes into the pty, which is safe here in a way it is not at pane
# creation: this shell has been at a prompt since the session came back, so there
# is no startup to race.
"$herdr_bin" pane run "$pane" "$command" >/dev/null 2>&1 || true
sleep 3
