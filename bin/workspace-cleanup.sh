#!/usr/bin/env bash
set -euo pipefail

# 1) List of branches to keep
KEEP_BRANCHES=(
  main
  fix/fly-github-actions-docker-buildx
  fix/htg-304-the-u-values-from-the-global-components-are-not-transferred
  fix/htg-316-build-times-replace-depot-with-docker-buildx
  refactor/type-library-jit-build
  refactor/ui-library-jit-build
  feat/htg-411-leads-database-migration
  feat/htg-429-create-lead-api-endpoint
  feat/htg-433-marketplace-check
)

# 2) Iterate porcelain output
git worktree list --porcelain | awk '
  $1=="worktree" { path=$2 }
  $1=="branch"   { sub("refs/heads/","",$2); print path "|" $2 }
' | while IFS=\| read -r WT_PATH BRANCH; do
  # 3) Check if $BRANCH is in KEEP_BRANCHES
  keep=0
  for b in "${KEEP_BRANCHES[@]}"; do
    if [[ "$BRANCH" == "$b" ]]; then
      keep=1
      break
    fi
  done

  if [[ $keep -eq 0 ]]; then
    echo "Removing unused worktree: $WT_PATH (branch: $BRANCH)"
    git worktree remove --force "$WT_PATH"
  fi
done
