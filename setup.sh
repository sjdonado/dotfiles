#!/usr/bin/env bash
# Bootstrap this repository, then apply its shell-managed declaration.
set -euo pipefail

DOTFILES_REPO=https://github.com/sjdonado/dotfiles
if [ -z "${DOTFILES:-}" ]; then
  script_dir=$(cd "$(dirname "${BASH_SOURCE[0]:-./setup.sh}")" && pwd)
  if [ -n "${BASH_SOURCE[0]:-}" ] && [ -e "$script_dir/.git" ] && [ -f "$script_dir/sync.sh" ]; then DOTFILES=$script_dir
  else DOTFILES=$HOME/.config/dotfiles
  fi
fi
want=

usage() { printf 'usage: setup.sh [--macos | --linux]\n'; }
case "${1:-}" in
  '') ;;
  --macos) want=macos ;;
  --linux) want=linux ;;
  -h|--help) usage; exit 0 ;;
  *) printf 'unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
esac
[ "$#" -le 1 ] || { usage >&2; exit 2; }

case "$(uname -s)" in
  Darwin) platform=macos ;;
  Linux) platform=linux ;;
  *) printf 'unsupported system: %s\n' "$(uname -s)" >&2; exit 1 ;;
esac
[ -z "$want" ] || [ "$want" = "$platform" ] || { printf 'this machine is %s, not %s\n' "$platform" "$want" >&2; exit 2; }

if [ "$platform" = linux ] && [ ! -e "$DOTFILES/.git" ]; then
  if ! command -v git >/dev/null 2>&1; then
    sudo apt-get update -y
    sudo apt-get install -y git ca-certificates
  fi
  git clone "$DOTFILES_REPO" "$DOTFILES"
fi
[ -e "$DOTFILES/.git" ] || { printf 'clone %s to %s first\n' "$DOTFILES_REPO" "$DOTFILES" >&2; exit 1; }
exec "$DOTFILES/sync.sh"
