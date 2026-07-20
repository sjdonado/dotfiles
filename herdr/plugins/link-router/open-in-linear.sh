#!/bin/sh
set -eu

target="https://linear.review/${HERDR_PLUGIN_CLICKED_URL#https://github.com/}"

case "$(uname -s)" in
  Darwin) exec open -b com.linear "$target" ;;
  Linux) exec xdg-open "$target" ;;
  *) exit 1 ;;
esac
