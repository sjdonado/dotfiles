#!/bin/sh
# Mark common dev junk dirs (node_modules, build, etc.) as excluded from
# Time Machine via xattr. Re-run after package managers regenerate them.
#
# Roots default to ~/Developer plus ~. Override with TM_EXCLUDE_ROOTS.
set -eu

ROOTS="${TM_EXCLUDE_ROOTS:-$HOME/Developer $HOME}"

PATTERNS="
node_modules
build
dist
target
.next
.nuxt
.turbo
.svelte-kit
.astro
.cache
.venv
venv
vendor
Pods
DerivedData
__pycache__
.gradle
.parcel-cache
"

# Live status only on a terminal; launchd log stays clean (no \r spam).
status() { [ -t 2 ] && printf '\r\033[K%s' "$1" >&2 || :; }
done_status() { [ -t 2 ] && printf '\r\033[K' >&2 || :; }

# Build one OR'd name predicate: \( -name a -o -name b -o ... \)
set --
for pat in $PATTERNS; do
  [ "$#" -eq 0 ] && set -- -name "$pat" || set -- "$@" -o -name "$pat"
done

for root in $ROOTS; do
  [ -d "$root" ] || continue
  status "scanning $root ..."
  # Single pass: -prune stops descent at the first match, so we never walk
  # INTO node_modules et al. looking for other patterns.
  find "$root" -maxdepth 6 -type d \( "$@" \) -prune 2>/dev/null | while read -r dir; do
    status "checking ${dir#$HOME/}"
    if ! tmutil isexcluded "$dir" 2>/dev/null | grep -q '\[Excluded\]'; then
      done_status
      tmutil addexclusion "$dir" && echo "excluded: $dir"
    fi
  done
done
done_status
