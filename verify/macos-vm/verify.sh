#!/usr/bin/env bash
# Assertions inside the macOS guest after macos.sh switched it (verify/macos-vm/run.sh runs this twice). Prints every result, then exits non-zero if any failed.
set -uo pipefail

DOTFILES="$HOME/.config/dotfiles"
CONFIG=".#darwinConfigurations.verify-vm.config"
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
# Every declared package that names its program, read from the configuration rather than listed here. Tools spell the version flag differently, so each counts as running when one of the usual spellings answers.
# macOS has no `timeout`; the declared coreutils carry it as gtimeout. Without it a server that waits on stdin would hang the check.
limit=$(command -v gtimeout) || { bad "gtimeout (declared coreutils) is missing"; limit=""; }
answers() {
  local cmd=$1 flag out
  for flag in --version -version version -V --help; do
    if out=$(${limit:+$limit 20} "$cmd" $flag 2>&1 </dev/null) && [ -n "$out" ]; then printf '%s' "$out" | head -1 | cut -c1-50; return 0; fi
  done
  return 1
}
# Packages that name no program (the wrappers, python, a few tools) are listed by command instead.
progs=$(cd "$DOTFILES" && nix eval --raw "$CONFIG.home-manager.users.$(id -un).home.packages" --apply 'ps: builtins.concatStringsSep "\n" (builtins.filter (x: x != "") (map (p: p.meta.mainProgram or "") ps))') || progs=""
[ -n "$progs" ] || bad "could not read the declared packages from the configuration"
for prog in $(printf '%s\n' "$progs" gsed gawk gtimeout telnet python3.12 duti pi | sort -u); do
  if ! command -v "$prog" >/dev/null 2>&1; then bad "$prog not on PATH"
  elif [ -z "$limit" ]; then bad "$prog not checked: no gtimeout"
  elif v=$(answers "$prog"); then ok "$prog -> $v"
  else bad "$prog on PATH but answers no version or help flag"; fi
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
linked "$HOME/.config/fish/config.fish"       "$DOTFILES/fish/config.fish"
linked "$HOME/.config/nvim"                   "$DOTFILES/nvim"
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
fish=/run/current-system/sw/bin/fish
if [ "$(dscl . -read "$HOME" UserShell | awk '{print $2}')" = "$fish" ]; then ok "login shell is $fish"; else bad "login shell is $(dscl . -read "$HOME" UserShell)"; fi
if grep -qx "$fish" /etc/shells; then ok "$fish is in /etc/shells"; else bad "$fish is not in /etc/shells"; fi
[ "$(defaults read NSGlobalDomain AppleShowAllExtensions 2>/dev/null)" = 1 ] && ok "Finder shows all extensions" || bad "AppleShowAllExtensions is not set"
[ "$(defaults read com.apple.finder AppleShowAllFiles 2>/dev/null)" = 1 ] && ok "Finder shows hidden files" || bad "AppleShowAllFiles is not set"
for agent in KeyRemapping TMExcludeDev; do
  if launchctl print "gui/$(id -u)/org.nix-community.home.$agent" >/dev/null 2>&1; then ok "launch agent $agent is loaded"; else bad "launch agent $agent is not loaded"; fi
done
if [ -d "$HOME/Library/Keyboard Layouts/ABC - Custom.bundle" ] && [ ! -L "$HOME/Library/Keyboard Layouts/ABC - Custom.bundle" ]; then ok "keyboard layout copied (not linked)"; else bad "keyboard layout missing"; fi
if [ -d "$HOME/Applications/BrowserRouter.app" ]; then ok "BrowserRouter copied to ~/Applications"; else bad "BrowserRouter.app missing from ~/Applications"; fi
if duti -x md 2>/dev/null | grep -qi zed; then ok "Markdown opens in Zed"; else bad "Markdown does not open in Zed ($(duti -x md 2>&1 | head -1))"; fi
[ -f "$HOME/.hushlogin" ] && ok "~/.hushlogin exists" || bad "~/.hushlogin missing"

group "non-interactive shells resolve the tools"
for c in rg nvim claude codex; do
  if env -i HOME="$HOME" /bin/zsh -c "command -v $c" >/dev/null 2>&1; then ok "zsh -c finds $c"; else bad "zsh -c cannot find $c"; fi
  if env -i HOME="$HOME" /bin/bash -lc "command -v $c" >/dev/null 2>&1; then ok "login bash finds $c"; else bad "login bash cannot find $c"; fi
done
if "$fish" -c 'type -q rg; and type -q nvim' 2>/dev/null; then ok "fish finds rg and nvim"; else bad "fish cannot find rg or nvim"; fi

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
