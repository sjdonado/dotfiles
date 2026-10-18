#!/usr/bin/env bash
# The macOS host check: asserts this Mac after a switch (`macos.sh` or `nix run .#sync`). Read-only: it changes nothing, so it runs as often as needed.
#
#   verify/macos-host.sh
#
# It reads the declaration of this Mac's configuration (chosen by hostname, as the switch does) and checks the result: declared tools run, links resolve into this repository, the switch-applied settings hold, and non-interactive shells find the tools.
set -uo pipefail
DOTFILES="$HOME/.config/dotfiles"
CONFIG=".#darwinConfigurations.$(scutil --get LocalHostName).config"
PASS=0 FAIL=0
ok()    { printf '  ok   %s\n' "$1"; PASS=$((PASS+1)); }
bad()   { printf '  FAIL %s\n' "$1"; FAIL=$((FAIL+1)); }
group() { printf '\n== %s\n' "$1"; }
runs() {
  local cmd=$1 flag=${2:---version} out
  if ! command -v "$cmd" >/dev/null 2>&1; then bad "$cmd not on PATH"; return; fi
  if out=$("$cmd" $flag 2>&1 </dev/null) && [ -n "$out" ]; then ok "$cmd -> $(printf '%s' "$out" | head -1 | cut -c1-50)"; else bad "$cmd on PATH but '$cmd $flag' failed"; fi
}
linked() {
  local link=$1 target=$2
  if [ -L "$link" ] && [ "$(readlink -f "$link")" = "$(readlink -f "$target")" ]; then ok "${link#"$HOME"/} -> ${target#"$DOTFILES"/}"; else bad "${link#"$HOME"/} is not a link to ${target#"$DOTFILES"/}"; fi
}
declared() { (cd "$DOTFILES" && nix eval --raw "$CONFIG.$1" --apply 'xs: builtins.concatStringsSep "\n" (map (x: x.name or x) xs)'); }

group "Nix"
# Upstream Nix, not Determinate Nix: nix-darwin manages nix.conf on macOS, and both platforms install the same way.
if v=$(nix --version 2>&1) && ! grep -qi determinate <<<"$v"; then ok "upstream Nix: $v"; else bad "not upstream Nix: $v"; fi

group "declared tools (Nix)"
# This runs in a login bash, whose path_helper puts /usr/bin ahead of the Nix profiles; Apple's stubs there (java) would answer instead of the declared tool. The shells group below checks how each shell resolves tools.
PATH="/etc/profiles/per-user/$(id -un)/bin:/run/current-system/sw/bin:$PATH"
# supabase refuses to start when its Docker context does not answer (OrbStack not running); whether Docker runs is not what this check asks.
export DOCKER_CONTEXT=default
# Every declared package that names its program, read from the configuration rather than listed here. Tools spell the version flag differently, so each counts as running when one of the usual spellings answers.
# macOS has no `timeout`; the declared coreutils carry it as gtimeout. Without it a server that waits on stdin would hang the check.
limit=$(command -v gtimeout) || { bad "gtimeout (declared coreutils) is missing"; limit=""; }
answers() {
  local cmd=$1 flag out
  for flag in --version -version version -V -v --help; do
    if out=$(${limit:+$limit 20} "$cmd" $flag 2>&1 </dev/null) && [ -n "$out" ]; then printf '%s' "$out" | head -1 | cut -c1-50; return 0; fi
  done
  # The last flag's output, so a failure says what the tool answered.
  printf '%s' "$out" | head -1 | cut -c1-80
  return 1
}
# Packages that name no program (the wrappers, python, a few tools) are listed by command instead.
progs=$(cd "$DOTFILES" && nix eval --raw "$CONFIG.home-manager.users.$(id -un).home.packages" --apply 'ps: builtins.concatStringsSep "\n" (builtins.filter (x: x != "") (map (p: p.meta.mainProgram or "") ps))') || progs=""
[ -n "$progs" ] || bad "could not read the declared packages from the configuration"
for prog in $(printf '%s\n' "$progs" gsed gawk gtimeout telnet python3.12 duti pi | sort -u); do
  if ! command -v "$prog" >/dev/null 2>&1; then bad "$prog not on PATH"
  elif [ -z "$limit" ]; then bad "$prog not checked: no gtimeout"
  elif v=$(answers "$prog"); then ok "$prog -> $v"
  else bad "$prog on PATH but answers no version or help flag: $v"; fi
