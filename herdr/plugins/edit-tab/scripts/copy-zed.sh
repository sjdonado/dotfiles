#!/usr/bin/env bash
set -euo pipefail

: "${HERDR_ZED_COMMAND:?Missing remote Zed command}"
payload=$(printf '%s' "$HERDR_ZED_COMMAND" | base64 | tr -d '\r\n')
printf '\033]52;c;%s\007' "$payload"
printf 'Clipboard request sent to the foreground Herdr client.\n\n%s\n\nIf clipboard access is blocked, copy the command above manually.\nPress Enter to close.\n' "$HERDR_ZED_COMMAND"
# Stay alive until dismissal: exiting immediately can race Herdr's PTY/OSC52 reader.
read -r _
