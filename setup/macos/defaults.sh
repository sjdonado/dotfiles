#!/bin/sh
# macOS system defaults. Idempotent — safe to re-run.
set -eu

echo "[Finder] show all filename extensions"
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

echo "[Finder] show hidden files by default"
defaults write com.apple.finder AppleShowAllFiles -bool true

# Apply immediately so changes take effect without logout
killall Finder 2>/dev/null || true
killall cfprefsd 2>/dev/null || true
