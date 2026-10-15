#!/usr/bin/env bash
# The full macOS check: a disposable macOS guest (tart on Virtualization.framework) runs macos.sh from this working tree, which installs Nix and switches the darwin configuration. It runs twice, the result is asserted after each run, and the guest is discarded. This has to pass before the first switch on a real Mac.
#
#   verify/macos-vm.sh
#
# Nothing on this Mac changes beyond two caches: tart itself (~/.cache/dotfiles-verify) and tart's images (~/.tart; the base image is ~25 GB on first use). It downloads every cask, so expect tens of minutes. Apple allows two running macOS guests per host.
#
# Transport is SSH, not `tart exec`: exec's agent channel fails silently (exit 125, no output) on this image while sshd answers. Auth is the base image's admin/admin convention. Throwaway guests only: host keys are never recorded.
#
# The guest uses darwinConfigurations.verify-vm (DARWIN_CONFIG, read by macos.sh): the same modules as this Mac's configuration, for the base image's admin user, without App Store apps, since the guest has no App Store account. The same script runs inside the guest to assert (VERIFY_STAGE=assert).
set -euo pipefail

# The assertions, run inside the guest after macos.sh.
assert_guest() {
  set +e
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
}

if [ "${VERIFY_STAGE:-}" = assert ]; then
  assert_guest
  exit
fi

[ "$(uname)" = "Darwin" ] || { echo "macOS host only" >&2; exit 2; }
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE="${TART_BASE:-ghcr.io/cirruslabs/macos-tahoe-base:latest}"
GUEST_USER="${GUEST_USER:-admin}"
GUEST_PASSWORD="${GUEST_PASSWORD:-admin}"
VM="dotfiles-verify-macos-$$"


# tart, the pinned release checked against its published sha256 and kept in a cache directory: nothing is installed on this Mac. Bump TART_VERSION and TART_SHA256 together.
TART_VERSION=2.41.0
TART_SHA256=07faafc77acc668fcfb2fbe97811622567fb89c650db401a470f72e7c4ddc560
TART_DIR="$HOME/.cache/dotfiles-verify/tart-$TART_VERSION"
if [ ! -x "$TART_DIR/tart.app/Contents/MacOS/tart" ]; then
  echo "==> downloading tart $TART_VERSION"
  mkdir -p "$TART_DIR"
  curl -fsSL -o "$TART_DIR/tart.tar.gz" "https://github.com/cirruslabs/tart/releases/download/$TART_VERSION/tart.tar.gz"
  echo "$TART_SHA256  $TART_DIR/tart.tar.gz" | shasum -a 256 -c - >/dev/null || { echo "tart download does not match its checksum" >&2; rm -rf "$TART_DIR"; exit 1; }
  tar -xzf "$TART_DIR/tart.tar.gz" -C "$TART_DIR"
fi
tart() { "$TART_DIR/tart.app/Contents/MacOS/tart" "$@"; }

# SSH_ASKPASS hands the base image's password to ssh with stdin closed: deterministic where an interactive prompt hangs.
ASKPASS="$(mktemp)"
printf '#!/bin/sh\nprintf "%%s\\n" "$GUEST_PASSWORD"\n' > "$ASKPASS"
chmod 700 "$ASKPASS"

cleanup() {
  tart stop "$VM" >/dev/null 2>&1 || true
  tart delete "$VM" >/dev/null 2>&1 || true
  [ -n "${LOGS:-}" ] && rm -rf "$LOGS"
  [ -n "${STAGE:-}" ] && rm -rf "$STAGE"
  rm -f "$ASKPASS"
}
trap cleanup EXIT INT TERM

# The remote command travels pre-quoted: ssh joins its argv into one remote shell line. Password via $ASKPASS with stdin closed.
guest() {
  # The quote goes through a variable: macOS's bash 3.2 mangles a backslash-escaped quote in the replacement.
  local sq="'"
  local qc="'${1//$sq/$sq\\$sq$sq}'"
  SSH_ASKPASS="$ASKPASS" SSH_ASKPASS_REQUIRE=force DISPLAY=:0 GUEST_PASSWORD="$GUEST_PASSWORD" \
    ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      "$GUEST_USER@$GUEST_IP" "bash -lc $qc" < "${GUEST_STDIN:-/dev/null}"
}

echo "==> cloning $BASE (pulls ~25 GB on first use, cached after)"
tart clone "$BASE" "$VM"

