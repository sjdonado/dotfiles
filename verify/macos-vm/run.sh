#!/usr/bin/env bash
# The full macOS check: a disposable macOS guest (tart on Virtualization.framework) that runs macos.sh from this working tree, which installs Nix and switches the darwin configuration, then switches a second time, asserts the result after each, and is discarded. Nothing on this Mac changes beyond tart's image cache in ~/.tart.
#
#   verify/macos-vm/run.sh
#
# verify/macos/run.sh is the fast loop (evaluate or build, no activation). This is the slow rehearsal that has to pass before the first switch on a real Mac: Homebrew adoption, every cask, launchd, defaults and the login shell, for real. It downloads every cask, so expect tens of minutes and several GB.
#
# tart comes from nixpkgs (`nix run nixpkgs#tart`), so Nix has to be on this Mac first; installing Nix alone changes no package, link or setting here. The first run pulls the ~25 GB base image. Apple allows two running macOS guests per host.
#
# Transport is SSH, not `tart exec`: exec's agent channel fails silently (exit 125, no output) on this image while sshd answers. Auth is the base image's admin/admin convention via SSH_ASKPASS (askpass.sh). Throwaway guests only: host keys are never recorded.
#
# The guest uses darwinConfigurations.verify-vm: the same modules as this Mac's configuration, for the base image's admin user, without App Store apps (the guest has no App Store account).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
BASE="${TART_BASE:-ghcr.io/cirruslabs/macos-tahoe-base:latest}"
GUEST_USER="${GUEST_USER:-admin}"
GUEST_PASSWORD="${GUEST_PASSWORD:-admin}"
VM="dotfiles-verify-macos-$$"

[ "$(uname)" = "Darwin" ] || { echo "macOS host only" >&2; exit 2; }
command -v nix >/dev/null 2>&1 || { echo "Nix is needed on this Mac for tart: ./macos.sh --nix-only installs it and changes nothing else" >&2; exit 2; }
[ -x "$HERE/askpass.sh" ] || { echo "askpass.sh missing or not executable" >&2; exit 2; }
tart() { nix run --inputs-from "$ROOT" nixpkgs#tart -- "$@"; }

cleanup() {
  tart stop "$VM" >/dev/null 2>&1 || true
  tart delete "$VM" >/dev/null 2>&1 || true
  [ -n "${LOGS:-}" ] && rm -rf "$LOGS"
  [ -n "${STAGE:-}" ] && rm -rf "$STAGE"
}
trap cleanup EXIT INT TERM

# The remote command travels pre-quoted: ssh joins its argv into one remote shell line. Password via askpass.sh with stdin closed.
guest() {
  local qc="'${1//\'/\'\\\'\'}'"
  SSH_ASKPASS="$HERE/askpass.sh" SSH_ASKPASS_REQUIRE=force DISPLAY=:0 GUEST_PASSWORD="$GUEST_PASSWORD" \
    ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      "$GUEST_USER@$GUEST_IP" "bash -lc $qc" < /dev/null
}

echo "==> cloning $BASE (pulls ~25 GB on first use, cached after)"
tart clone "$BASE" "$VM"

echo "==> staging a filtered copy (the guest must not see live secrets)"
# The share is the guest's only view of the tree, so it cannot be the live checkout: gitignored secrets (.env, .ssh/private.conf) would sit readable next to third-party installers. verify/tree.sh lists what the git flake sees.
STAGE="$(mktemp -d)"
LOGS="$(mktemp -d)"
"$ROOT/verify/tree.sh" | rsync -a --files-from=- "$ROOT/" "$STAGE/"

echo "==> booting headless with the staged tree mounted"
tart run --no-graphics "$VM" --dir=repo:"$STAGE" > "$LOGS/tart.log" 2>&1 &
GUEST_IP="$(tart ip "$VM" --wait 300)"
[ -n "$GUEST_IP" ] || { echo "guest never got an IP; see $LOGS/tart.log" >&2; exit 1; }
for _ in $(seq 1 60); do
  guest true >/dev/null 2>&1 && break
  sleep 10
done
guest true || { echo "guest never answered over SSH" >&2; exit 1; }
echo "  guest: $(guest 'sw_vers -productName; sw_vers -productVersion' | paste -sd' ' -)"

echo "==> copying the tree to ~/.config/dotfiles (the configuration links there)"
# rsync, not cp -a or tar: macOS cp fails on xattrs through virtiofs and bsdtar stops at the share's .Trashes entry. An unnamed share appears at the root, a named one under its name, so probe for both.
guest 'SRC=""; for d in "/Volumes/My Shared Files/repo" "/Volumes/My Shared Files"; do [ -f "$d/flake.nix" ] && SRC="$d" && break; done; [ -n "$SRC" ] || { echo "no shared tree mounted" >&2; exit 1; }; mkdir -p ~/.config; rm -rf ~/.config/dotfiles; rsync -a --exclude .Trashes --exclude .DS_Store "$SRC/" ~/.config/dotfiles/; test -f ~/.config/dotfiles/flake.nix'

# macos.sh switches through sudo; the base image's admin needs the password once per session, so it is primed through askpass.
switch() {
  guest "echo '$GUEST_PASSWORD' | sudo -S -v 2>/dev/null; cd ~/.config/dotfiles && DARWIN_CONFIG=verify-vm ./macos.sh" > "$LOGS/$1.log" 2>&1 \
    || { echo "$1 failed:"; tail -40 "$LOGS/$1.log"; exit 1; }
  grep -E '^==>|dotfiles:' "$LOGS/$1.log" | sed 's/^/  /' || true
}

echo "==> first run: macos.sh"
switch run1
echo "==> verifying"
guest 'bash ~/.config/dotfiles/verify/macos-vm/verify.sh'
# No herdr server runs in the guest, so the plugin step has to report itself skipped rather than pass silently.
if grep -q 'dotfiles: skipped herdr-plugins' "$LOGS/run1.log"; then echo "  ok   the herdr plugin step reported itself skipped"; else echo "  FAIL the herdr plugin step did not report its skip"; exit 1; fi

before="$(guest 'readlink -f /nix/var/nix/profiles/system; find ~ -maxdepth 4 -name "*.pre-nix" 2>/dev/null | sort')"
[ -n "$(head -1 <<<"$before")" ] || { echo "  FAIL no nix-darwin system after the first run"; exit 1; }
echo "==> second run: macos.sh again (idempotency)"
switch run2
echo "==> verifying again"
guest 'bash ~/.config/dotfiles/verify/macos-vm/verify.sh'
after="$(guest 'readlink -f /nix/var/nix/profiles/system; find ~ -maxdepth 4 -name "*.pre-nix" 2>/dev/null | sort')"
if [ "$before" = "$after" ]; then
  echo "  ok   the second run kept the same system and left no new backups"
else
  echo "  FAIL the second run changed the system or left backups:"
  diff <(printf '%s\n' "$before") <(printf '%s\n' "$after") | sed 's/^/  /'
  exit 1
fi
if grep -q 'Installing Nix' "$LOGS/run2.log"; then echo "  FAIL the second run installed Nix again"; exit 1; fi

echo
echo "==> rehearsal passed (guest discarded on exit)"
