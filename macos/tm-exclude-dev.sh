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

for root in $ROOTS; do
  [ -d "$root" ] || continue
  for pat in $PATTERNS; do
    # -maxdepth keeps sweeps fast; go deeper only for nested monorepos
    find "$root" -maxdepth 6 -type d -name "$pat" -prune 2>/dev/null | while read -r dir; do
      if ! tmutil isexcluded "$dir" 2>/dev/null | grep -q '\[Excluded\]'; then
        tmutil addexclusion "$dir" && echo "excluded: $dir"
      fi
    done
  done
done
