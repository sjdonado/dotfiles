#!/usr/bin/env bash

homebrew_path_is_nix_link() {
  local path=$1 target
  [ -L "$path" ] || return 1
  target=$(readlink "$path")
  case "$target" in /nix/store/*) return 0 ;; *) return 1 ;; esac
}

retire_homebrew_nix_marker() {
  local marker="$1/.managed_by_nix_darwin"
  if [ -e "$marker" ]; then
    mv "$marker" "$marker.pre-shell" || return 1
  fi
}

detach_homebrew_files() {
  local prefix=$1 source=$2 backup=$3 relative path
  [ -x "$source/bin/brew" ] || { printf 'invalid Homebrew source checkout: %s\n' "$source" >&2; return 1; }
  [ -d "$source/Library/Homebrew" ] || { printf 'Homebrew source lacks Library/Homebrew\n' >&2; return 1; }
  mkdir -p "$backup" || return 1
  for relative in bin/brew Library/Homebrew Library/Taps; do
    path="$prefix/$relative"
    if [ -L "$path" ]; then
      homebrew_path_is_nix_link "$path" || { printf 'refusing to replace non-Nix link: %s\n' "$path" >&2; return 1; }
      mkdir -p "$backup/$(dirname "$relative")" || return 1
      if [ ! -e "$backup/$relative" ] && [ ! -L "$backup/$relative" ]; then
        cp -P "$path" "$backup/$relative" || return 1
      fi
      rm -f "$path" || return 1
    elif [ -e "$path" ] && [ "$relative" != Library/Taps ]; then
      printf 'refusing to replace unexpected real path: %s\n' "$path" >&2
      return 1
    fi
  done
  /usr/bin/ditto "$source" "$prefix" || return 1
  retire_homebrew_nix_marker "$prefix"
}

verify_homebrew_independence() {
  local brew=${1:-/opt/homebrew/bin/brew} value status=0
  for value in "$brew" "$("$brew" --repository)" "$("$brew" --prefix)"; do
    case "$(dotfiles_realpath "$value" 2>/dev/null || printf '%s' "$value")" in
      /nix/*) printf 'Homebrew still resolves through Nix: %s\n' "$value" >&2; status=1 ;;
    esac
  done
  [ -d "$("$brew" --repository)/.git" ] || { printf 'Homebrew repository is not an official Git checkout\n' >&2; status=1; }
  [ ! -L /opt/homebrew/Library/Taps ] || { printf 'Homebrew taps are still an immutable link\n' >&2; status=1; }
  return "$status"
}

migration_commit() {
  git -C "$DOTFILES" rev-parse HEAD
}

check_macos_account_checkouts() {
  local expected account checkout actual status=0
  expected=$(migration_commit) || return 1
  macos_load_accounts || return 1
  for account in "${MACOS_ACCOUNTS[@]}"; do
    checkout="/Users/$account/.config/dotfiles"
    if [ "$account" = "$(id -un)" ]; then
      actual=$(git -C "$checkout" rev-parse HEAD 2>/dev/null || true)
    else
      actual=$(sudo -H -u "$account" git -C "$checkout" rev-parse HEAD 2>/dev/null || true)
    fi
    if [ "$actual" != "$expected" ]; then
      printf 'Account checkout at %s must be updated to %s before migration (current: %s).\n' "$checkout" "$expected" "${actual:-unavailable}" >&2
      status=1
    fi
  done
  return "$status"
}

migration_fingerprint() {
  {
    migration_commit
    git -C "$DOTFILES" diff --binary -- . ':(exclude).env' ':(exclude).env.*'
    git -C "$DOTFILES" diff --cached --binary -- . ':(exclude).env' ':(exclude).env.*'
  } | shasum -a 256 | awk '{print $1}'
}

check_all_macos_accounts() {
  local expected account checkout actual status=0
  expected=$(migration_commit) || return 1
  macos_load_accounts || return 1
  for account in "${MACOS_ACCOUNTS[@]}"; do
    checkout="/Users/$account/.config/dotfiles"
    actual=$(sudo -H -u "$account" git -C "$checkout" rev-parse HEAD 2>/dev/null || true)
    if [ "$actual" != "$expected" ]; then
      printf '%s checkout is %s, expected %s\n' "$account" "${actual:-unavailable}" "$expected" >&2
      status=1
      continue
    fi
    if [ "$account" = "$(id -un)" ]; then
      DOTFILES="$checkout" "$checkout/sync.sh" --check || status=1
    else
      sudo -H -u "$account" env DOTFILES="$checkout" "$checkout/sync.sh" --check || status=1
    fi
  done
  return "$status"
}

record_migration_evidence() {
  local fingerprint state
  fingerprint=$(migration_fingerprint) || return 1
  state="$HOME/.local/state/dotfiles"
  mkdir -p "$state"
  printf '%s\n' "$fingerprint" > "$state/nix-migration-ready"
}

detach_homebrew_from_nix() {
  local temporary source backup tap brew
  require_macos_primary || return 1
  if ! homebrew_path_is_nix_link /opt/homebrew/bin/brew; then
    verify_homebrew_independence /opt/homebrew/bin/brew || return 1
    retire_homebrew_nix_marker /opt/homebrew
    return
  fi
  temporary=$(mktemp -d) || return 1
  source="$temporary/brew"
  backup="$HOME/.local/state/dotfiles/homebrew-nix-links"
  /usr/bin/git clone --depth 1 https://github.com/Homebrew/brew "$source" || { rm -rf "$temporary"; return 1; }
  detach_homebrew_files /opt/homebrew "$source" "$backup" || { rm -rf "$temporary"; return 1; }
  brew=/opt/homebrew/bin/brew
  while read -r tap; do
    [ -n "$tap" ] || continue
    HOMEBREW_NO_AUTO_UPDATE=1 "$brew" tap "$tap" || { rm -rf "$temporary"; return 1; }
  done < <(sed -n 's/^tap "\([^"]*\)".*/\1/p' "$DOTFILES/Brewfile")
  verify_homebrew_independence "$brew" || { rm -rf "$temporary"; return 1; }
  rm -rf "$temporary"
}

