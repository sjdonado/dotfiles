#!/usr/bin/env bash

macos_host_name() {
  if [ -n "${DOTFILES_HOST:-}" ]; then printf '%s\n' "$DOTFILES_HOST"; return; fi
  /usr/sbin/scutil --get LocalHostName
}

macos_load_accounts() {
  local host=${1:-$(macos_host_name)}
  local account
  MACOS_ACCOUNTS=()
  while IFS= read -r account; do
    [ -n "$account" ] && MACOS_ACCOUNTS+=("$account")
  done < <(macos_accounts_for_host "$host")
  [ "${#MACOS_ACCOUNTS[@]}" -gt 0 ] || return 1
  MACOS_PRIMARY=${MACOS_ACCOUNTS[0]}
}

require_macos_primary() {
  macos_load_accounts || { printf 'unknown macOS host: %s\n' "$(macos_host_name)" >&2; return 1; }
  if [ "${DOTFILES_CURRENT_USER:-$(id -un)}" != "$MACOS_PRIMARY" ]; then
    printf 'Only the primary account may change shared macOS state. Run sync.sh --check from this account.\n' >&2
    return 1
  fi
}

macos_brew() {
  if [ -n "${DOTFILES_BREW:-}" ]; then printf '%s\n' "$DOTFILES_BREW"
  elif [ -x /opt/homebrew/bin/brew ]; then printf '%s\n' /opt/homebrew/bin/brew
  elif have brew; then command -v brew
  else return 1
  fi
}

ensure_homebrew() {
  local installer
  macos_brew >/dev/null 2>&1 && return 0
  installer=$(mktemp)
  curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$installer"
  NONINTERACTIVE=1 /bin/bash "$installer"
  rm -f "$installer"
  macos_brew >/dev/null
}

apply_homebrew() {
  local mode=$1 brew
  ensure_homebrew || return 1
  brew=$(macos_brew) || return 1
  if [ "$mode" = upgrade ]; then
    HOMEBREW_NO_AUTO_UPDATE=1 "$brew" update
    HOMEBREW_NO_AUTO_UPDATE=1 "$brew" upgrade
    HOMEBREW_NO_AUTO_UPDATE=1 "$brew" bundle install --file "$DOTFILES/Brewfile"
  else
    HOMEBREW_NO_AUTO_UPDATE=1 "$brew" bundle install --no-upgrade --file "$DOTFILES/Brewfile"
  fi
  if [ "${DOTFILES_BREW_CLEANUP:-0}" = 1 ]; then
    HOMEBREW_NO_AUTO_UPDATE=1 "$brew" bundle cleanup --force --file "$DOTFILES/Brewfile"
  fi
}

apply_macos_defaults() {
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  defaults write com.apple.finder AppleShowAllFiles -bool true
  "$DOTFILES/macos/app-shortcuts.sh"
}

render_launch_agent() {
  local template=$1 destination=$2 placeholder=$3 replacement=$4 placeholder2=${5:-} replacement2=${6:-} temporary
  mkdir -p "$(dirname "$destination")" "$HOME/Library/Logs"
  temporary=$(mktemp "$destination.XXXXXX")
  if [ -n "$placeholder2" ]; then
    sed -e "s|$placeholder|$replacement|g" -e "s|$placeholder2|$replacement2|g" "$template" > "$temporary"
  else
    sed "s|$placeholder|$replacement|g" "$template" > "$temporary"
  fi
  plutil -lint "$temporary" >/dev/null
  if [ -f "$destination" ] && cmp -s "$temporary" "$destination"; then
    rm -f "$temporary"
  else
    mv -f "$temporary" "$destination"
  fi
}

apply_macos_launch_agents() {
  local uid key_agent tm_agent
  uid=$(id -u)
  key_agent="$HOME/Library/LaunchAgents/com.local.KeyRemapping.plist"
  tm_agent="$HOME/Library/LaunchAgents/com.local.TMExcludeDev.plist"
  render_launch_agent "$DOTFILES/macos/com.local.KeyRemapping.plist" "$key_agent" __CAPS_TO_CONTROL_SCRIPT__ "$DOTFILES/macos/caps-to-control.sh"
  render_launch_agent "$DOTFILES/macos/com.local.TMExcludeDev.plist" "$tm_agent" __TM_EXCLUDE_SCRIPT__ "$DOTFILES/macos/tm-exclude-dev.sh" __TM_LOG__ "$HOME/Library/Logs/dotfiles-time-machine-exclusions.log"
  if [ "${DOTFILES_PREFLIGHT:-0}" = 1 ]; then
    unverified "launch agents rendered in preflight"
  elif launchctl print "gui/$uid" >/dev/null 2>&1; then
    launchctl bootout "gui/$uid" "$key_agent" 2>/dev/null || true
    launchctl bootstrap "gui/$uid" "$key_agent"
    launchctl bootout "gui/$uid" "$tm_agent" 2>/dev/null || true
    launchctl bootstrap "gui/$uid" "$tm_agent"
  else
    unverified "launch agents rendered but this account has no GUI session"
  fi
}

