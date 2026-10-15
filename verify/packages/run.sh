#!/usr/bin/env bash
# Check every declared package before any machine builds it, for all three platforms, from any host with Docker.
#
#   verify/packages/run.sh
#
# For each platform's package list it reports, per package: whether it evaluates (exists, not broken, licensed, built for that platform), whether cache.nixos.org has it prebuilt (so a switch downloads instead of compiling), and every file two packages both provide, which is what makes a profile build fail with "collision between". The macOS profile cannot be built on Linux, so its collisions are found from the cache's file listings instead.
#
# Packages this repository defines itself (nix/pkgs, the `only` wrappers in nix/home/darwin.nix) are not in the cache by design; they are listed as local and their files are not checked. Exits non-zero on anything else that fails.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Copied in, never mounted, and only what the git flake sees (verify/tree.sh): ignored secrets stay on the host.
"$ROOT/verify/tree.sh" | COPYFILE_DISABLE=1 tar --no-xattrs --no-fflags -C "$ROOT" -T - -cf - |
  docker run --rm -i -e USER=check -e HOME=/home/check nixos/nix:2.28.3 bash -euo pipefail -c '
    printf "experimental-features = nix-command flakes\n" >> /etc/nix/nix.conf
    mkdir -p /src && tar -C /src -xf - && cd /src
    exec nix shell --inputs-from . nixpkgs#jq nixpkgs#curl -c bash verify/packages/report.sh
  '
