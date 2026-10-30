#!/usr/bin/env bash
# Apply, upgrade, check, or migrate the shell-managed workspace declaration.
set -uo pipefail

DOTFILES=${DOTFILES:-$HOME/.config/dotfiles}
export DOTFILES
. "$DOTFILES/lib/core.sh"
. "$DOTFILES/hosts/macos.sh"
. "$DOTFILES/lib/links.sh"
. "$DOTFILES/lib/installers.sh"
. "$DOTFILES/lib/macos.sh"
. "$DOTFILES/lib/linux.sh"
. "$DOTFILES/lib/migration.sh"

usage() { printf 'usage: sync.sh [--check | --upgrade | --migrate-from-nix | --uninstall-nix | --user-only]\n'; }
mode=apply
case "${1:-}" in
  '') ;;
  --check) mode=check ;;
  --upgrade) mode=upgrade ;;
  --migrate-from-nix) mode=migrate ;;
  --uninstall-nix) mode=uninstall ;;
  --user-only) mode=user ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac
[ "$#" -le 1 ] || { usage >&2; exit 2; }

platform=$(dotfiles_platform) || { printf 'unsupported platform\n' >&2; exit 1; }
case "$mode:$platform" in
  migrate:macos) run_nix_migration_until_uninstall_gate || fail 'Nix migration before uninstall gate' ;;
  uninstall:macos) uninstall_nix_after_migration_gate || fail 'Nix uninstall' ;;
  migrate:*|uninstall:*) printf '%s is macOS only\n' "--$mode" >&2; exit 2 ;;
  user:macos)
    macos_load_accounts || { printf 'unknown macOS host\n' >&2; exit 1; }
    [ "${SUDO_USER:-}" = "$MACOS_PRIMARY" ] || { printf '%s\n' '--user-only is reserved for primary-account orchestration' >&2; exit 1; }
    apply_macos_user
    ;;
  user:*) printf '%s\n' '--user-only is macOS only' >&2; exit 2 ;;
  check:macos) check_macos_state || fail 'macOS host check' ;;
  check:linux) check_linux_state || fail 'Linux host check' ;;
  *:macos)
    apply_macos_machine "$mode" || fail 'macOS apply'
    check_macos_state || fail 'macOS host check'
    ;;
  *:linux)
    apply_linux "$mode" || fail 'Linux apply'
    check_linux_state || fail 'Linux host check'
    ;;
esac

dotfiles_report