retire_nix_home_agents() {
  local uid label plist
  uid=$(id -u)
  for label in KeyRemapping TMExcludeDev; do
    plist="$HOME/Library/LaunchAgents/org.nix-community.home.$label.plist"
    [ -e "$plist" ] || continue
    launchctl bootout "gui/$uid" "$plist" 2>/dev/null || true
    rm -f "$plist"
  done
}

remove_retired_macos_software() {
  local brew
  brew=$(macos_brew) || return 1
  if "$brew" list --cask tailscale-app >/dev/null 2>&1; then
    "$brew" uninstall --cask --zap --force tailscale-app
  fi
}

run_nix_migration_until_uninstall_gate() {
  require_macos_primary || return 1
  migration_commit >/dev/null || return 1
  check_macos_account_checkouts || return 1
  detach_homebrew_from_nix || return 1
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$HOME/.local/bin:$HOME/.opencode/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
  remove_retired_macos_software || return 1
  apply_macos_machine apply || return 1
  verify_homebrew_independence || return 1
  check_all_macos_accounts || return 1
  record_migration_evidence || return 1
  printf '\nShell provisioning and Homebrew detachment passed.\n'
  printf 'Run sync.sh --uninstall-nix from this exact commit to remove Nix or resume finalization.\n'
}

nix_mount_table() { /sbin/mount; }

nix_store_removed() {
  local root=${1:-/nix} entries mounts
  mounts=$(nix_mount_table) || return 1
  if awk -v root="$root" '$3 == root { found=1 } END { exit !found }' <<<"$mounts"; then
    printf 'Nix volume is still mounted at %s\n' "$root" >&2
    return 1
  fi
  if [ -L "$root" ] || { [ -e "$root" ] && [ ! -d "$root" ]; }; then
    printf 'unexpected Nix path remains: %s\n' "$root" >&2
    return 1
  fi
  if [ -d "$root" ]; then
    entries=$(find "$root" -mindepth 1 -maxdepth 1 -print -quit) || return 1
    [ -z "$entries" ] || { printf 'Nix files remain under %s\n' "$root" >&2; return 1; }
  fi
}

uninstall_nix_after_migration_gate() {
  local expected actual uninstaller
  require_macos_primary || return 1
  actual=$(migration_fingerprint) || return 1
  expected=$(cat "$HOME/.local/state/dotfiles/nix-migration-ready" 2>/dev/null || true)
  [ -n "$expected" ] && [ "$actual" = "$expected" ] || { printf 'no passing migration evidence for this commit\n' >&2; return 1; }
  check_all_macos_accounts || return 1
  uninstaller=/nix/nix-installer
  if [ -x "$uninstaller" ]; then
    if [ -x /run/current-system/sw/bin/darwin-uninstaller ]; then
      sudo /run/current-system/sw/bin/darwin-uninstaller || return 1
      check_all_macos_accounts || return 1
    fi
    "$uninstaller" uninstall || return 1
  else
    note 'Nix installer is absent; checking whether removal already completed'
  fi
  nix_store_removed || return 1
  DOTFILES_BREW_CLEANUP=1 apply_homebrew apply || return 1
  check_all_macos_accounts || return 1
  printf '%s\n' "$actual" > "$HOME/.local/state/dotfiles/nix-migration-complete"
}
