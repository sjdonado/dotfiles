#!/usr/bin/env bash
# Run macos.sh against a throwaway HOME as a throwaway USER and assert links.
#
#   verify/macos/run.sh            # run, then delete user + sandbox
#   verify/macos/run.sh --keep     # leave both for inspection (see output)
#
# macOS cannot be containerised: there is no macOS Docker image, and Docker on
# a Mac is a Linux VM. A full-VM rehearsal exists in verify/macos-vm/ but is
# deferred (host vmnet NAT died under brew-download load and needs a host
# reboot to recover), so this sandbox is the check, hardened to the strongest
# isolation available without a VM:
#
# - a COPY of the working tree (no .git), owned by the test user: the
#   installer touches the tree it runs from, and it must not be the real one.
# - everything runs as an ephemeral local user whose only writable places
#   are the sandbox dirs. The real HOME is unreachable by file permission,
#   not just because $HOME points elsewhere.
# - user and dirs are deleted on exit, unless --keep.
#
# Needs sudo once (user create/delete). No other system state is touched:
# --links-only skips the login shell, /etc/shells, defaults, launchd,
# default-app bindings, the browser router and moshi-hook pairing, and the
# check asserts the skipped paths stayed absent.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# Deliberately NOT under $TMPDIR: on macOS that is /var/folders/<user>/...,
# whose intermediate dirs are 700, so the test user could never traverse
# into its own sandbox. /tmp is 1777 and traversable by everyone.
SANDBOX="$(mktemp -d /tmp/dotfiles-verify-macos.XXXXXX)"
VUSER="dotfiles-verify"
KEEP=0
[ "${1:-}" = "--keep" ] && KEEP=1

cleanup() {
  if [ "$KEEP" = 1 ]; then
    echo "sandbox kept at $SANDBOX (user $VUSER kept too)"
    echo "delete with: sudo sysadminctl -deleteUser $VUSER && sudo rm -rf $SANDBOX"
    return
  fi
  sudo sysadminctl -deleteUser "$VUSER" >/dev/null 2>&1 || true
  # Sandbox is owned by the test user (700), so only sudo can remove it.
  sudo rm -rf "$SANDBOX" 2>/dev/null || rm -rf "$SANDBOX" || true
}
trap cleanup EXIT INT TERM

[ "$(uname)" = "Darwin" ] || { echo "macOS only; on Linux use verify/linux/run.sh" >&2; exit 2; }
[ -n "$SANDBOX" ] && [ "$SANDBOX" != "$HOME" ] || { echo "refusing: bad sandbox dir" >&2; exit 2; }

echo "==> staging a copy of the working tree (the installer touches it)"
mkdir -p "$SANDBOX/repo" "$SANDBOX/home" "$SANDBOX/tmp"
# .git is a worktree pointer file here, not a dir; either way it must not
# travel. .agent holds local-only proto notes, .fseventsd is volume noise.
# .env* and .ssh/private.conf are gitignored secrets the check never needs
# (pairing skips gracefully without a token); the sandbox user must not be
# able to read them. Exclusion lists mirror verify/linux/run.sh; keep both in
# sync when a new secret-bearing name appears.
rsync -a --exclude .git --exclude .agent --exclude .fseventsd --exclude .Trashes --exclude .env --exclude '.env.*' --exclude .ssh/private.conf "$ROOT/" "$SANDBOX/repo/"

echo "==> creating ephemeral user $VUSER (sudo)"
# The FDE warning sysadminctl prints here is expected: a scripted user gets
# no FileVault unlock, which a throwaway verify user never needs.
sudo sysadminctl -deleteUser "$VUSER" >/dev/null 2>&1 || true
VPASS="$(openssl rand -base64 24)"
sudo sysadminctl -addUser "$VUSER" -password "$VPASS" -fullName "dotfiles verify" -home "$SANDBOX/home" >/dev/null 2>&1 || true
id "$VUSER" >/dev/null
sudo chown -R "$VUSER:staff" "$SANDBOX"

as_user() { sudo -u "$VUSER" env HOME="$SANDBOX/home" TMPDIR="$SANDBOX/tmp" PATH="$PATH" "$@"; }
# The sandbox is 700 and user-owned, so anything that touches files inside
# it (redirects, find, tail) must run as the user or under sudo. Redirects
# in particular execute in THIS shell, so they live inside the as_user call.

echo "==> first run: macos.sh --links-only as $VUSER"
as_user bash -c "cd '$SANDBOX/repo' && ./macos.sh --links-only >'$SANDBOX/run1.log' 2>&1" \
  || { echo "run failed:"; sudo tail -30 "$SANDBOX/run1.log"; exit 1; }

echo "==> verifying"
as_user env DOTFILES="$SANDBOX/repo" bash "$SANDBOX/repo/verify/macos/verify.sh"

# A first run legitimately backs one file up: `herdr integration install claude`
# writes a real ~/.claude/settings.json before the script links the tracked one
# over it, which is why that install runs first. So the baseline is whatever the
# first pass produced, and the second pass has to add nothing to it.
before="$(as_user find "$SANDBOX" -name '*.backup.*' 2>/dev/null | sort || true)"

# The second pass is the point: link_managed backs up anything that is not
# already the right link, so a bug there turns every re-run into a pile of
# .backup.<timestamp> files next to the real config.
echo "==> second run: macos.sh --links-only again (idempotency)"
as_user bash -c "cd '$SANDBOX/repo' && ./macos.sh --links-only >'$SANDBOX/run2.log' 2>&1" \
  || { echo "second run failed:"; sudo tail -30 "$SANDBOX/run2.log"; exit 1; }

echo "==> verifying again"
as_user env DOTFILES="$SANDBOX/repo" bash "$SANDBOX/repo/verify/macos/verify.sh"

echo "==> checking the second run replaced nothing"
after="$(as_user find "$SANDBOX" -name '*.backup.*' 2>/dev/null | sort || true)"
if [ "$before" != "$after" ]; then
  echo "FAIL the second run backed a file up, so it is replacing a link it should have left alone:"
  comm -13 <(printf '%s\n' "$before") <(printf '%s\n' "$after") | sed 's/^/  /'
  exit 1
fi
echo "  ok   the second run replaced nothing"

echo
echo "==> all checks passed"
