#!/usr/bin/env bash

DOTFILES_FAILURES=${DOTFILES_FAILURES:-0}
DOTFILES_UNVERIFIED=${DOTFILES_UNVERIFIED:-0}

log() { printf '\n==> %s\n' "$*"; }
note() { printf '  %s\n' "$*"; }
warn() { printf '  WARN %s\n' "$*" >&2; }
fail() { printf '  FAIL %s\n' "$*" >&2; DOTFILES_FAILURES=$((DOTFILES_FAILURES + 1)); }
unverified() { printf '  SKIP %s\n' "$*"; DOTFILES_UNVERIFIED=$((DOTFILES_UNVERIFIED + 1)); }
have() { command -v "$1" >/dev/null 2>&1; }

dotfiles_platform() {
  case "$(uname -s)" in
    Darwin) printf '%s\n' macos ;;
    Linux) printf '%s\n' linux ;;
    *) return 1 ;;
  esac
}

dotfiles_arch() {
  case "$(uname -m)" in
    arm64|aarch64) printf '%s\n' aarch64 ;;
    x86_64|amd64) printf '%s\n' x86_64 ;;
    *) return 1 ;;
  esac
}

run_step() {
  local name=$1
  shift
  log "$name"
  if "$@"; then
    note "ok: $name"
  else
    fail "$name"
  fi
}

dotfiles_realpath() {
  if have realpath; then realpath "$1"; else readlink -f "$1"; fi
}

dotfiles_report() {
  printf '\n%s failed, %s unverified\n' "$DOTFILES_FAILURES" "$DOTFILES_UNVERIFIED"
  [ "$DOTFILES_FAILURES" -eq 0 ]
}
