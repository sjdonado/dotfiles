#!/usr/bin/env bash
# Provision a disposable Ubuntu container twice and run the host checks.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
platform=
case "${1:-}" in
  '') ;;
  --platform) platform=${2:-}; shift ;;
  -h|--help) printf 'usage: verify/linux.sh [--platform linux/amd64 | --platform linux/arm64]\n'; exit 0 ;;
  *) printf 'unknown argument: %s\n' "$1" >&2; exit 2 ;;
esac
[ "$#" -le 1 ] || exit 2
case "$platform" in ''|linux/amd64|linux/arm64) ;; *) printf 'unsupported platform: %s\n' "$platform" >&2; exit 2 ;; esac
command -v docker >/dev/null 2>&1 || { printf 'Docker is required\n' >&2; exit 1; }
docker info >/dev/null 2>&1 || { printf 'Docker is unavailable\n' >&2; exit 1; }

archive=$(mktemp)
trap 'rm -f "$archive"' EXIT
git -C "$ROOT" ls-files -co --exclude-standard | sed '/^\.env$/d; /^\.env\./d; /^\.ssh\/private\.conf$/d' | tar -C "$ROOT" -T - -czf "$archive"
args=(run --rm -i -v "$archive:/tmp/dotfiles.tgz:ro")
[ -z "$platform" ] || args+=(--platform "$platform")
docker "${args[@]}" ubuntu:24.04 bash -s -- < <(cat <<'CONTAINER'
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq sudo ca-certificates git
useradd -m -s /bin/bash coder
printf 'coder ALL=(ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/coder
mkdir -p /home/coder/.config/dotfiles
tar -C /home/coder/.config/dotfiles -xzf /tmp/dotfiles.tgz
chown -R coder:coder /home/coder/.config/dotfiles
su - coder -c '/home/coder/.config/dotfiles/setup.sh --linux'
su - coder -c '/home/coder/.config/dotfiles/sync.sh --check'
first=$(find /home/coder -name '*.pre-shell' -print | sort | sha256sum)
su - coder -c '/home/coder/.config/dotfiles/setup.sh --linux'
su - coder -c '/home/coder/.config/dotfiles/sync.sh --check'
second=$(find /home/coder -name '*.pre-shell' -print | sort | sha256sum)
[ "$first" = "$second" ]
for file in /home/coder/.profile /home/coder/.zshenv /home/coder/.bashrc /home/coder/.zshrc; do
  ! grep -Eq '(/nix|\.nix-profile|mise|linuxbrew)' "$file"
done
printf 'Linux provisioning passed twice\n'
CONTAINER
)
