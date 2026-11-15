#!/usr/bin/env bash
# Keep the public sync command stable while setup owns its implementation.
set -euo pipefail

DOTFILES=${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
export DOTFILES
exec "$DOTFILES/setup/sync.sh" "$@"
