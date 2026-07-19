#!/bin/sh
set -eu

url="${HERDR_PLUGIN_CLICKED_URL:-}"
herdr="${HERDR_BIN_PATH:-herdr}"

# Defensive re-check; the link_handler pattern already gates this.
case "$url" in
  http://localhost*|https://localhost*) ;;
  http://127.0.0.1*|https://127.0.0.1*) ;;
  http://0.0.0.0*|https://0.0.0.0*) ;;
  http://\[::1\]*|https://\[::1\]*) ;;
  http://*.localhost*|https://*.localhost*) ;;
  *)
    "$herdr" notification show "Link Router" --body "Not a localhost URL" || true
    exit 1
    ;;
esac

case "$(uname -s)" in
  Darwin) exec open -b net.imput.helium "$url" ;;
  Linux) exec helium "$url" ;;
  *)
    "$herdr" notification show "Link Router" --body "Unsupported platform" || true
    exit 1
    ;;
esac
