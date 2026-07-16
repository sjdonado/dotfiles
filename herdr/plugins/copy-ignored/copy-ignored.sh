#!/bin/sh
# herdr worktree.created hook.
#
# Seeds a freshly created git worktree with the gitignored files it needs to
# skip a cold start (.env, build caches, node_modules, target/, ...). herdr
# only checks out tracked files, so without this a new worktree is missing
# everything git ignores.
#
# Delegates to worktrunk's `wt step copy-ignored`, which enumerates ignored
# entries via `git ls-files` and copies them with clonefile (APFS copy-on-write
# reflink) — near-instant and zero extra disk until modified, unlike a byte
# copy. Narrow what gets copied per-repo with a `.worktreeinclude` file.
#
# Context arrives as JSON in HERDR_PLUGIN_CONTEXT_JSON; the new checkout is its
# only `checkout_path`. `wt step copy-ignored` defaults --from to the main
# worktree and --to to the current directory, so we just cd in and run it.
set -eu

ctx="${HERDR_PLUGIN_CONTEXT_JSON:-}"
[ -n "$ctx" ] || exit 0

dest=$(printf '%s' "$ctx" | sed -n 's/.*"checkout_path":"\([^"]*\)".*/\1/p')
[ -n "$dest" ] && [ -d "$dest" ] || exit 0

# herdr's server env (spawned over ssh / non-login) may have a minimal PATH.
# The setup scripts install the wt binary into ~/.local/bin on Linux or
# Homebrew's bin directory on macOS.
PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
export PATH
command -v wt >/dev/null 2>&1 || exit 0

cd "$dest" || exit 0
exec wt step copy-ignored -y
