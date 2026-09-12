#!/usr/bin/env bash
# Run macos.sh against a throwaway HOME and assert what it linked.
#
#   verify/macos/run.sh
#
# macOS cannot be containerised: there is no macOS Docker image, and Docker on a
# Mac is a Linux VM. A real macOS VM means tart or UTM and a ~20GB image, which
# is worth it for a full from-scratch rehearsal and far too slow for the loop
# this replaces. So this does the next best thing: the half of macos.sh that only
# writes inside $HOME, with $HOME pointed somewhere disposable.
#
# What that covers: every symlink, every generated file, the pruning of links
# this repo no longer ships, and that --links-only really does skip the blocks
# that touch the machine. What it does not: Homebrew, mise installing anything,
# the login shell, launchd, macOS defaults, LaunchServices. Those are verified by
# running the script for real.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-verify-macos.XXXXXX")"
KEEP=0
[ "${1:-}" = "--keep" ] && KEEP=1

cleanup() { [ "$KEEP" = 1 ] && { echo "sandbox kept at $SANDBOX"; return; }; rm -rf "$SANDBOX"; }
trap cleanup EXIT INT TERM

[ "$(uname)" = "Darwin" ] || { echo "macOS only; on Linux use verify/linux/run.sh" >&2; exit 2; }

echo "==> sandbox HOME: $SANDBOX"
echo "==> first run: macos.sh --links-only"
( cd "$ROOT" && HOME="$SANDBOX" ./macos.sh --links-only ) >"$SANDBOX/run1.log" 2>&1 \
  || { echo "run failed:"; tail -30 "$SANDBOX/run1.log"; exit 1; }

echo "==> verifying"
HOME="$SANDBOX" DOTFILES="$ROOT" "$ROOT/verify/macos/verify.sh"

# A first run legitimately backs one file up: `herdr integration install claude`
# writes a real ~/.claude/settings.json before the script links the tracked one
# over it, which is why that install runs first. So the baseline is whatever the
# first pass produced, and the second pass has to add nothing to it.
before="$(find "$SANDBOX" -name '*.backup.*' 2>/dev/null | sort || true)"

# The second pass is the point: link_managed backs up anything that is not
# already the right link, so a bug there turns every re-run into a pile of
# .backup.<timestamp> files next to the real config.
echo "==> second run: macos.sh --links-only again (idempotency)"
( cd "$ROOT" && HOME="$SANDBOX" ./macos.sh --links-only ) >"$SANDBOX/run2.log" 2>&1 \
  || { echo "second run failed:"; tail -30 "$SANDBOX/run2.log"; exit 1; }

echo "==> verifying again"
HOME="$SANDBOX" DOTFILES="$ROOT" "$ROOT/verify/macos/verify.sh"

echo "==> checking the second run replaced nothing"
after="$(find "$SANDBOX" -name '*.backup.*' 2>/dev/null | sort || true)"
if [ "$before" != "$after" ]; then
  echo "FAIL the second run backed a file up, so it is replacing a link it should have left alone:"
  comm -13 <(printf '%s\n' "$before") <(printf '%s\n' "$after") | sed 's/^/  /'
  exit 1
fi
echo "  ok   the second run replaced nothing"

echo
echo "==> all checks passed"
