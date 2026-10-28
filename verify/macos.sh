#!/usr/bin/env bash
# The fast macOS check: evaluate the darwin configuration and assert what a switch would apply, without applying it. Nothing on this Mac changes.
#
#   verify/macos.sh
#
# With Nix on this Mac it builds the system closure first (no activation); without Nix it evaluates inside a Linux container, where nothing can be built for macOS. Either way it then checks every package of the macOS and both Linux profiles against cache.nixos.org: it must exist, be prebuilt (so a switch downloads instead of compiling), and provide no file another package provides. After a switch, `sync.sh --check` asserts this Mac itself.
#
# HOST_CONFIG and USER_CONFIG select another configuration (default: this Mac's hostname, the user running the check). The same script runs inside the container to assert (VERIFY_STAGE=assert).
set -euo pipefail

HOST="${HOST_CONFIG:-$(scutil --get LocalHostName 2>/dev/null || hostname -s)}"
USER_NAME="${USER_CONFIG:-$(id -un)}"

# The assertions, run from a flake root with nix, jq and curl on PATH.
assert_config() {
  set +e
  PASS=0 FAIL=0
  ok()    { printf '  ok   %s\n' "$1"; PASS=$((PASS+1)); }
  bad()   { printf '  FAIL %s\n' "$1"; FAIL=$((FAIL+1)); }
  group() { printf '\n== %s\n' "$1"; }

  # One evaluation, everything the assertions read. A live link's target is visible in the command that creates it.
  facts=$(nix eval --json ".#darwinConfigurations.\"$HOST\".config" --apply "c: let
      hm = c.home-manager.users.$USER_NAME;
      files = hm.home.file;
      target = f: let m = builtins.match \"ln -s '?([^' ]*)'? .*\" (f.source.buildCommand or \"\"); in if m == null then null else builtins.head m;
    in {
      links = builtins.listToAttrs (map (f: { name = f.target; value = target f; }) (builtins.attrValues files));
      activation = builtins.attrNames hm.home.activation;
      agents = builtins.mapAttrs (n: a: a.config.ProgramArguments) hm.launchd.agents;
      system = builtins.concatStringsSep \"\n\" (map (s: s.text or \"\") (builtins.attrValues c.system.activationScripts));
      brew = { inherit (c.homebrew) brews casks masApps taps; inherit (c.homebrew.onActivation) cleanup upgrade autoUpdate; };
      nixHomebrew = { inherit (c.nix-homebrew) enable autoMigrate mutableTaps; taps = builtins.attrNames c.nix-homebrew.taps; };
      packages = map (p: p.name) hm.home.packages;
      users = builtins.attrNames c.home-manager.users;
      accounts = builtins.filter (u: builtins.substring 0 7 u != \"_nixbld\") (builtins.attrNames c.users.users);
      primary = c.system.primaryUser;
      shells = c.environment.etc.shells.text or \"\";
      userDefaults = builtins.toJSON hm.targets.darwin.defaults;
    }") || { echo "evaluation failed"; exit 1; }
  f() { jq -r "$1" <<<"$facts"; }

  group "live links into the repository"
  repo="/Users/$USER_NAME/.config/dotfiles"
  while IFS=$'\t' read -r name target; do
    [ "$target" = null ] && continue
    rel="${target#"$repo"/}"
    if [ "$rel" = "$target" ]; then bad "$name links outside the repository: $target"
    elif [ -e "$rel" ]; then ok "~/$name -> $rel"
    else bad "~/$name -> $rel, which does not exist in the tree"; fi
  done < <(f '.links | to_entries[] | [.key, (.value // "null")] | @tsv')
  for want in .gitconfig .ssh/config .docker/config.json .zshrc .config/browser-router/config.json .claude/settings.json .codex/AGENTS.md .config/opencode/opencode.json .pi/agent/settings.json; do
    if [ "$(f ".links[\"$want\"] // empty")" ]; then :; else bad "no live link declared for ~/$want"; fi
  done
  handy="Library/Application Support/com.pais.handy/settings_store.json"
  if [ "$(f ".links[\"$handy\"] // empty")" = "$repo/macos/handy/settings_store.json" ]; then
    ok "Handy settings link into this account's repository"
  else
    bad "Handy settings do not link into this account's repository"
  fi

  group "setup steps"
  for step in codexConfig batCache pss agentClis retireOldAgents keyboardLayouts browserRouter defaultApps appShortcuts envFile; do
    if f '.activation[]' | grep -qx "$step"; then ok "activation step $step"; else bad "activation step $step missing"; fi
  done

  group "launch agents"
  for agent in KeyRemapping:macos/caps-to-control.sh TMExcludeDev:macos/tm-exclude-dev.sh; do
    name="${agent%%:*}" script="${agent#*:}"
    if [ "$(f ".agents.$name[0]")" = "$repo/$script" ] && [ -x "$script" ]; then ok "$name runs $script"; else bad "$name does not run $script"; fi
  done

  group "system settings"
  system="$(f .system)"
  if grep -q 'UserShell /bin/zsh' <<<"$system"; then ok "activation sets zsh as the login shell"; else bad "activation does not set /bin/zsh as UserShell"; fi
  if f .shells | grep -qx /bin/zsh; then ok "/etc/shells is written and lists /bin/zsh"; else bad "nix-darwin writes no /etc/shells (environment.shells is empty)"; fi
  for want in AppleShowAllExtensions AppleShowAllFiles; do
    if f .userDefaults | grep -q "$want"; then ok "home-manager sets $want for each user"; else bad "$want is not a per-user default"; fi
  done
  # Every account the configuration declares gets the same home configuration, the primary one included.
  if [ "$(f '.accounts | sort | join(",")')" = "$(f '.users | sort | join(",")')" ]; then ok "home-manager configures every declared account ($(f '.accounts | length'))"; else bad "declared accounts ($(f '.accounts | join(" ")')) differ from home-manager users ($(f '.users | join(" ")'))"; fi
  if f '.users[]' | grep -qx "$(f .primary)"; then ok "the primary account has a home configuration"; else bad "the primary account has no home configuration"; fi

  group "Homebrew, driven by the switch"
  [ "$(f .nixHomebrew.enable)" = true ] && [ "$(f .nixHomebrew.autoMigrate)" = true ] && ok "nix-homebrew owns and adopts /opt/homebrew" || bad "nix-homebrew is not adopting /opt/homebrew"
  [ "$(f .nixHomebrew.mutableTaps)" = false ] && ok "taps are read-only flake inputs" || bad "taps are mutable"
  [ "$(f '[.brew.taps[].name] | sort | join(",")')" = "$(f '.nixHomebrew.taps | sort | join(",")')" ] && ok "homebrew.taps equals the pinned taps" || bad "homebrew.taps differs from the pinned taps"
  [ "$(f .brew.autoUpdate)" = false ] && ok "no tap fetch during the switch" || bad "autoUpdate is on"
  [ "$(f .brew.upgrade)" = true ] && ok "installed items move to the pinned versions" || bad "upgrade is off"
  echo "  info cleanup = $(f .brew.cleanup)"
  cov=openspec/changes/provision-with-nix/coverage.tsv
  if [ -f "$cov" ]; then
    before=$FAIL
    while IFS=$'\t' read -r _ item declared _; do
      case "$declared" in
        "cask "*) c="${declared#cask }"; f '.brew.casks[] | (.name? // .)' | grep -qx "$c" || f '.brew.casks[] | (.name? // .)' | grep -q "/$c$" || bad "cask $c is in coverage.tsv but not declared" ;;
        "masApps "*) [ "$(f ".brew.masApps[\"$item\"] // empty")" = "${declared#masApps }" ] || bad "App Store app $item is in coverage.tsv but not declared" ;;
        "Homebrew formula "*) f '.brew.brews[] | (.name? // .)' | grep -qx "${declared#Homebrew formula }" || bad "formula ${declared#Homebrew formula } is in coverage.tsv but not declared" ;;
      esac
    done < <(tail -n +2 "$cov")
    [ "$FAIL" = "$before" ] && ok "every cask, formula and App Store app in coverage.tsv is declared ($(f '.brew.casks | length') casks, $(f '.brew.brews | length') formulas, $(f '.brew.masApps | length') App Store apps)"
  fi

  group "packages"
  echo "  info $(f '.packages | length') packages in the home profile"
  for p in mise neovim opencode pi-coding-agent; do
    if f '.packages[]' | grep -q "^$p-[0-9]"; then ok "$p declared"; else bad "$p not declared"; fi
  done
  # Installed by the agentClis step instead, so T3 Code can update them.
  for p in codex claude-code; do
    if f '.packages[]' | grep -q "^$p-[0-9]"; then bad "$p is a Nix package"; else ok "$p is not a Nix package"; fi
  done


  if [ "${CHECK_PACKAGES:-0}" = 1 ]; then
    group "packages: available, prebuilt, no collisions"
    # Built on the machine by design: this repository's own packages (nix/pkgs, the `only` wrappers), python environments (a directory of links), and home-manager's generated files.
    LOCAL='^(opencode|gawk|gsed|telnet|python3-[0-9.]+-env|home-manager|hm-session-vars\.sh|home-configuration-reference-manpage|dummy-xdg-mime-dirs[0-9])(-[0-9]|$)'

    # name, every output a profile installs, and whether it evaluates at all.
    describe='ps: map (p: let o = builtins.tryEval (map (n: (p.${n} or p).outPath) (p.meta.outputsToInstall or [ "out" ])); in { name = p.name or "?"; ok = o.success; outs = if o.success then o.value else []; }) ps'

    check() {
      local label=$1 attr=$2 tmp
      tmp=$(mktemp -d)
      printf '\n== %s\n' "$label"
      if ! nix eval --impure --json "$attr" --apply "$describe" > "$tmp/pkgs.json" 2> "$tmp/err"; then
        echo "  FAIL the package list does not evaluate: $(tail -3 "$tmp/err")"; FAIL=$((FAIL+1)); return
      fi
      local n=0 local_n=0
      while IFS=$'\t' read -r name ok outs; do
        n=$((n+1))
        if [ "$ok" != true ]; then echo "  FAIL $name does not evaluate for this platform"; FAIL=$((FAIL+1)); continue; fi
        if [[ "$name" =~ $LOCAL ]]; then local_n=$((local_n+1)); echo "  local $name"; continue; fi
        for out in $outs; do
          h=$(basename "$out" | cut -d- -f1)
          if ! curl -sf --compressed "https://cache.nixos.org/$h.ls" > "$tmp/$h.ls"; then
            echo "  FAIL $name: $out is not on cache.nixos.org, so a switch would build it"; FAIL=$((FAIL+1)); continue
          fi
          # Every regular file and symlink below the top level, as "path<TAB>package". A profile ignores nix-support/, and a top-level symlink (lib -> ...) is merged as a directory.
          jq -r --arg pkg "$name" '
            paths(objects | select(.type? == "regular" or .type? == "symlink"))
            | map(select(. != "root" and . != "entries"))
            | select(length > 1 and .[0] != "nix-support")
            | "/" + join("/") + "\t" + $pkg
          ' "$tmp/$h.ls" >> "$tmp/files"
        done
      done < <(jq -r '.[] | [.name, (.ok|tostring), (.outs|join(" "))] | @tsv' "$tmp/pkgs.json")
      echo "  $n packages evaluate; $local_n built locally; the rest are prebuilt on cache.nixos.org"
      # A path two packages both provide fails the profile build.
      local dups
      dups=$(sort -u "$tmp/files" 2>/dev/null | cut -f1 | sort | uniq -d)
      if [ -n "$dups" ]; then
        while read -r p; do
          echo "  FAIL collision on $p: $(grep -F "$p	" "$tmp/files" | cut -f2 | sort -u | paste -sd, -)"
        done <<< "$dups"
        FAIL=$((FAIL+1))
      else
        echo "  ok   no two packages provide the same file"
      fi
      rm -rf "$tmp"
    }
    check "macOS home profile" ".#darwinConfigurations.\"$HOST\".config.home-manager.users.$USER_NAME.home.packages"
    # The Linux profiles too: verify/linux.sh builds them, but would compile a package missing from the cache without saying so.
    check "Linux aarch64 home profile" .#homeConfigurations.linux-aarch64.config.home.packages
    check "Linux x86_64 home profile" .#homeConfigurations.linux-x86_64.config.home.packages
  fi

  printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
  [ "$FAIL" -eq 0 ]
}

if [ "${VERIFY_STAGE:-}" = assert ]; then
  assert_config
  exit
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# The files the git flake sees (git's index, with working-tree contents). `path:` puts everything it is given into the world-readable /nix/store, so ignored files (secrets, eval transcripts) must not be among them.
tree() { git -C "$ROOT" ls-files --cached | while IFS= read -r f; do if [ -e "$ROOT/$f" ] || [ -L "$ROOT/$f" ]; then printf '%s\n' "$f"; fi; done; }

if command -v nix >/dev/null 2>&1; then
  # The real path: macOS puts $TMPDIR under /var, a symlink to /private/var, and nix 2.34 refuses a flake path through a symlink.
  STAGE="$(cd "$(mktemp -d)" && pwd -P)"
  trap 'rm -rf "$STAGE"' EXIT
  tree | rsync -a --files-from=- "$ROOT/" "$STAGE/"
  echo "==> building darwinConfigurations.$HOST (no activation)"
  nix build --no-link "path:$STAGE#darwinConfigurations.\"$HOST\".system"
  cd "$STAGE"
  VERIFY_STAGE=assert CHECK_PACKAGES=1 HOST_CONFIG="$HOST" USER_CONFIG="$USER_NAME" nix shell --inputs-from . nixpkgs#jq nixpkgs#curl -c bash verify/macos.sh
else
  echo "==> no Nix on this Mac: evaluating in a container (nothing is built)"
  tree | COPYFILE_DISABLE=1 tar --no-xattrs --no-fflags -C "$ROOT" -T - -cf - |
    docker run --rm -i -e HOST_CONFIG="$HOST" -e USER_CONFIG="$USER_NAME" -e USER=check -e HOME=/home/check nixos/nix:2.28.3 bash -euo pipefail -c '
      printf "experimental-features = nix-command flakes\n" >> /etc/nix/nix.conf
      mkdir -p /src && tar -C /src -xf - && cd /src
      nix eval --raw ".#darwinConfigurations.\"$HOST_CONFIG\".system.drvPath" >/dev/null
      VERIFY_STAGE=assert CHECK_PACKAGES=1 exec nix shell --inputs-from . nixpkgs#jq nixpkgs#curl -c bash verify/macos.sh
    '
fi
