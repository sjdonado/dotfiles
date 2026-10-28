#!/usr/bin/env bash
# Apply this repository's declaration to this machine, then check the result. The platform comes from uname; the switch itself is `nix run .#sync` (nix/apps.nix), so this adds the checks after it.
#
#   ~/.config/dotfiles/sync.sh             # switch, then check
#   ~/.config/dotfiles/sync.sh --upgrade   # move every pin in flake.lock, switch, then check
#   ~/.config/dotfiles/sync.sh --check     # check only: read-only, runs as often as needed
#
# The checks assert what a switch should have left: declared tools answer their version command, links resolve into this repository (a copy with the same contents fails), the switch-applied settings hold, and non-interactive shells find the tools. The exit status says whether the switch and every check passed.
#
# On macOS one switch serves every account in this Mac's list in flake.nix, and only the first, the primary account, may run it. From the primary account this switches and then checks every listed account, each in a clean login shell of its own through sudo, using the sync.sh of that account's clone. From any other account it skips the switch and checks that account only.
#
# Setting up a new machine, or repairing a broken Nix, is setup.sh.
set -uo pipefail

mode=sync
case "${1:-}" in
  "") ;;
  --check) mode=check ;;
  --upgrade) mode=upgrade ;;
  -h|--help) sed -n '4,6p' "$0" | sed 's/^#   //'; exit 0 ;;
  *) echo "unknown argument: $1 (use --check or --upgrade, or nothing)" >&2; exit 2 ;;
esac
[ "$#" -le 1 ] || { echo "sync.sh takes one argument at most" >&2; exit 2; }

# Fixed: the configuration links into this path (nix/home/common.nix).
DOTFILES="$HOME/.config/dotfiles"
# A shell that has not loaded Nix yet (a first login after setup.sh) still finds it.
command -v nix >/dev/null 2>&1 || . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 2>/dev/null || true

PASS=0 FAIL=0
ok()    { printf '  ok   %s\n' "$1"; PASS=$((PASS+1)); }
bad()   { printf '  FAIL %s\n' "$1"; FAIL=$((FAIL+1)); }
group() { printf '\n== %s\n' "$1"; }
# A tool counts as installed only if it runs: a wrapper whose setup never happened is on PATH and still broken. Some tools spell the version flag differently, hence the optional second argument.
runs() {
  local cmd=$1 flag=${2:---version} out
  if ! command -v "$cmd" >/dev/null 2>&1; then bad "$cmd not on PATH"; return; fi
  if out=$("$cmd" $flag 2>&1 </dev/null) && [ -n "$out" ]; then
    ok "$cmd -> $(printf '%s' "$out" | head -1 | cut -c1-50)"
  else
    bad "$cmd on PATH but '$cmd $flag' failed: $(printf '%s' "$out" | head -1 | cut -c1-60)"
  fi
}
# The link has to resolve to the file in the working tree: a copy with the same contents fails.
linked() {
  local link=$1 target=$2
  if [ -L "$link" ] && [ "$(readlink -f "$link")" = "$(readlink -f "$target")" ]; then
    ok "${link#"$HOME"/} -> ${target#"$DOTFILES"/}"
  else
    bad "${link#"$HOME"/} is not a link to ${target#"$DOTFILES"/} (readlink -f: $(readlink -f "$link" 2>/dev/null || echo none))"
  fi
}
switch() {
  printf '==> nix run .#%s\n' "$1"
  nix run "$DOTFILES#$1" || { echo "The switch failed; nothing was checked. See the output above." >&2; exit 1; }
}

