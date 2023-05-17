#!/bin/sh

echo "[Finder] show all filename extensions"
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

echo "[Finder] show hidden files by default"
defaults write com.apple.Finder AppleShowAllFiles -bool true

echo "[Finder] show the ~/Library folder"
chflags nohidden ~/Library

echo "[Finder] disable window animations"
defaults write com.apple.finder DisableAllAnimations -bool true

echo "[Finder] show Path bar in Finder"
defaults write com.apple.finder ShowPathbar -bool true

echo "[Finder] show Status bar in Finder"
defaults write com.apple.finder ShowStatusBar -bool true

echo "[Dock] auto hide and show"
defaults write com.apple.dock autohide -bool true

echo "[Dock] don’t animate opening applications"
defaults write com.apple.dock launchanim -bool false

echo "[Dock] disable genie effect (setting it to 'scale')"
defaults write com.apple.dock mineffect -string scale

echo "[Menu Bar] show remaining battery time; show percentage"
defaults write com.apple.menuextra.battery ShowPercent -string "YES"

echo "[SystemUIServer] disable opening and closing animations"
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false

echo "[Safari] enable debug menu"
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

echo "[Alacritty] font smoothing"
# https://github.com/alacritty/alacritty/commit/2a676dfad837d1784ed0911d314bc263804ef4ef
defaults write org.alacritty AppleFontSmoothing -int 0

echo "Please log out to safely restart SystemUIServer"