apply_browser_router() {
  local source=/opt/homebrew/opt/browser-router/BrowserRouter.app destination="$HOME/Applications/BrowserRouter.app"
  [ -d "$source" ] || { unverified "BrowserRouter formula is not installed"; return 0; }
  mkdir -p "$HOME/Applications"
  if [ ! -d "$destination" ] || ! cmp -s "$source/Contents/MacOS/BrowserRouter" "$destination/Contents/MacOS/BrowserRouter"; then
    rm -rf "$destination"
    cp -R "$source" "$destination"
  fi
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$destination"
}

apply_macos_user() {
  install_macos_user_tools
  apply_common_links
  apply_macos_links
  managed_link /opt/homebrew/opt/openjdk@11 "$HOME/.local/opt/jdk11"
  managed_link /opt/homebrew/opt/openjdk@17 "$HOME/.local/opt/jdk17"
  managed_link /opt/homebrew/opt/llvm "$HOME/.local/opt/llvm"
  managed_link /opt/homebrew/opt/openssl@4 "$HOME/.local/opt/openssl-4"
  managed_link /opt/homebrew/opt/zig@0.15 "$HOME/.local/opt/zig-0_15"
  apply_generated_user_state
  mkdir -p "$HOME/Library/Keyboard Layouts"
  if [ -d "$DOTFILES/macos/ukelele" ]; then cp -Rp "$DOTFILES/macos/ukelele/"* "$HOME/Library/Keyboard Layouts/"; fi
  apply_browser_router
  if [ -d /Applications/Zed.app ]; then
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/Zed.app
  fi
  if have duti; then duti "$DOTFILES/macos/default-apps.duti" || true; fi
  apply_macos_launch_agents
  apply_macos_defaults
  if type retire_nix_home_agents >/dev/null 2>&1; then retire_nix_home_agents; fi
}

apply_macos_machine() {
  local mode=$1 account shell
  require_macos_primary
  apply_homebrew "$mode"
  grep -qx /bin/zsh /etc/shells || printf '%s\n' /bin/zsh | sudo tee -a /etc/shells >/dev/null
  for account in "${MACOS_ACCOUNTS[@]}"; do
    if ! id -u "$account" >/dev/null 2>&1; then warn "$account is declared but has no macOS account"; continue; fi
    shell=$(dscl . -read "/Users/$account" UserShell 2>/dev/null | awk '{print $2}')
    if [ "$shell" != /bin/zsh ]; then sudo dscl . -create "/Users/$account" UserShell /bin/zsh; fi
  done
  for account in "${MACOS_ACCOUNTS[@]}"; do
    if [ "$account" = "$(id -un)" ]; then
      apply_macos_user
    else
      sudo -H -u "$account" env DOTFILES="/Users/$account/.config/dotfiles" "/Users/$account/.config/dotfiles/sync.sh" --user-only
    fi
  done
}