echo "==> staging a filtered copy (the guest must not see live secrets)"
# The share is the guest's only view of the tree, so it cannot be the live checkout: gitignored secrets (.env, .ssh/private.conf) would sit readable next to third-party installers. Only the files the git flake sees (git's index) are staged.
STAGE="$(mktemp -d)"
LOGS="$(mktemp -d)"
git -C "$ROOT" ls-files --cached | while IFS= read -r f; do if [ -e "$ROOT/$f" ] || [ -L "$ROOT/$f" ]; then printf '%s\n' "$f"; fi; done | rsync -a --files-from=- "$ROOT/" "$STAGE/"

echo "==> booting headless with the staged tree mounted"
tart run --no-graphics "$VM" --dir=repo:"$STAGE" > "$LOGS/tart.log" 2>&1 &
GUEST_IP="$(tart ip "$VM" --wait 300)"
[ -n "$GUEST_IP" ] || { echo "guest never got an IP; see $LOGS/tart.log" >&2; exit 1; }
for _ in $(seq 1 60); do
  guest true >/dev/null 2>&1 && break
  sleep 10
done
guest true || { echo "guest never answered over SSH" >&2; exit 1; }
echo "  guest: $(guest 'sw_vers -productName; sw_vers -productVersion' | paste -sd' ' -)"

echo "==> copying the tree to ~/.config/dotfiles (the configuration links there)"
# rsync, not cp -a or tar: macOS cp fails on xattrs through virtiofs and bsdtar stops at the share's .Trashes entry. An unnamed share appears at the root, a named one under its name, so probe for both.
guest 'SRC=""; for d in "/Volumes/My Shared Files/repo" "/Volumes/My Shared Files"; do [ -f "$d/flake.nix" ] && SRC="$d" && break; done; [ -n "$SRC" ] || { echo "no shared tree mounted" >&2; exit 1; }; mkdir -p ~/.config; rm -rf ~/.config/dotfiles; rsync -a --exclude .Trashes --exclude .DS_Store "$SRC/" ~/.config/dotfiles/; test -f ~/.config/dotfiles/flake.nix'

# macos.sh switches through sudo; the base image's admin needs its password once per session, so sudo is primed first. The password travels on the remote command's stdin, never on its command line.
switch() {
  printf '%s\n' "$GUEST_PASSWORD" | GUEST_STDIN=/dev/stdin guest 'sudo -S -v 2>/dev/null; cd ~/.config/dotfiles && DARWIN_CONFIG=verify-vm ./macos.sh' > "$LOGS/$1.log" 2>&1 \
    || { echo "$1 failed:"; tail -40 "$LOGS/$1.log"; exit 1; }
  grep -E '^==>|dotfiles:' "$LOGS/$1.log" | sed 's/^/  /' || true
}

echo "==> first run: macos.sh"
switch run1
echo "==> verifying"
guest 'VERIFY_STAGE=assert bash ~/.config/dotfiles/verify/macos-vm.sh'
# No herdr server runs in the guest, so the plugin step has to report itself skipped rather than pass silently.
if grep -q 'dotfiles: skipped herdr-plugins' "$LOGS/run1.log"; then echo "  ok   the herdr plugin step reported itself skipped"; else echo "  FAIL the herdr plugin step did not report its skip"; exit 1; fi

before="$(guest 'readlink -f /nix/var/nix/profiles/system; find ~ -maxdepth 4 -name "*.pre-nix" 2>/dev/null | sort')"
[ -n "$(head -1 <<<"$before")" ] || { echo "  FAIL no nix-darwin system after the first run"; exit 1; }
echo "==> second run: macos.sh again (idempotency)"
switch run2
echo "==> verifying again"
guest 'VERIFY_STAGE=assert bash ~/.config/dotfiles/verify/macos-vm.sh'
after="$(guest 'readlink -f /nix/var/nix/profiles/system; find ~ -maxdepth 4 -name "*.pre-nix" 2>/dev/null | sort')"
if [ "$before" = "$after" ]; then
  echo "  ok   the second run kept the same system and left no new backups"
else
  echo "  FAIL the second run changed the system or left backups:"
  diff <(printf '%s\n' "$before") <(printf '%s\n' "$after") | sed 's/^/  /'
  exit 1
fi
if grep -q 'Installing Nix' "$LOGS/run2.log"; then echo "  FAIL the second run installed Nix again"; exit 1; fi

echo
echo "==> rehearsal passed (guest discarded on exit)"
