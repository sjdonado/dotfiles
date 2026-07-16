#!/bin/sh
set -eu

url="${HERDR_PLUGIN_CLICKED_URL:-}"
herdr="${HERDR_BIN_PATH:-herdr}"

case "$url" in
  https://github.com/*/*/pull/[0-9]*) ;;
  *)
    "$herdr" notification show "Link Router" --body "Not a GitHub pull request URL" || true
    exit 1
    ;;
esac

linear_url="https://linear.review/${url#https://github.com/}"
case "$(uname -s)" in
  Darwin) exec open "$linear_url" ;;
  Linux) exec xdg-open "$linear_url" ;;
  *)
    "$herdr" notification show "Link Router" --body "Unsupported platform" || true
    exit 1
    ;;
esac
