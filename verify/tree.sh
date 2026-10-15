#!/usr/bin/env bash
# Print, one per line and relative to the repository root, the files a check copies out of this working tree: the ones the git flake a real switch reads sees, which are the files in git's index, with their working-tree contents. A new file has to be staged (`git add`) before a check sees it, exactly as before a switch. Everything else stays on the host: secrets (.env, .ssh/private.conf), eval transcripts, synced skills. A copy that went through `nix build path:` would otherwise put them in the world-readable /nix/store.
set -euo pipefail
cd "$(dirname "$0")/.."
git ls-files --cached | while IFS= read -r f; do
  # A tracked file deleted in the working tree is still listed; skip it.
  if [ -e "$f" ] || [ -L "$f" ]; then printf '%s\n' "$f"; fi
done