check_macos_state() {
  local status=0 brew item stray command_path primary_uid app app_uid
  macos_load_accounts || return 1
  [ "$(dscl . -read "$HOME" UserShell 2>/dev/null | awk '{print $2}')" = /bin/zsh ] || { printf 'login shell is not /bin/zsh\n' >&2; status=1; }
  check_link_registry "$(common_link_registry)" || status=1
  check_link_registry "$(macos_link_registry)" || status=1
  [ -f "$HOME/.codex/config.toml" ] || { printf 'generated Codex config is missing\n' >&2; status=1; }
  [ -f "$HOME/.hushlogin" ] || { printf '.hushlogin is missing\n' >&2; status=1; }
  [ -d "$HOME/Applications/BrowserRouter.app" ] || { printf 'BrowserRouter app is missing\n' >&2; status=1; }
  if [ -d "$DOTFILES/macos/ukelele" ]; then
    for item in "$DOTFILES/macos/ukelele/"*; do [ -e "$HOME/Library/Keyboard Layouts/$(basename "$item")" ] || { printf 'keyboard layout missing: %s\n' "$(basename "$item")" >&2; status=1; }; done
  fi
  for item in jdk11:openjdk@11 jdk17:openjdk@17 llvm:llvm openssl-4:openssl@4 zig-0_15:zig@0.15; do
    [ "$(dotfiles_realpath "$HOME/.local/opt/${item%%:*}" 2>/dev/null || true)" = "$(dotfiles_realpath "/opt/homebrew/opt/${item#*:}" 2>/dev/null || true)" ] || { printf 'keg link missing: %s\n' "${item%%:*}" >&2; status=1; }
  done
  brew=$(macos_brew) || return 1
  while read -r item; do
    [ -n "$item" ] || continue
    "$brew" list --formula "$item" >/dev/null 2>&1 || { printf 'formula missing: %s\n' "$item" >&2; status=1; }
  done < <(sed -n 's/^brew "\([^"]*\)".*/\1/p' "$DOTFILES/Brewfile")
  while read -r item; do
    [ -n "$item" ] || continue
    "$brew" list --cask "$item" >/dev/null 2>&1 || { printf 'cask missing: %s\n' "$item" >&2; status=1; }
  done < <(sed -n 's/^cask "\([^"]*\)".*/\1/p' "$DOTFILES/Brewfile")
  [ "$(defaults read NSGlobalDomain AppleShowAllExtensions 2>/dev/null)" = 1 ] || { printf 'AppleShowAllExtensions is not set\n' >&2; status=1; }
  [ "$(defaults read com.apple.finder AppleShowAllFiles 2>/dev/null)" = 1 ] || { printf 'AppleShowAllFiles is not set\n' >&2; status=1; }
  stray=$(find /opt/homebrew ! -user "$MACOS_PRIMARY" ! -user root -print -quit 2>/dev/null || true)
  [ -z "$stray" ] || { printf 'foreign Homebrew owner: %s\n' "$stray" >&2; status=1; }
  primary_uid=$(id -u "$MACOS_PRIMARY")
  for app in /Applications/*.app; do
    [ -e "$app" ] || continue
    app_uid=$(stat -f %u "$app")
    if [ "$app_uid" -ge 501 ] && [ "$app_uid" != "$primary_uid" ]; then printf 'foreign application owner: %s\n' "$app" >&2; status=1; fi
  done
  for item in rg nvim wt node bun pnpm uv opencode openspec bootdev pss claude codex; do
    command_path=$(command -v "$item" 2>/dev/null || true)
    [ -n "$command_path" ] || { printf 'command missing: %s\n' "$item" >&2; status=1; continue; }
    if [ ! -d /nix ]; then
      case "$(dotfiles_realpath "$command_path" 2>/dev/null || printf '%s' "$command_path")" in
        /nix/*|*/.nix-profile/*|*/.local/share/mise/*|/home/linuxbrew/*) printf 'forbidden command path: %s -> %s\n' "$item" "$command_path" >&2; status=1 ;;
      esac
    fi
  done
  opencode --version 2>/dev/null | grep -qE '(^| )v?2\.' || { printf 'OpenCode is not v2\n' >&2; status=1; }
  bat --list-themes 2>/dev/null | grep -q '^GitHub-Dark' || { printf 'bat theme cache is missing GitHub-Dark\n' >&2; status=1; }
  env -i HOME="$HOME" USER="$(id -un)" /bin/zsh -c 'command -v rg >/dev/null && command -v wt >/dev/null && command -v codex >/dev/null' >/dev/null 2>&1 || { printf 'clean zsh cannot resolve required tools\n' >&2; status=1; }
  env -i HOME="$HOME" USER="$(id -un)" /bin/bash -lc 'command -v rg >/dev/null && command -v wt >/dev/null && command -v codex >/dev/null' >/dev/null 2>&1 || { printf 'login bash cannot resolve required tools\n' >&2; status=1; }
  for item in KeyRemapping TMExcludeDev; do
    [ -f "$HOME/Library/LaunchAgents/com.local.$item.plist" ] || { printf 'launch agent missing: %s\n' "$item" >&2; status=1; }
    if launchctl print "gui/$(id -u)" >/dev/null 2>&1 && ! launchctl print "gui/$(id -u)/com.local.$item" >/dev/null 2>&1; then printf 'launch agent is not loaded: %s\n' "$item" >&2; status=1; fi
  done
  return "$status"
}
