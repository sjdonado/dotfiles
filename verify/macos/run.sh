#!/usr/bin/env bash
# The fast macOS check: evaluate the darwin configuration and assert what a switch would apply, without applying it. Nothing on this Mac changes.
#
#   verify/macos/run.sh
#
# With Nix on this Mac it also builds the whole system closure (`nix build`, no activation), which is what catches a package that does not build or a profile collision. Without Nix it evaluates inside a Linux container, which proves the configuration is well-formed and complete but builds nothing; verify/packages/run.sh covers availability and collisions from there.
#
# The full check is verify/macos-vm/run.sh: a disposable macOS guest that switches for real, twice.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
HOST="${HOST_CONFIG:-Juans-MacBook-Pro}"
USER_NAME="${USER_CONFIG:-juan}"

if command -v nix >/dev/null 2>&1; then
  # Built from a copy of what the git flake sees (verify/tree.sh): `path:` puts everything it is given into the world-readable /nix/store, so ignored files must not be in it, and unstaged files still count.
  STAGE="$(mktemp -d)"
  trap 'rm -rf "$STAGE"' EXIT
  "$ROOT/verify/tree.sh" | rsync -a --files-from=- "$ROOT/" "$STAGE/"
  echo "==> building darwinConfigurations.$HOST (no activation)"
  nix build --no-link --print-out-paths "path:$STAGE#darwinConfigurations.\"$HOST\".system"
  cd "$STAGE"
  HOST="$HOST" USER_NAME="$USER_NAME" bash "$HERE/verify.sh"
else
  echo "==> no Nix on this Mac: evaluating in a container (nothing is built)"
  "$ROOT/verify/tree.sh" | COPYFILE_DISABLE=1 tar --no-xattrs --no-fflags -C "$ROOT" -T - -cf - |
    docker run --rm -i -e HOST="$HOST" -e USER_NAME="$USER_NAME" nixos/nix:2.28.3 bash -euo pipefail -c '
      printf "experimental-features = nix-command flakes\n" >> /etc/nix/nix.conf
      mkdir -p /src && tar -C /src -xf - && cd /src
      echo "==> evaluating darwinConfigurations.$HOST"
      nix eval --raw ".#darwinConfigurations.\"$HOST\".system.drvPath" >/dev/null
      exec nix shell --inputs-from . nixpkgs#jq -c bash verify/macos/verify.sh
    '
fi
