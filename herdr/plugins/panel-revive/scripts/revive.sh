#!/usr/bin/env bash
# Restart the program a restored plugin pane lost, on the focus that reveals it.
#
# The nvim tab is keyed by the label herdr kept across the restore, which is also
# what tells a restored pane apart from a shell someone opened themselves: only a
# plugin pane carries one.
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
# edit-tab's [[panes]] title, and the only plugin pane left to repair.
[ "$label" = nvim ] || exit 0

foreground=$("$herdr_bin" pane process-info --pane "$pane" 2>/dev/null \
  | jq -r '[.result.process_info.foreground_processes[]?.name] | join(" ")')
case " $foreground " in
  *" nvim "*) exit 0 ;;
esac

# Only a pane sitting at a shell gets revived. `pane run` types its argument into
# the pty, so firing it at a pane whose entrypoint is still exec'ing would land
# the command's characters inside the program that is starting: a stray "nvim" in
# an editor buffer rather than at a prompt. A restored pane is always a shell,
# which is the only case this plugin exists for.
case " $foreground " in
  *" fish "*|*" bash "*|*" zsh "*|*" sh "*) ;;
  *) exit 0 ;;
esac

# Two focus events can land while the program is still starting, and the second
# would type its name into the first. The lock is held past the write for that
# reason, not for the write itself: mkdir is the atomic part, the sleep is what
# covers the gap until the process shows up in process-info.
lock="${TMPDIR:-/tmp}/panel-revive-${pane//:/_}.lock"
mkdir "$lock" 2>/dev/null || exit 0
trap 'rmdir "$lock" 2>/dev/null || true' EXIT

# `pane run` writes into the pty, which is safe here in a way it is not at pane
# creation: this shell has been at a prompt since the session came back, so there
# is no startup to race.
"$herdr_bin" pane run "$pane" nvim >/dev/null 2>&1 || true

sleep 3
