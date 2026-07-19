#!/bin/sh
set -eu

# Open GitHub pull requests and Linear links in the Linear desktop app.
# NOTE: herdr runs this on the SERVER host. In `--remote` mode that is the
# remote box, so the app opens there (or falls back to a browser), not on the
# local client. Meaningful only when the herdr server is your local machine.

url="${HERDR_PLUGIN_CLICKED_URL:-}"
herdr="${HERDR_BIN_PATH:-herdr}"

case "$url" in
  https://github.com/*/*/pull/[0-9]*)
    # Map a GitHub PR to its Linear review URL.
    target="https://linear.review/${url#https://github.com/}" ;;
  https://linear.app/*|https://linear.review/*)
    target="$url" ;;
  *)
    "$herdr" notification show "Link Router" --body "Not a Linear or GitHub PR URL" || true
    exit 1 ;;
esac

case "$(uname -s)" in
  # Hand the URL to Linear.app; its universal-link router opens the right view.
  Darwin) exec open -b com.linear "$target" ;;
  # No Linear app on Linux hosts; fall back to the default browser.
  Linux) exec xdg-open "$target" ;;
  *)
    "$herdr" notification show "Link Router" --body "Unsupported platform" || true
    exit 1 ;;
esac
