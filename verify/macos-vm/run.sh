#!/usr/bin/env bash
# Full macos.sh rehearsal in a disposable macOS guest (tart + Virtualization.framework).
#
# verify/macos/run.sh is the fast loop: links only, ~5 s, throwaway HOME.
# This is the slow rehearsal: a real guest that runs everything the sandbox
# skips (Homebrew, mise installs, login shell, launchd, defaults) and is then
# discarded. Minutes, not seconds; run it before wiping a machine, not on
# every edit.
#
# Why tart and not custom tooling: tart is the maintained open-source
# Virtualization.framework frontend (OCI images, CoW clones, --dir sharing).
# A bespoke Swift wrapper reimplements it for nothing.
#
# Transport is SSH, not `tart exec`: exec's agent channel fails silently
# (exit 125, no output) on this image while sshd answers fine, and SSH also
# works on vanilla images with no agent at all. Auth is the base-image
# admin/admin convention via SSH_ASKPASS (askpass.sh): deterministic with
# stdin closed, where expect hung at the password prompt without sending.
# Throwaway guests only: host keys are never recorded.
#
#   verify/macos-vm/run.sh
#
# One-time cost, cached in ~/.tart afterwards: `brew install openai/tools/tart`
# (the cirruslabs tap is currently broken upstream) and a ~25 GB image pull.
# Apple allows 2 running macOS guests per host.
#
# Scope: single provision pass plus spot checks. A second-run idempotency
# pass and full assertion parity are future work, noted so nobody mistakes
# this for the finished check.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
BASE="${TART_BASE:-ghcr.io/cirruslabs/macos-tahoe-base:latest}"
GUEST_USER="${GUEST_USER:-admin}"
GUEST_PASSWORD="${GUEST_PASSWORD:-admin}"
VM="dotfiles-verify-macos-$$"

[ "$(uname)" = "Darwin" ] || { echo "macOS host only" >&2; exit 2; }
command -v tart >/dev/null 2>&1 || { echo "install tart first: brew install openai/tools/tart" >&2; exit 2; }
[ -x "$HERE/askpass.sh" ] || { echo "askpass.sh missing or not executable" >&2; exit 2; }

cleanup() {
  tart stop "$VM" >/dev/null 2>&1 || true
  tart delete "$VM" >/dev/null 2>&1 || true
  rm -f /tmp/tart-run-"$VM".log
  [ -n "${STAGE:-}" ] && rm -rf "$STAGE"
}
trap cleanup EXIT INT TERM

# The remote command travels pre-quoted: ssh joins its argv into one remote
# shell line, so an unquoted multi-word command would split and `bash -lc`
# would see only its first word. Quotes are added host-side, embedded quotes
# escaped the shell way. Password via askpass.sh with stdin closed.
guest() {
  local qc="'${1//\'/\'\\\'\'}'"
  SSH_ASKPASS="$HERE/askpass.sh" SSH_ASKPASS_REQUIRE=force DISPLAY=:0 \
  GUEST_PASSWORD="$GUEST_PASSWORD" \
    ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      "$GUEST_USER@$GUEST_IP" "bash -lc $qc" < /dev/null
}

echo "==> cloning $BASE (pulls ~25 GB on first use, cached after)"
tart clone "$BASE" "$VM"

echo "==> staging a filtered copy (the guest must not see live secrets)"
# The share is the guest's only view of the tree, so it cannot be the live
# checkout: gitignored secrets (.env, .ssh/private.conf) would sit readable
# next to third-party installers for the whole run. Same exclusion list as
# verify/linux/run.sh and verify/macos/run.sh; keep all three in sync.
STAGE="$(mktemp -d /tmp/dotfiles-verify-src.XXXXXX)"
rsync -a --exclude .git --exclude .agent --exclude .fseventsd --exclude .Trashes --exclude .env --exclude '.env.*' --exclude .ssh/private.conf --exclude .DS_Store "$ROOT/" "$STAGE/"

echo "==> booting headless with the staged tree mounted"
tart run --no-graphics "$VM" --dir=repo:"$STAGE" >/tmp/tart-run-"$VM".log 2>&1 &
echo "==> waiting for boot and sshd"
GUEST_IP="$(tart ip "$VM" --wait 300)"
[ -n "$GUEST_IP" ] || { echo "guest never got an IP; see /tmp/tart-run-$VM.log" >&2; exit 1; }
for _ in $(seq 1 60); do
  guest true >/dev/null 2>&1 && break
  sleep 10
done
guest true || { echo "guest never answered over SSH" >&2; exit 1; }

echo "==> copying the working tree off the shared mount (the installer touches it)"
# Measured: an unnamed --dir share exposes the tree at the share root, a
# named one under its name. Probe for the marker instead of assuming either.
# rsync, not cp -a or tar: macOS cp fails copying xattrs through virtiofs
# (ELOOP on symlinks) and bsdtar aborts the archive partway at the share's
# .Trashes entry, leaving a silently partial tree. rsync handles both.
guest 'SRC=""; for d in "/Volumes/My Shared Files/repo" "/Volumes/My Shared Files"; do [ -f "$d/macos.sh" ] && SRC="$d" && break; done; [ -n "$SRC" ] || { echo "no shared tree mounted" >&2; exit 1; }; rm -rf ~/verify-repo; mkdir -p ~/verify-repo; rsync -a --exclude .git --exclude .Trashes --exclude .DS_Store "$SRC/" ~/verify-repo/; test -f ~/verify-repo/macos.sh || { echo "copy incomplete" >&2; exit 1; }'

echo "==> full run: macos.sh --install"
guest 'cd ~/verify-repo && ./macos.sh --install'

echo "==> spot checks (full assertion parity is the next iteration)"
guest 'command -v mise && command -v rg && test -L ~/.gitconfig && test -L ~/.config/fish/config.fish && echo GUEST-OK'

echo
echo "==> rehearsal passed (guest discarded by the EXIT trap)"