done
if opencode --version 2>/dev/null | grep -q 'v2\.'; then ok "OpenCode is v2"; else bad "OpenCode is not v2"; fi
case "$(command -v sed)" in /usr/bin/sed) ok "sed is still macOS sed (GNU sed only as gsed)" ;; *) bad "sed resolves to $(command -v sed)" ;; esac

group "Homebrew, driven by the switch"
brew_formulas=$(brew list --formula -1 2>/dev/null)
while read -r f; do
  [ -n "$f" ] || continue
  if grep -qx "${f##*/}" <<<"$brew_formulas"; then ok "formula $f"; else bad "formula $f not installed"; fi
done < <(declared homebrew.brews)
brew_casks=$(brew list --cask -1 2>/dev/null)
while read -r c; do
  [ -n "$c" ] || continue
  if grep -qx "${c##*/}" <<<"$brew_casks"; then ok "cask $c"; else bad "cask $c not installed"; fi
done < <(declared homebrew.casks)
if [ "$(brew tap | sort | paste -sd, -)" = "$(declared homebrew.taps | sed 's|/homebrew-|/|' | sort | paste -sd, -)" ]; then ok "the taps are exactly the pinned ones"; else bad "brew tap differs from the pinned taps: $(brew tap | paste -sd' ' -)"; fi

group "links into the repository"
linked "$HOME/.gitconfig"                     "$DOTFILES/git/.gitconfig"
linked "$HOME/.zshrc"                         "$DOTFILES/zsh/.zshrc"
linked "$HOME/.config/fish/config.fish"       "$DOTFILES/fish/config.fish"
# linked "$HOME/.config/nvim"                   "$DOTFILES/nvim"  # skipped with the full neovim setup
linked "$HOME/.config/ghostty/config"         "$DOTFILES/ghostty/config"
linked "$HOME/.config/browser-router/config.json" "$DOTFILES/macos/browser-router.json"
linked "$HOME/.docker/config.json"            "$DOTFILES/docker/config.json"
linked "$HOME/.ssh/config"                    "$DOTFILES/.ssh/config"
linked "$HOME/.claude/settings.json"          "$DOTFILES/claude/settings.json"
linked "$HOME/.claude/skills"                 "$DOTFILES/agents/skills"
linked "$HOME/.codex/AGENTS.md"               "$DOTFILES/agents/AGENTS.md"
linked "$HOME/.config/opencode/opencode.json" "$DOTFILES/opencode/opencode.json"
linked "$HOME/.pi/agent/settings.json"        "$DOTFILES/pi/settings.json"
for f in "$DOTFILES/bin/"*; do linked "$HOME/.local/bin/$(basename "$f")" "$f"; done

group "system settings"
if [ "$(dscl . -read "$HOME" UserShell | awk '{print $2}')" = /bin/zsh ]; then ok "login shell is /bin/zsh"; else bad "login shell is $(dscl . -read "$HOME" UserShell)"; fi
# Homebrew and the app bundles other accounts installed belong to the primary account (the first in this Mac's list in flake.nix), so they survive the removal of any other account.
config="$(scutil --get LocalHostName)"
primary="$(sed -n "s/.*\"$config\" = darwin \[ *\"\([^\"]*\)\".*/\1/p" "$DOTFILES/flake.nix")"
if [ -z "$primary" ]; then
  bad "flake.nix names no primary account for $config"
elif ! id -u "$primary" >/dev/null 2>&1; then
  bad "the primary account in flake.nix, $primary, does not exist on this Mac"
