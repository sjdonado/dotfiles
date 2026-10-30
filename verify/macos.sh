#!/usr/bin/env bash
# Non-mutating macOS preflight. All fixture writes stay under a temporary HOME.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
PASS=0 FAIL=0 UNVERIFIED=0
ok() { printf '  ok   %s\n' "$1"; PASS=$((PASS + 1)); }
bad() { printf '  FAIL %s\n' "$1" >&2; FAIL=$((FAIL + 1)); }
skip() { printf '  skip %s\n' "$1"; UNVERIFIED=$((UNVERIFIED + 1)); }

printf '== shell syntax\n'
for file in "$ROOT/setup.sh" "$ROOT/sync.sh" "$ROOT"/lib/*.sh "$ROOT"/hosts/*.sh "$ROOT"/macos/*.sh; do
  if bash -n "$file"; then ok "${file#"$ROOT/"}"; else bad "${file#"$ROOT/"}"; fi
done

printf '\n== declarations\n'
if awk -F'"' '/^(tap|brew|cask) / { key=$1 FS $2; if (seen[key]++) exit 1 }' "$ROOT/Brewfile"; then ok 'Brewfile has no duplicate declarations'; else bad 'Brewfile has duplicate declarations'; fi
if HOMEBREW_NO_AUTO_UPDATE=1 brew bundle list --all --file "$ROOT/Brewfile" >/dev/null; then ok 'Homebrew parses every declaration'; else bad 'Homebrew cannot parse Brewfile'; fi
if awk 'NF && $1 !~ /^#/ { if (seen[$1]++) exit 1 }' "$ROOT/packages/linux-apt.txt"; then ok 'Linux apt list has no duplicates'; else bad 'Linux apt list has duplicates'; fi

. "$ROOT/lib/core.sh"
. "$ROOT/hosts/macos.sh"
. "$ROOT/lib/links.sh"
. "$ROOT/lib/installers.sh"
. "$ROOT/lib/macos.sh"
. "$ROOT/lib/linux.sh"
. "$ROOT/lib/migration.sh"

printf '\n== host and account guard\n'
fixture_host=$(macos_hosts | sed -n '1p')
fixture_primary=$(macos_primary_for_host "$fixture_host")
fixture_secondary=$(macos_accounts_for_host "$fixture_host" | sed -n '2p')
if [ -n "$fixture_primary" ] && [ -n "$fixture_secondary" ] && [ "$(macos_accounts_for_host "$fixture_host" | wc -l | tr -d ' ')" -ge 2 ]; then ok 'known host returns primary and account list'; else bad 'known host parsing'; fi
if macos_accounts_for_host unknown >/dev/null 2>&1; then bad 'unknown host was accepted'; else ok 'unknown host is rejected'; fi
if DOTFILES_HOST="$fixture_host" DOTFILES_CURRENT_USER="$fixture_secondary" require_macos_primary >/dev/null 2>&1; then bad 'secondary account passed mutation guard'; else ok 'secondary account cannot mutate'; fi
if DOTFILES_HOST="$fixture_host" DOTFILES_CURRENT_USER="$fixture_primary" require_macos_primary >/dev/null 2>&1; then ok 'primary account passes mutation guard'; else bad 'primary account rejected'; fi
if HOME="${TMPDIR:-/tmp}" DOTFILES="$ROOT" DOTFILES_HOST="$fixture_host" SUDO_USER="$fixture_secondary" "$ROOT/sync.sh" --user-only >/dev/null 2>&1; then bad 'secondary account reached internal user apply'; else ok 'secondary account cannot invoke internal user apply'; fi
if "$ROOT/setup.sh" --linux >/dev/null 2>&1; then bad 'mismatched setup platform was accepted'; else ok 'mismatched setup platform stops before mutation'; fi

printf '\n== fixtures\n'
TEMP_HOME=$(mktemp -d)
trap 'rm -rf "$TEMP_HOME"' EXIT
HOME=$TEMP_HOME DOTFILES=$ROOT DOTFILES_PREFLIGHT=1
export HOME DOTFILES DOTFILES_PREFLIGHT
mkdir -p "$HOME/.config"
printf 'keep me\n' > "$HOME/.gitconfig"
apply_common_links
apply_macos_links
first=$(find "$HOME" -type l | sort | while read -r link; do printf '%s=%s\n' "${link#"$HOME/"}" "$(readlink "$link")"; done)
apply_common_links
apply_macos_links
second=$(find "$HOME" -type l | sort | while read -r link; do printf '%s=%s\n' "${link#"$HOME/"}" "$(readlink "$link")"; done)
if [ "$first" = "$second" ]; then ok 'second link application changes no targets'; else bad 'link application is not idempotent'; fi
if [ "$(cat "$HOME/.gitconfig.pre-shell")" = 'keep me' ]; then ok 'unmanaged destination gets one backup'; else bad 'link backup missing'; fi
if check_link_registry "$(common_link_registry)" && check_link_registry "$(macos_link_registry)"; then ok 'all links resolve into this checkout'; else bad 'declared link check'; fi
if apply_generated_user_state && [ -f "$HOME/.codex/config.toml" ]; then ok 'generated user state is present'; else bad 'generated user state'; fi

trace="$TEMP_HOME/installers"
DOTFILES_INSTALL_TRACE=$trace
export DOTFILES_INSTALL_TRACE
install_vendor_agent_clis
if [ "$(sort "$trace" | paste -sd, -)" = claude,codex ]; then ok 'missing vendor CLIs select only their installers'; else bad 'vendor installer selection'; fi
mkdir -p "$HOME/.local/share/claude/bin" "$HOME/.codex/packages/standalone/bin"
touch "$HOME/.local/share/claude/bin/claude" "$HOME/.codex/packages/standalone/bin/codex"
ln -sfn "$HOME/.local/share/claude/bin/claude" "$HOME/.local/bin/claude"
ln -sfn "$HOME/.codex/packages/standalone/bin/codex" "$HOME/.local/bin/codex"
: > "$trace"
install_vendor_agent_clis
if [ ! -s "$trace" ]; then ok 'existing vendor CLIs are retained'; else bad 'existing vendor CLIs selected reinstall'; fi

apply_macos_launch_agents
for plist in "$HOME/Library/LaunchAgents/com.local.KeyRemapping.plist" "$HOME/Library/LaunchAgents/com.local.TMExcludeDev.plist"; do
  if plutil -lint "$plist" >/dev/null && ! grep -q '__.*__' "$plist"; then ok "$(basename "$plist")"; else bad "$(basename "$plist")"; fi
done
skip 'launch agents were rendered but not loaded'

printf '\n== Homebrew behavior\n'
fake_brew="$TEMP_HOME/brew"
brew_trace="$TEMP_HOME/brew-trace"
# shellcheck disable=SC2016
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "$BREW_TRACE"\n' > "$fake_brew"
chmod +x "$fake_brew"
DOTFILES_BREW=$fake_brew BREW_TRACE=$brew_trace
export DOTFILES_BREW BREW_TRACE
apply_homebrew apply
DOTFILES_BREW=$fake_brew BREW_TRACE=$brew_trace DOTFILES_BREW_CLEANUP=1 apply_homebrew upgrade
if grep -q '^bundle install --no-upgrade' "$brew_trace" && grep -q '^update$' "$brew_trace" && grep -q '^upgrade$' "$brew_trace" && grep -q '^bundle cleanup --force' "$brew_trace" && ! grep -q -- '--zap' "$brew_trace"; then ok 'apply, upgrade, and non-zapping cleanup order'; else bad 'Homebrew command trace'; fi
unset DOTFILES_BREW BREW_TRACE

fixture="$TEMP_HOME/homebrew-fixture" source_checkout="$TEMP_HOME/homebrew-source" backup="$TEMP_HOME/homebrew-backup"
mkdir -p "$fixture/bin" "$fixture/Library" "$fixture/Cellar/kept/1.0" "$fixture/Caskroom/kept/1.0" "$source_checkout/bin" "$source_checkout/Library/Homebrew" "$source_checkout/.git"
printf '#!/bin/sh\nexit 0\n' > "$source_checkout/bin/brew"
chmod +x "$source_checkout/bin/brew"
ln -s /nix/store/fake-brew/bin/brew "$fixture/bin/brew"
ln -s /nix/store/fake-brew/Library/Homebrew "$fixture/Library/Homebrew"
ln -s /nix/store/fake-taps "$fixture/Library/Taps"
touch "$fixture/Cellar/kept/1.0/sentinel" "$fixture/Caskroom/kept/1.0/sentinel"
if detach_homebrew_files "$fixture" "$source_checkout" "$backup" && [ -f "$fixture/Cellar/kept/1.0/sentinel" ] && [ -f "$fixture/Caskroom/kept/1.0/sentinel" ]; then ok 'Homebrew detachment preserves Cellar and Caskroom'; else bad 'Homebrew detachment fixture'; fi

printf '\n== migration gates\n'
migration_trace="$TEMP_HOME/migration-trace"
(
  require_macos_primary() { return 0; }
  migration_commit() { printf 'fixture\n'; }
  remove_retired_macos_software() { return 0; }
  apply_macos_machine() { return 0; }
  check_all_macos_accounts() { return 1; }
  detach_homebrew_from_nix() { printf 'detached\n' >> "$migration_trace"; }
  run_nix_migration_until_uninstall_gate
) >/dev/null 2>&1 || true
if [ ! -e "$migration_trace" ]; then ok 'failed account check makes detachment unreachable'; else bad 'migration continued after failed check'; fi
if uninstall_nix_after_migration_gate >/dev/null 2>&1; then bad 'uninstall passed without recorded evidence'; else ok 'Nix uninstall requires evidence from the same tree'; fi

printf '\n== Linux shell fixture\n'
linux_home="$TEMP_HOME/linux-home"
mkdir -p "$linux_home"
ln -s /nix/store/old-profile "$linux_home/.profile"
HOME=$linux_home
export HOME
apply_common_links
apply_linux_shells
linux_first=$(shasum "$HOME/.profile" "$HOME/.zshenv" "$HOME/.bashrc" "$HOME/.zshrc")
apply_linux_shells
linux_second=$(shasum "$HOME/.profile" "$HOME/.zshenv" "$HOME/.bashrc" "$HOME/.zshrc")
if [ "$linux_first" = "$linux_second" ]; then ok 'Linux shell blocks are idempotent'; else bad 'Linux shell blocks changed twice'; fi
if [ -L "$HOME/.profile.pre-shell" ] && [ ! -L "$HOME/.profile" ]; then ok 'Nix-managed shell file is replaced with a backup'; else bad 'Nix-managed shell replacement'; fi
for file in "$HOME/.profile" "$HOME/.zshenv" "$HOME/.bashrc" "$HOME/.zshrc"; do
  if grep -qE '(/nix|\.nix-profile|mise|linuxbrew)' "$file"; then bad "forbidden Linux path in $file"; fi
done

printf '\n%s passed, %s failed, %s unverified\n' "$PASS" "$FAIL" "$UNVERIFIED"
[ "$FAIL" -eq 0 ]