check_macos() {
  CONFIG=".#darwinConfigurations.$(/usr/sbin/scutil --get LocalHostName).config"
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
  # Read first, so a configuration that fails to evaluate is a failure rather than zero checks.
  { brews=$(declared homebrew.brews) && [ -n "$brews" ]; } || bad "could not read homebrew.brews from the configuration"
  { casks=$(declared homebrew.casks) && [ -n "$casks" ]; } || bad "could not read homebrew.casks from the configuration"
  brew_formulas=$(brew list --formula -1 2>/dev/null)
  while read -r f; do
    [ -n "$f" ] || continue
    if grep -qx "${f##*/}" <<<"$brew_formulas"; then ok "formula $f"; else bad "formula $f not installed"; fi
  done <<<"$brews"
  brew_casks=$(brew list --cask -1 2>/dev/null)
  while read -r c; do
    [ -n "$c" ] || continue
    if grep -qx "${c##*/}" <<<"$brew_casks"; then ok "cask $c"; else bad "cask $c not installed"; fi
  done <<<"$casks"
  if [ "$(brew tap | sort | paste -sd, -)" = "$(declared homebrew.taps | sed 's|/homebrew-|/|' | sort | paste -sd, -)" ]; then ok "the taps are exactly the pinned ones"; else bad "brew tap differs from the pinned taps: $(brew tap | paste -sd' ' -)"; fi

  group "git credentials"
  # Nix's git sets osxkeychain in its system gitconfig; git/.gitconfig must not add a plaintext helper (store) on top. GitHub goes through gh, set per URL there.
  helpers=$(git config --get-all credential.helper | paste -sd' ' -)
  if [ "$helpers" = osxkeychain ]; then ok "git stores credentials in the Keychain"; else bad "git credential helpers are '$helpers', not osxkeychain alone"; fi

  group "links into the repository"
  linked "$HOME/.gitconfig"                     "$DOTFILES/git/.gitconfig"
  linked "$HOME/.zshrc"                         "$DOTFILES/zsh/.zshrc"
  # linked "$HOME/.config/nvim"                   "$DOTFILES/nvim"  # skipped with the full neovim setup
  linked "$HOME/.config/browser-router/config.json" "$DOTFILES/macos/browser-router.json"
  linked "$HOME/Library/Application Support/com.pais.handy/settings_store.json" "$DOTFILES/macos/handy/settings_store.json"
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
  if grep -qx /bin/zsh /etc/shells 2>/dev/null; then ok "/etc/shells lists /bin/zsh"; else bad "/etc/shells is missing or does not list /bin/zsh"; fi
  # Homebrew and the app bundles other accounts installed belong to the primary account (the first in this Mac's list in flake.nix), so they survive the removal of any other account.
  # $primary is read from flake.nix below, before any check runs.
  if ! id -u "$primary" >/dev/null 2>&1; then
    bad "the primary account in flake.nix, $primary, does not exist on this Mac"
  else
    # Root-owned entries are nix-homebrew's own (its brew launcher); anything else belongs to the primary account.
    stray="$(find /opt/homebrew ! -user "$primary" ! -user root -print -quit 2>/dev/null)"
    if [ -z "$stray" ]; then ok "nothing under /opt/homebrew belongs to another account"; else bad "$stray belongs to $(/usr/bin/stat -f %Su "$stray"), not the primary account"; fi
    primary_uid="$(id -u "$primary")"
    for app in /Applications/*.app; do
      [ -e "$app" ] || continue
      uid="$(/usr/bin/stat -f %u "$app")"
      if [ "$uid" -ge 501 ] && [ "$uid" != "$primary_uid" ]; then bad "$app belongs to $(/usr/bin/stat -f %Su "$app"), not the primary account"; fi
    done
  fi
  [ "$(defaults read NSGlobalDomain AppleShowAllExtensions 2>/dev/null)" = 1 ] && ok "Finder shows all extensions" || bad "AppleShowAllExtensions is not set"
  [ "$(defaults read com.apple.finder AppleShowAllFiles 2>/dev/null)" = 1 ] && ok "Finder shows hidden files" || bad "AppleShowAllFiles is not set"
  # Launch agents live in the account's GUI session, which an account that is not logged in does not have.
  if ! launchctl print "gui/$(id -u)" >/dev/null 2>&1; then
    printf '  skip launch agents: %s has no GUI session (not logged in)\n' "$(id -un)"
  else
    for agent in KeyRemapping TMExcludeDev; do
      if launchctl print "gui/$(id -u)/org.nix-community.home.$agent" >/dev/null 2>&1; then ok "launch agent $agent is loaded"; else bad "launch agent $agent is not loaded"; fi
    done
  fi
  if [ -d "$HOME/Library/Keyboard Layouts/ABC - Custom.bundle" ] && [ ! -L "$HOME/Library/Keyboard Layouts/ABC - Custom.bundle" ]; then ok "keyboard layout copied (not linked)"; else bad "keyboard layout missing"; fi
  if [ -d "$HOME/Applications/BrowserRouter.app" ]; then ok "BrowserRouter copied to ~/Applications"; else bad "BrowserRouter.app missing from ~/Applications"; fi
  # duti exits 0 but changes nothing on macOS 26, so default apps are chosen by hand for now (README.md, "Manual steps"); the result is reported, not asserted.
  printf '  skip default apps are manual for now: Markdown opens in %s\n' "$(duti -x md 2>&1 | head -1)"
  [ -f "$HOME/.hushlogin" ] && ok "~/.hushlogin exists" || bad "~/.hushlogin missing"

  group "non-interactive shells resolve the tools"
  for c in rg nvim mise claude codex; do
    # USER as launchd, sshd and terminals set it: nix-darwin's PATH names /etc/profiles/per-user/$USER/bin.
    if env -i HOME="$HOME" USER="$(id -un)" /bin/zsh -c "command -v $c" >/dev/null 2>&1; then ok "zsh -c finds $c"; else bad "zsh -c cannot find $c"; fi
    if env -i HOME="$HOME" USER="$(id -un)" /bin/bash -lc "command -v $c" >/dev/null 2>&1; then ok "login bash finds $c"; else bad "login bash cannot find $c"; fi
  done
  # A login, interactive zsh is what a new terminal gets (an editor's terminal runs the same ~/.zshrc without the login part): ~/.zshrc must leave the Nix profiles ahead of Homebrew (nix-homebrew's brew shellenv runs before it) and set the interactive environment.
  zsh_env=$(env -i HOME="$HOME" USER="$(id -un)" TERM=xterm /bin/zsh -lic 'printf "%s|%s|%s|%s\n" "$(command -v rg)" "$EDITOR" "$(command -v brew)" "$PATH"' </dev/null 2>/dev/null | tail -1)
  case "${zsh_env%%|*}" in /etc/profiles/per-user/*|/run/current-system/*|"$HOME"/.nix-profile/*) ok "zsh resolves rg from a Nix profile (${zsh_env%%|*})" ;; *) bad "zsh resolves rg to '${zsh_env%%|*}', not a Nix profile" ;; esac
  [ "$(echo "$zsh_env" | cut -d'|' -f2)" = nvim ] && ok "zsh sets EDITOR=nvim" || bad "zsh does not set EDITOR=nvim"
  [ -n "$(echo "$zsh_env" | cut -d'|' -f3)" ] && ok "zsh finds brew" || bad "zsh cannot find brew"
  case ":$(echo "$zsh_env" | cut -d'|' -f4):" in *":$HOME/.local/bin:"*) ok "zsh has ~/.local/bin on PATH" ;; *) bad "zsh lacks ~/.local/bin on PATH" ;; esac

  check_agents
}

check_agents() {
  group "agents update themselves"
  # T3 Code's update button runs `claude update` or `codex update`, which work only on the vendors' own installs; GUI apps look in ~/.local/bin, so the PATH lookup and that directory both have to reach them.
  for c in claude:"$HOME/.local/share/claude/" codex:"$HOME/.codex/packages/standalone/"; do
    name=${c%%:*} home=${c#*:}
    case "$(readlink -f "$(command -v "$name")")" in "$home"*) ok "$name on PATH is its own install" ;; *) bad "$name on PATH resolves to $(readlink -f "$(command -v "$name")"), not under $home" ;; esac
    case "$(readlink -f "$HOME/.local/bin/$name")" in "$home"*) ok "~/.local/bin/$name is its own install" ;; *) bad "~/.local/bin/$name resolves to $(readlink -f "$HOME/.local/bin/$name" 2>&1), not under $home" ;; esac
    if v=$("$HOME/.local/bin/$name" --version 2>&1 </dev/null); then ok "$name runs: $(printf '%s' "$v" | head -1 | cut -c1-50)"; else bad "$name does not run: $(printf '%s' "$v" | head -1 | cut -c1-80)"; fi
    # Linux: processes that never read the shell files find the same install through /usr/local/bin (nix/home/linux.nix).
    if [ "$(uname)" = Linux ]; then
      if [ -w /usr/local/bin ] || sudo -n true 2>/dev/null; then
        case "$(readlink -f "/usr/local/bin/$name")" in "$home"*) ok "/usr/local/bin/$name is its own install" ;; *) bad "/usr/local/bin/$name resolves to $(readlink -f "/usr/local/bin/$name" 2>&1), not under $home" ;; esac
      else
        printf '  skip /usr/local/bin/%s: not writable and sudo needs a password\n' "$name"
      fi
    fi
  done
}

check_linux() {
  group "Nix"
  # Upstream Nix, not Determinate Nix: nix-darwin manages nix.conf on macOS, and both platforms install the same way.
  if v=$(nix --version 2>&1) && ! grep -qi determinate <<<"$v"; then ok "upstream Nix: $v"; else bad "not upstream Nix: $v"; fi

  group "declared tools"
  for c in git zsh mosh python3 pip wget rg fd bat fzf jq nvim wt node bun pnpm uv mise opencode openspec; do runs "$c"; done
  if opencode --version 2>/dev/null | grep -q 'v2\.'; then ok "OpenCode is v2"; else bad "OpenCode is not v2 ($(opencode --version 2>&1 | head -1))"; fi

  # Skipped with the full neovim setup (nix/home/common.nix).
  # group "language servers and formatters (from Nix, not Mason)"
  # for c in astro-ls basedpyright clangd crystalline lua-language-server vtsls yaml-language-server black gofumpt isort prettierd ruff stylua; do runs "$c"; done
  # runs gopls version
  # # These servers have no version flag; each has to answer an LSP initialize request with its capabilities. They run in parallel, since each needs a few seconds to answer.
  # initialize='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"processId":null,"rootUri":null,"capabilities":{}}}'
  # # Captured before matching: under pipefail, the server's exit status after stdin closes would override grep's.
  # answers() {
  #   local out
  #   out=$({ printf 'Content-Length: %d\r\n\r\n%s' "${#initialize}" "$initialize"; sleep 5; } | timeout 15 "$1" --stdio 2>/dev/null)
  #   grep -q '"capabilities"' <<<"$out"
  # }
  # lsp_dir=$(mktemp -d)
  # for c in vscode-css-language-server vscode-eslint-language-server vscode-json-language-server svelteserver tailwindcss-language-server; do
  #   { if answers "$c"; then echo "ok"; else echo "fail"; fi > "$lsp_dir/$c"; } &
  # done
  # wait
  # for f in "$lsp_dir"/*; do
  #   c=$(basename "$f")
  #   if [ "$(cat "$f")" = ok ]; then ok "$c answers an LSP initialize request"; else bad "$c does not answer an LSP initialize request"; fi
  # done
  # rm -rf "$lsp_dir"
  # for c in golangci-lint-langserver goimports; do
  #   if command -v "$c" >/dev/null 2>&1; then ok "$c on PATH (has no version flag)"; else bad "$c not on PATH"; fi
  # done
  if nvim --headless -c 'if v:errmsg != "" | cquit 1 | endif' -c 'qa' >/dev/null 2>&1; then ok "nvim starts headless without errors"; else bad "nvim reports errors on a headless start"; fi

  group "linked config"
  linked "$HOME/.gitconfig"                       "$DOTFILES/git/.gitconfig"
  for f in "$DOTFILES/bat/themes/"*; do linked "$HOME/.config/bat/themes/$(basename "$f")" "$f"; done
  for f in "$DOTFILES/bin/"*; do linked "$HOME/.local/bin/$(basename "$f")" "$f"; done
  # linked "$HOME/.config/nvim"                     "$DOTFILES/nvim"  # skipped with the full neovim setup
  linked "$HOME/.config/worktrunk/config.toml"    "$DOTFILES/worktrunk/config.toml"
  linked "$HOME/.config/zed/settings.json"        "$DOTFILES/zed/settings.json"
  linked "$HOME/.config/zed/keymap.json"          "$DOTFILES/zed/keymap.json"
  linked "$HOME/.claude/settings.json"            "$DOTFILES/claude/settings.json"
  linked "$HOME/.claude/skills"                   "$DOTFILES/agents/skills"
  linked "$HOME/.claude/CLAUDE.md"                "$DOTFILES/agents/AGENTS.md"
  linked "$HOME/.agents/skills"                   "$DOTFILES/agents/skills"
  linked "$HOME/.codex/AGENTS.md"                 "$DOTFILES/agents/AGENTS.md"
  linked "$HOME/.config/opencode/opencode.json"   "$DOTFILES/opencode/opencode.json"
  linked "$HOME/.config/opencode/cli.json"        "$DOTFILES/opencode/cli.json"
  linked "$HOME/.config/opencode/AGENTS.md"       "$DOTFILES/opencode/AGENTS.md"
  linked "$HOME/.config/opencode/plugins/no-foreground-wait.ts" "$DOTFILES/opencode/plugins/no-foreground-wait.ts"
  linked "$HOME/.local/state/opencode/kv.json"    "$DOTFILES/opencode/kv.json"
  linked "$HOME/.pi/agent/settings.json"          "$DOTFILES/pi/settings.json"
  linked "$HOME/.pi/agent/mcp.json"               "$DOTFILES/pi/mcp.json"
  linked "$HOME/.pi/agent/AGENTS.md"              "$DOTFILES/agents/AGENTS.md"

  group "generated by the setup steps"
  if [ -f "$HOME/.codex/config.toml" ]; then ok "codex-config wrote ~/.codex/config.toml"; else bad "~/.codex/config.toml missing"; fi
  if bat --list-themes 2>/dev/null | grep -q '^GitHub-Dark'; then ok "bat resolves the GitHub-Dark theme from its cache"; else bad "bat cache lacks GitHub-Dark"; fi

  group "non-interactive shells resolve the tools"
  # This is the shell an agent hook or a tool running a command gets: no rc file beyond what these read.
  for c in rg nvim wt mise codex claude; do
    if bash -lc "command -v $c" >/dev/null 2>&1; then ok "login bash finds $c"; else bad "login bash cannot find $c"; fi
    # `ssh host command` runs a non-login, non-interactive bash, which reads only ~/.bashrc, up to its interactive guard.
    if env -i HOME="$HOME" bash -c ". ~/.bashrc >/dev/null 2>&1; command -v $c" >/dev/null 2>&1; then ok "a non-login bash sourcing ~/.bashrc finds $c"; else bad "~/.bashrc does not put $c on PATH before its interactive guard"; fi
    if env -i HOME="$HOME" bash -c ". ~/.profile >/dev/null 2>&1; command -v $c" >/dev/null 2>&1; then
      ok "a bare shell sourcing ~/.profile finds $c"
    else
      bad "~/.profile does not put $c on PATH"
    fi
    # zsh comes from the Nix profile (Ubuntu has none), so it is named by path: env -i leaves no PATH to find it with.
    if env -i HOME="$HOME" "$HOME/.nix-profile/bin/zsh" -c "command -v $c" >/dev/null 2>&1; then ok "zsh -c finds $c (via ~/.zshenv)"; else bad "zsh -c cannot find $c"; fi
  done
  check_agents
  # An interactive terminal execs zsh, whose ~/.zshrc sources zsh/.zshrc: the wtc alias is defined only there.
  if env -i HOME="$HOME" TERM=dumb "$HOME/.nix-profile/bin/zsh" -ic 'alias wtc >/dev/null && whence rg nvim >/dev/null' </dev/null >/dev/null 2>&1; then ok "interactive zsh runs zsh/.zshrc and finds rg and nvim"; else bad "interactive zsh does not run zsh/.zshrc or cannot find rg or nvim"; fi

  group "git identity comes from the tracked gitconfig"
  tracked=$(git config -f "$DOTFILES/git/.gitconfig" user.email)
  if [ -n "$tracked" ] && env GIT_AUTHOR_EMAIL=injected@coder bash -lc 'git var GIT_AUTHOR_IDENT' 2>/dev/null | grep -qF "<$tracked>"; then
    ok "an injected GIT_AUTHOR_EMAIL gives way to the tracked user.email"
  else
    bad "the login shell does not use the tracked user.email ($tracked)"
  fi
  # Coder's env.sh sets the identity again after ~/.zshenv; zsh/.zshrc must unset it after sourcing that file.
  if [ -n "$tracked" ] && env GIT_AUTHOR_EMAIL=injected@coder TERM=dumb "$HOME/.nix-profile/bin/zsh" -ic 'git var GIT_AUTHOR_IDENT' </dev/null 2>/dev/null | grep -qF "<$tracked>"; then
    ok "interactive zsh uses the tracked user.email"
  else
    bad "interactive zsh does not use the tracked user.email ($tracked)"
  fi
}

report() {
  printf '\n%s: %s passed, %s failed\n' "$(id -un)" "$PASS" "$FAIL"
  [ "$FAIL" -eq 0 ]
}

if [ "$(uname -s)" = Linux ]; then
  [ "$mode" = check ] || switch "$mode"
  check_linux
  report
  exit
fi

config="$(/usr/sbin/scutil --get LocalHostName)"
accounts="$(sed -n "s/.*\"$config\" = darwin \[\(.*\)\] \[.*/\1/p" "$DOTFILES/flake.nix" | tr -d '"')"
primary="$(echo $accounts | cut -d' ' -f1)"
[ -n "$primary" ] || { echo "flake.nix has no darwinConfigurations entry for this Mac ($config)" >&2; exit 1; }
me="$(id -un)"

# One account's checks, from inside that account's clean login shell (below): nothing of the caller's environment, PATH above all, reaches them.
if [ -n "${SYNC_ACCOUNT_ONLY:-}" ]; then
  check_macos
  report
  exit
fi

if [ "$mode" != check ]; then
  if [ "$me" = "$primary" ]; then
    switch "$mode"
  elif [ "$mode" = upgrade ]; then
    echo "Only the primary account, $primary, upgrades; nothing was changed." >&2; exit 1
  else
    printf '==> Only the primary account, %s, switches; checking %s only.\n' "$primary" "$me"
  fi
fi
# The primary account checks every listed account; any other account checks itself. Each runs the sync.sh of its own clone, because its links point into that clone.
targets=$me
[ "$me" != "$primary" ] || targets=$accounts
status=0
head="$(git -C "$DOTFILES" rev-parse HEAD 2>/dev/null)"
# The switch built this working tree, uncommitted changes included; other accounts check their clone's committed tree, so a dirty tree here can make their checks test a different declaration.
[ "$me" != "$primary" ] || [ -z "$(git -C "$DOTFILES" status --porcelain --untracked-files=no 2>/dev/null)" ] || echo "==> note: $DOTFILES has uncommitted changes; other accounts are checked against their own commit"
for u in $targets; do
  printf '\n==> checking %s\n' "$u"
  if [ "$u" = "$me" ]; then
    env -i HOME="$HOME" USER="$u" LOGNAME="$u" TERM="${TERM:-dumb}" SYNC_ACCOUNT_ONLY=1 /bin/zsh -l -c 'cd && ~/.config/dotfiles/sync.sh --check' || status=1
    continue
  fi
  if ! dscl . -read "/Users/$u" >/dev/null 2>&1; then
    echo "  FAIL $u is listed in flake.nix but has no macOS account"; status=1; continue
  fi
  if ! sudo -u "$u" true; then
    echo "  FAIL cannot run commands as $u through sudo"; status=1; continue
  fi
  if ! sudo -u "$u" test -x "/Users/$u/.config/dotfiles/sync.sh"; then
    echo "  FAIL /Users/$u/.config/dotfiles has no sync.sh; pull this branch there"; status=1; continue
  fi
  # The switch applied this clone's declaration; a clone on another commit would check a different one.
  theirs="$(sudo -u "$u" -H git -C "/Users/$u/.config/dotfiles" rev-parse HEAD 2>/dev/null)"
  if [ "$theirs" != "$head" ]; then
    echo "  FAIL /Users/$u/.config/dotfiles is at ${theirs:-an unknown commit}, not ${head:-the commit of this clone}; pull there and check again"; status=1; continue
  fi
  sudo -u "$u" -H env -i HOME="/Users/$u" USER="$u" LOGNAME="$u" TERM="${TERM:-dumb}" SYNC_ACCOUNT_ONLY=1 /bin/zsh -l -c 'cd && ~/.config/dotfiles/sync.sh --check' || status=1
done
exit "$status"