else
  stray="$(find /opt/homebrew ! -user "$primary" -print -quit 2>/dev/null)"
  if [ -z "$stray" ]; then ok "everything under /opt/homebrew belongs to the primary account"; else bad "$stray belongs to $(/usr/bin/stat -f %Su "$stray"), not the primary account"; fi
  primary_uid="$(id -u "$primary")"
  for app in /Applications/*.app; do
    [ -e "$app" ] || continue
    uid="$(/usr/bin/stat -f %u "$app")"
    if [ "$uid" -ge 501 ] && [ "$uid" != "$primary_uid" ]; then bad "$app belongs to $(/usr/bin/stat -f %Su "$app"), not the primary account"; fi
  done
fi
[ "$(defaults read NSGlobalDomain AppleShowAllExtensions 2>/dev/null)" = 1 ] && ok "Finder shows all extensions" || bad "AppleShowAllExtensions is not set"
[ "$(defaults read com.apple.finder AppleShowAllFiles 2>/dev/null)" = 1 ] && ok "Finder shows hidden files" || bad "AppleShowAllFiles is not set"
for agent in KeyRemapping TMExcludeDev; do
  if launchctl print "gui/$(id -u)/org.nix-community.home.$agent" >/dev/null 2>&1; then ok "launch agent $agent is loaded"; else bad "launch agent $agent is not loaded"; fi
done
if [ -d "$HOME/Library/Keyboard Layouts/ABC - Custom.bundle" ] && [ ! -L "$HOME/Library/Keyboard Layouts/ABC - Custom.bundle" ]; then ok "keyboard layout copied (not linked)"; else bad "keyboard layout missing"; fi
if [ -d "$HOME/Applications/BrowserRouter.app" ]; then ok "BrowserRouter copied to ~/Applications"; else bad "BrowserRouter.app missing from ~/Applications"; fi
# duti exits 0 but changes nothing on macOS 26, so default apps are chosen by hand for now (README.md, "Manual steps"); the result is reported, not asserted.
printf '  skip default apps are manual for now: Markdown opens in %s\n' "$(duti -x md 2>&1 | head -1)"
[ -f "$HOME/.hushlogin" ] && ok "~/.hushlogin exists" || bad "~/.hushlogin missing"

group "non-interactive shells resolve the tools"
for c in rg nvim claude codex; do
  # USER as launchd, sshd and terminals set it: nix-darwin's PATH names /etc/profiles/per-user/$USER/bin.
  if env -i HOME="$HOME" USER="$(id -un)" /bin/zsh -c "command -v $c" >/dev/null 2>&1; then ok "zsh -c finds $c"; else bad "zsh -c cannot find $c"; fi
  if env -i HOME="$HOME" USER="$(id -un)" /bin/bash -lc "command -v $c" >/dev/null 2>&1; then ok "login bash finds $c"; else bad "login bash cannot find $c"; fi
done
# A login, interactive zsh is what a new terminal gets (a herdr pane runs the same ~/.zshrc without the login part): ~/.zshrc must leave the Nix profiles ahead of Homebrew (nix-homebrew's brew shellenv runs before it) and set the environment fish used to.
zsh_env=$(env -i HOME="$HOME" USER="$(id -un)" TERM=xterm /bin/zsh -lic 'printf "%s|%s|%s|%s\n" "$(command -v rg)" "$EDITOR" "$(command -v brew)" "$PATH"' </dev/null 2>/dev/null | tail -1)
case "${zsh_env%%|*}" in /etc/profiles/per-user/*|/run/current-system/*|"$HOME"/.nix-profile/*) ok "zsh resolves rg from a Nix profile (${zsh_env%%|*})" ;; *) bad "zsh resolves rg to '${zsh_env%%|*}', not a Nix profile" ;; esac
[ "$(echo "$zsh_env" | cut -d'|' -f2)" = nvim ] && ok "zsh sets EDITOR=nvim" || bad "zsh does not set EDITOR=nvim"
[ -n "$(echo "$zsh_env" | cut -d'|' -f3)" ] && ok "zsh finds brew" || bad "zsh cannot find brew"
case ":$(echo "$zsh_env" | cut -d'|' -f4):" in *":$HOME/.local/bin:"*) ok "zsh has ~/.local/bin on PATH" ;; *) bad "zsh lacks ~/.local/bin on PATH" ;; esac

group "agents come from Nix"
# GUI apps look in ~/.local/bin with the PATH they launched with, so both the PATH lookup and that directory have to reach the Nix build, not a curl-installed copy.
for c in claude codex; do
  case "$(readlink -f "$(command -v "$c")")" in /nix/store/*) ok "$c on PATH is the Nix build" ;; *) bad "$c on PATH resolves to $(readlink -f "$(command -v "$c")")" ;; esac
  case "$(readlink -f "$HOME/.local/bin/$c")" in /nix/store/*) ok "~/.local/bin/$c is the Nix build" ;; *) bad "~/.local/bin/$c resolves to $(readlink -f "$HOME/.local/bin/$c" 2>&1)" ;; esac
done

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
