#!/bin/sh
# Hand the clicked URL to the default handler, once.
#
# herdr sets HERDR_PLUGIN_CLICKED_URL for a link handler action. `open` goes to
# whatever LaunchServices has as the default browser, which is Finicky, so all
# routing and rewriting stays in one place.
set -eu

[ -n "${HERDR_PLUGIN_CLICKED_URL:-}" ] || exit 0

exec open "$HERDR_PLUGIN_CLICKED_URL"
