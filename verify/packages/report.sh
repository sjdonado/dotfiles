#!/usr/bin/env bash
# The half of verify/packages/run.sh that runs inside the container, from the flake root.
set -uo pipefail

# Built on the machine by design: this repository's own packages (nix/pkgs, the `only` wrappers), claude-code (unfree, so Hydra never builds it; its build is a download), python environments (a directory of links), and home-manager's generated files.
LOCAL='^(opencode|codex|gawk|gsed|telnet|claude-code|python3-[0-9.]+-env|home-manager|hm-session-vars\.sh|home-configuration-reference-manpage|dummy-xdg-mime-dirs[0-9])(-[0-9]|$)'
fail=0

# name, every output a profile installs, and whether it evaluates at all.
describe='ps: map (p: let o = builtins.tryEval (map (n: (p.${n} or p).outPath) (p.meta.outputsToInstall or [ "out" ])); in { name = p.name or "?"; ok = o.success; outs = if o.success then o.value else []; }) ps'

check() {
  local label=$1 attr=$2 tmp
  tmp=$(mktemp -d)
  printf '\n== %s\n' "$label"
  if ! nix eval --impure --json "$attr" --apply "$describe" > "$tmp/pkgs.json" 2> "$tmp/err"; then
    echo "  FAIL the package list does not evaluate: $(tail -3 "$tmp/err")"; fail=1; return
  fi
  local n=0 local_n=0
  while IFS=$'\t' read -r name ok outs; do
    n=$((n+1))
    if [ "$ok" != true ]; then echo "  FAIL $name does not evaluate for this platform"; fail=1; continue; fi
    if [[ "$name" =~ $LOCAL ]]; then local_n=$((local_n+1)); echo "  local $name"; continue; fi
    for out in $outs; do
      h=$(basename "$out" | cut -d- -f1)
      if ! curl -sf --compressed "https://cache.nixos.org/$h.ls" > "$tmp/$h.ls"; then
        echo "  FAIL $name: $out is not on cache.nixos.org, so a switch would build it"; fail=1; continue
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
    fail=1
  else
    echo "  ok   no two packages provide the same file"
  fi
  rm -rf "$tmp"
}

check "Linux aarch64 (home-manager)" .#homeConfigurations.linux-aarch64.config.home.packages
check "Linux x86_64 (home-manager)" .#homeConfigurations.linux-x86_64.config.home.packages
check "macOS (home-manager inside nix-darwin)" '.#darwinConfigurations."Juans-MacBook-Pro".config.home-manager.users.juan.home.packages'

printf '\n'
[ "$fail" = 0 ] && echo "==> all packages available, prebuilt and collision-free" || echo "==> package check failed"
exit $fail
