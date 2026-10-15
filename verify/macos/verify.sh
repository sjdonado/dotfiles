#!/usr/bin/env bash
# Assertions on the evaluated darwin configuration: what a switch would apply. Run from the flake root with nix and jq on PATH (verify/macos/run.sh does both). HOST and USER_NAME name the configuration.
set -uo pipefail

HOST="${HOST:?}" USER_NAME="${USER_NAME:?}"
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
    shells = map toString c.environment.shells;
    brew = { inherit (c.homebrew) brews casks masApps taps; inherit (c.homebrew.onActivation) cleanup upgrade autoUpdate; };
    nixHomebrew = { inherit (c.nix-homebrew) enable autoMigrate mutableTaps; taps = builtins.attrNames c.nix-homebrew.taps; };
    packages = map (p: p.name) hm.home.packages;
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
for want in .gitconfig .ssh/config .docker/config.json .config/nvim .config/fish/config.fish .config/browser-router/config.json .claude/settings.json .codex/AGENTS.md .config/opencode/opencode.json .pi/agent/settings.json; do
  if [ "$(f ".links[\"$want\"] // empty")" ]; then :; else bad "no live link declared for ~/$want"; fi
done

group "setup steps"
for step in herdrClaude herdrOpencode herdrPlugins codexConfig batCache agentBrowser nvimPlugins fishHistory pss retireOldAgents keyboardLayouts browserRouter defaultApps appShortcuts envFile; do
  if f '.activation[]' | grep -qx "$step"; then ok "activation step $step"; else bad "activation step $step missing"; fi
done

group "launch agents"
for agent in KeyRemapping:macos/caps-to-control.sh TMExcludeDev:macos/tm-exclude-dev.sh; do
  name="${agent%%:*}" script="${agent#*:}"
  if [ "$(f ".agents.$name[0]")" = "$repo/$script" ] && [ -x "$script" ]; then ok "$name runs $script"; else bad "$name does not run $script"; fi
done

group "system settings"
system="$(f .system)"
for want in AppleShowAllExtensions AppleShowAllFiles 'UserShell'; do
  if grep -q "$want" <<<"$system"; then ok "activation sets $want"; else bad "activation never mentions $want"; fi
done
if f '.shells[]' | grep -q '/bin/fish$'; then ok "fish is listed for /etc/shells"; else bad "fish is not in environment.shells"; fi

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
for p in neovim opencode codex claude-code herdr pi-coding-agent; do
  if f '.packages[]' | grep -q "^$p-[0-9]"; then ok "$p declared"; else bad "$p not declared"; fi
done

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
